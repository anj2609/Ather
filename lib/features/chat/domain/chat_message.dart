import 'package:flutter/foundation.dart';

@immutable
final class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.userId,
    required this.body,
    required this.sentAt,
    required this.shard,
    required this.bucket,
  });

  final String id;
  final String userId;
  final String body;
  final DateTime sentAt;
  final int shard;
  final String bucket;
}
