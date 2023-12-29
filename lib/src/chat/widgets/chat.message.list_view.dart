import 'package:firebase_ui_database/firebase_ui_database.dart';
import 'package:fireship/fireship.dart';
import 'package:flutter/material.dart';

/// 메시지 목록
///
/// 채팅방 하나에 대한 메시지 목록을 보여준다.
///
class ChatMessageListView extends StatefulWidget {
  const ChatMessageListView({
    super.key,
    required this.room,
    this.builder,
    this.primary,
    this.emptyBuilder,
  });

  final ChatRoomModel room;

  final Widget Function(ChatMessageModel)? builder;
  final bool? primary;
  final Widget Function(BuildContext)? emptyBuilder;

  @override
  State<ChatMessageListView> createState() => _RChatMessageListState();
}

class _RChatMessageListState extends State<ChatMessageListView> {
  Widget? listView;

  String get roomId => widget.room.id;

  @override
  void initState() {
    super.initState();
    ChatService.instance.setCurrentRoom(widget.room);
    ChatService.instance.resetMyRoomNewMessage();
  }

  @override
  Widget build(BuildContext context) {
    return FirebaseDatabaseQueryBuilder(
      // 페이지 사이즈(메시지를 가져오는 개수)를 100으로 해서, 자주 가져오지 않도록 한다. 그래서 flickering 을 줄인다.
      pageSize: 100,
      query:
          ChatService.instance.messageRef(roomId: roomId).orderByChild('order'),
      builder: (context, snapshot, _) {
        if (snapshot.isFetching) {
          // FirebaseDatabaseQueryBuilder 는 snapshot.isFetching 을 맨 처음 로딩할 때 딱 한번만 true 로 지정한다.
          // 단, 처음 로딩 할 때, FirestoreDatabaseQueryBuilder 가 여러번 번 호출 되어, snapshot.isFetching 로 여러번 true 로 지정된다.
          dog('snapshot.isFetching: ${snapshot.isFetching}');

          // 맨 처음 로딩을 할 때, loader 표시
          if (listView == null) {
            dog('listView is null');
            return const Center(child: CircularProgressIndicator());
          } else {
            dog('첫번째 로딩이 이미 완료되어, 기존에 그린 위젯을 그대로 사용.');
            // 만약, 이전에 (첫번째 100개 메시지를 보여주는 ListView) 위젯을 화면에 표시 했으면, 그 위젯을 다시 표시한다.
            // 즉, flickering 을 줄인다.
            return listView!;
          }
        }

        if (snapshot.hasError) {
          dog(snapshot.error.toString());
          return Text('Something went wrong! ${snapshot.error}');
        }

        // 새로은 채팅이 들어오면(전달되어져 오면), 채팅방의 새 메시지 갯수를 0 으로 초기화 시킨다.
        if (ChatService.instance.isLoadingNewMessage(roomId, snapshot)) {
          final newMessage = ChatMessageModel.fromSnapshot(snapshot.docs.first);
          // newMessage 리셋
          ChatService.instance.resetMyRoomNewMessage(
            order: newMessage.createdAt != null ? -newMessage.createdAt! : null,
          );
        }

        // 메시지가 없는 경우,
        if (snapshot.docs.isEmpty) {
          listView = widget.emptyBuilder?.call(context) ??
              const Center(child: Text('There is no message, yet.'));
        } else {
          /// Reset the newMessage
          /// This is a good place to reset it since it is called when the user
          /// enters the room and every time it gets new message.
          listView = ListView.builder(
            padding: const EdgeInsets.all(0),
            reverse: true,
            primary: widget.primary,
            itemCount: snapshot.docs.length,
            itemBuilder: (context, index) {
              if (snapshot.hasMore && index + 1 == snapshot.docs.length) {
                snapshot.fetchMore();
              }
              final message =
                  ChatMessageModel.fromSnapshot(snapshot.docs[index]);

              /// Reset the [order] field of the message to list in time based order.
              ChatService.instance
                  .resetRoomMessageOrder(roomId: roomId, order: message.order);

              return ChatBubble(
                message: message,
              );
            },
          );
        }
        return listView!;
      },
    );
  }
}
