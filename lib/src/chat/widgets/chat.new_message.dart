import 'package:fireship/fireship.dart';
import 'package:flutter/material.dart';

class ChatNewMessage extends StatelessWidget {
  const ChatNewMessage({super.key, required this.room});

  final ChatRoomModel room;

  @override
  Widget build(BuildContext context) {
    if ((room.newMessage ?? 0) > 0) {
      return Container(
        width: (room.newMessage ?? 0) > 9 ? 20 : 16,
        height: 16,
        decoration: BoxDecoration(
          color: Colors.orange.shade900,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '${room.newMessage ?? 0}',
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
