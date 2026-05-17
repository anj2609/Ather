import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../raid/presentation/raid_providers.dart';
import '../data/in_memory_chat_repository.dart';
import '../domain/chat_message.dart';
import '../domain/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final repository = InMemoryChatRepository();
  ref.onDispose(repository.dispose);
  return repository;
});

final latestChatProvider = StreamProvider<List<ChatMessage>>((ref) {
  return ref
      .watch(chatRepositoryProvider)
      .watchLatestWindow(
        shard: AppConstants.visibleChatShard,
        limit: AppConstants.chatPageSize,
      );
});

final sendChatControllerProvider =
    AsyncNotifierProvider.autoDispose<SendChatController, void>(
      SendChatController.new,
    );

final class SendChatController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> send(String body) async {
    state = const AsyncLoading<void>();
    final result = await ref
        .read(chatRepositoryProvider)
        .sendMessage(
          userId: ref.read(localUserIdProvider),
          body: body,
          shard: AppConstants.visibleChatShard,
        );
    state = result.fold(
      onSuccess: (_) => const AsyncData<void>(null),
      onFailure: (failure) => AsyncError<void>(failure, StackTrace.current),
    );
  }
}
