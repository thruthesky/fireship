import { onValueWritten } from "firebase-functions/v2/database";
import { Config } from "../config";
import { ServerValue, getDatabase } from "firebase-admin/database";
import { getFirestore } from "firebase-admin/firestore";
import { MessagingService } from "../messaging/messaging.service";
import { isCreate } from "../library";


import { onRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v1";
import { UserService } from "./user.service";


/**
 * 전화번호 가입을 한다.
 *
 * 로그인을 하지 않는다. 즉, 이미 전화번호가 가입되어져 있으면 에러를 낸다.
 *
 * @param request request
 * @param response response
 *
 * @returns response
 *
 * @see READMD.md
 */
export const phoneNumberRegister = onRequest(async (request, response) => {
    logger.info("phoneNumberRegister: request.body", request.body);
    const res = await UserService.createAccountWithPhoneNumber({ ...request.body, ...request.query });
    response.send(res);
});


/**
 * User likes
 */
export const userLike = onValueWritten(
    `${Config.userWhoILike}/{myUid}/{targetUid}`,
    async (event): Promise<void> => {
        const db = getDatabase();
        const myUid = event.params.myUid;
        const targetUid = event.params.targetUid;

        // created or updated
        if (event.data.after.exists()) {
            await db.ref(`${Config.userLikes}/${targetUid}`).update({ [myUid]: true });
            await db.ref(`users/${targetUid}`).update({ noOfLikes: ServerValue.increment(1) });
        } else {
            // deleted
            await db.ref(`${Config.userLikes}/${targetUid}/${myUid}`).remove();
            await db.ref(`users/${targetUid}`).update({ noOfLikes: ServerValue.increment(-1) });
        }

        // Send message to the target user
        if (isCreate(event)) {
            await MessagingService.sendMessageWhenUserLikeMe({
                uid: targetUid,
                otherUid: myUid,
            });
        }
    },
);

/**
 * User CRUD
 * - Mirror the user data to Firestore
 */
export const userMirror = onValueWritten(
    `${Config.users}/{uid}`,
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    async (event): Promise<any> => {
        const firestore = getFirestore();
        const userUid = event.params.uid;

        if (event.data.before.exists()) {
            // updated
            const userData = event.data.after.val();
            // noOfLikes 는 자주 업데이트 되므로, firestore /users 를 목록 할 때, FirestoreListView 등에서 flickering 이 발생한다.
            // 그래서, noOfLikes 필드는 삭제한다.
            delete userData.noOfLikes;
            return await firestore.collection(Config.users).doc(userUid).update({ ...userData });
        }
        if (!event.data.after.exists()) {
            // deleted
            return await firestore.collection(Config.users).doc(userUid).delete();
        }
        // created
        const data = event.data.after.val();
        return await firestore.collection(Config.users).doc(userUid).set({ ...data });
    }
);


