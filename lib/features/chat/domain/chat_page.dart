import 'package:flutter/foundation.dart';

import 'chat_message.dart';

@immutable
final class ChatPage {
  const ChatPage({required this.messages, required this.nextCursor});

  final List<ChatMessage> messages;
  final String? nextCursor;
}
