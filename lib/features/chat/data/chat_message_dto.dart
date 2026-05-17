import '../domain/chat_message.dart';

final class ChatMessageDto {
  const ChatMessageDto({
    required this.id,
    required this.userId,
    required this.body,
    required this.sentAtMillis,
    required this.shard,
    required this.bucket,
  });

  final String id;
  final String userId;
  final String body;
  final int sentAtMillis;
  final int shard;
  final String bucket;

  ChatMessage toDomain() {
    return ChatMessage(
      id: id,
      userId: userId,
      body: body,
      sentAt: DateTime.fromMillisecondsSinceEpoch(sentAtMillis),
      shard: shard,
      bucket: bucket,
    );
  }
}
