import { SendResponse, getMessaging } from "firebase-admin/messaging";
import { getDatabase } from "firebase-admin/database";
import { MessageNotification, MessageRequest, PostCreateMessage, SendEachMessage } from "./messaging.interface";
import { chunk } from "../library";
import { Config } from "../config";

/**
 * MessagingService
 *
 *
 */
export class MessagingService {
  /**
         * Send messages
         *
         * @param {MessageRequest} params - The parameters for sending messages.
         * params.tokens - The list of tokens to send the message to.
         * params.title - The title of the message.
         * params.body - The body of the message.
         * params.image - The image of the message.
         * params.data - The extra data of the message.
         *
         *
         * It returns the error results of push notification in a map like
         * below. And it only returns the tokens that has error results.
         * The tokens that succeed (without error) will not be returned.
         *
         * ```
         * {
         *   'fVWDxKs1kEzx...Lq2Vs': '',
         *   'wrong-token': 'messaging/invalid-argument',
         * }
         * ```
         *
         * If there is no error with the token, the value will be empty
         * string. Otherwise, there will be a error message.
         */
  static async sendNotificationToTokens(params: MessageRequest): Promise<{ [token: string]: string; }> {
    const promises = [];

    if (typeof params.tokens != "object") {
      throw new Error("tokens must be an array of string");
    }
    if (params.tokens.length == 0) {
      throw new Error("tokens must not be empty");
    }
    if (!params.title) {
      throw new Error("title must not be empty");
    }
    if (!params.body) {
      throw new Error("body must not be empty");
    }


    // remove empty tokens
    const tokens = params.tokens.filter((token) => !!token);


    // image is optional
    const notification: MessageNotification = { title: params.title, body: params.body };
    if (params.image) {
      notification["image"] = params.image;
    }

    // send the notification message to the list of tokens
    for (const token of tokens) {
      const message = {
        notification: notification,
        data: params.data,
        token: token,
      };
      promises.push(getMessaging().send(message));
    }

    const res = await Promise.allSettled(promises);


    const responses: { [token: string]: string; } = {};

    for (let i = 0; i < res.length; i++) {
      const status: string = res[i].status;
      if (status == "fulfilled") {
        continue;
      }

      const reason = (res[i] as PromiseRejectedResult).reason;
      responses[tokens[i]] = reason["errorInfo"]["code"];
    }
    return responses;
  }

