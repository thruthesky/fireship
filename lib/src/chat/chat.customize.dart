import 'package:fireship/fireship.dart';
import 'package:flutter/material.dart';

class ChatCustomize {
  final Widget Function(ChatModel chat)? chatRoomMenu;

  final Widget Function(ChatRoomModel chat)? chatRoomInviteButton;

  const ChatCustomize({
    this.chatRoomMenu,
    this.chatRoomInviteButton,
  });
}
