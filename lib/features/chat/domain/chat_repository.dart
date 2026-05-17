import '../../../core/utils/result.dart';
import 'chat_message.dart';
import 'chat_page.dart';

abstract interface class ChatRepository {
  Stream<List<ChatMessage>> watchLatestWindow({
    required int shard,
    required int limit,
  });

  Future<Result<ChatPage>> pageBefore({
    required int shard,
    required String? cursor,
    required int limit,
  });

  Future<Result<ChatMessage>> sendMessage({
    required String userId,
    required String body,
    required int shard,
  });
}