  /**
   * 사용자의 uid 들을 입력받아, 그 사용자들의 토큰으로 메시지 전송
   *
   * Send message to users
   *
   * 1. This gets the user tokens from '/user-fcm-tokens/{uid}'.
   * 2. Then it chunks the tokens into 500 tokens per chunk.
   * 3. Then delete the tokens that are not valid.
   *
   * @param {Array<string>} uids - The list of user uids to send the message to.
   * @param {number} chunkSize - The size of chunk. Default 500. 한번에 보낼 메시지 수. 최대 500개.
   * 그런데 500개씩 하니까 좀 느리다. 256씩 두번 보내는 것이 500개 한번 보내는 것보다 더 빠르다.
   * 256 묶음으로 두 번 보내면 총 (두 번 포함) 22초.
   * 500 묵음으로 한 번 보내면 총 90초.
   * 128 묶음으로 4번 보내면 총 18 초
   *
   * 예제
   * ```
   * await MessagingService.sendNotificationToUids(['uid-a', 'uid-b'], 128, "title", "body");
   * ```
   *
   * 더 많은 예제는 firebase/functions/tests/message/sendNotificationToUids.spec.ts 참고
   */
  static async sendNotificationToUids(
    uids: Array<string>,
    chunkSize = 500,
    title: string,
    body: string,
    image?: string,
    data: { [key: string]: string } = {},
  ): Promise<void> {
    // 토큰 가져오기. 기본 500 개 단위로 chunk.
    const tokenChunks = await this.getTokensOfUsers(uids, chunkSize);

    Config.log("----> sendNotificationToUids() -> tokenChunks:", tokenChunks);

    // 토큰 메시지 작성. 이미지는 옵션.
    const notification: MessageNotification = { title, body };
    if (image) {
      notification["image"] = image;
    }

    const messaging = getMessaging();

    // chunk 단위로 메시지 작성해서 전송
    for (const tokenChunk of tokenChunks) {
      const messages: Array<SendEachMessage> = [];
      for (const token of tokenChunk) {
        messages.push({ notification, data, token });
      }
      Config.log("-----> sendNotificationToUids -> sendEach() messages[0]:", messages[0]);
      const res = await messaging.sendEach(messages, Config.messagingDryRun);
      Config.log("-----> sendNotificationToUids -> sendEach() result:", "successCount", res.successCount, "failureCount", res.failureCount,);


      // chunk 단위로 전송 - 결과 확인 및 에러 토큰 삭제
      for (let i = 0; i < messages.length; i++) {
        const response = res.responses[i] as SendResponse;
        if (response.success == false) {
          // 에러 토큰 표시
          messages[i].success = false;
          // console.log("error code:", response.error?.code);
          // console.log("error message:", response.error?.message);
        }
      }

      // 에러 토큰 삭제
      const tokensToRemove = messages.filter((message) => message.success == false).map((message) => message.token);
      // console.log("tokensToRemove; ", tokensToRemove);
      const promisesToRemove = [];
      for (let i = 0; i < tokensToRemove.length; i++) {
        promisesToRemove.push(getDatabase().ref(`${Config.userFcmTokensPath}/${tokensToRemove[i]}`).remove());
      }
      await Promise.allSettled(promisesToRemove);
    }
  }

  /**
   * Returns the list of tokens under '/user-fcm-tokens/{uid}'.
   *
   * @param uids uids of users
   * @param chunkSize chunk size - default 500. sendAll() 로 한번에 보낼 수 있는 최대 메세지 수는 500 개 이다.
   * chunk 가 500 이고, 총 토큰의 수가 501 이면, 첫번째 배열에 500개의 토큰 두번째 배열에 1개의 토큰이 들어간다.
   *
   * @returns Array<Array<string>> - Array of tokens. Each array contains 500 tokens.
   * 리턴 값은 2차원 배열이다. 각 배열은 최대 [chunkSize] 개의 토큰을 담고 있다.
   */
  static async getTokensOfUsers(uids: Array<string>, chunkSize = 500): Promise<Array<Array<string>>> {
    const promises = [];

    if (uids.length == 0) return [];

    const db = getDatabase();

    // uid 사용자 별 모든 토큰을 가져온다.
    for (const uid of uids) {
      promises.push(db.ref(Config.userFcmTokensPath).orderByChild("uid").equalTo(uid).get());
    }
    const settled = await Promise.allSettled(promises);


    // 토큰을 배열에 담는다.

    const tokens: Array<string> = [];
    for (const res of settled) {
      if (res.status == "fulfilled") {
        res.value.forEach((token) => {
          // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
          tokens.push(token.key!);
        });
      }
    }


    // 토큰을 chunk 단위로 나누어 리턴
    return chunk(tokens, chunkSize);
  }

  /**
   * 해당 게시판(카테고리)를 subscribe 한 사용자들에게 메시지를 보낸다.
   *
   * @param msg 글 정보
   */
  static async sendNotificationToForumCategorySubscribers(msg: PostCreateMessage) {
    // 해당 게시판(카테고리)를 subscribe 한 사용자들의 uid 를 가져온다.

    const db = getDatabase();
    const snapshot = await db.ref(`${Config.postsSubscriptionPath}/${msg.category}`).get();
    const uids: Array<string> = [];
    snapshot.forEach((child) => {
      // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
      uids.push(child.key!);
    });

    Config.log("-----> sendNotificationToForumCategorySubscribers uids:", uids);


    await this.sendNotificationToUids(uids, 256, msg.title, msg.body, msg.image, { id: msg.id, category: msg.category });
  }
}
