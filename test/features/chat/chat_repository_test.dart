import 'package:aethercore/core/utils/result.dart';
import 'package:aethercore/features/chat/data/in_memory_chat_repository.dart';
import 'package:aethercore/features/chat/domain/chat_message.dart';
import 'package:aethercore/features/chat/domain/chat_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('latest listener is scoped by shard and limit', () async {
    final repository = InMemoryChatRepository();
    addTearDown(repository.dispose);

    await repository.sendMessage(userId: 'u1', body: 'alpha', shard: 0);
    await repository.sendMessage(userId: 'u2', body: 'beta', shard: 1);
    await repository.sendMessage(userId: 'u3', body: 'gamma', shard: 0);

    final latest = await repository.watchLatestWindow(shard: 0, limit: 2).first;

    expect(latest, hasLength(2));
    expect(latest.every((message) => message.shard == 0), isTrue);
    expect(latest.first.body, 'gamma');
  });

  test('pagination returns bounded pages with cursor', () async {
    final repository = InMemoryChatRepository();
    addTearDown(repository.dispose);

    for (var index = 0; index < 5; index++) {
      await repository.sendMessage(
        userId: 'user-$index',
        body: 'message-$index',
        shard: 0,
      );
    }

    final first = await repository.pageBefore(shard: 0, cursor: null, limit: 3);
    final firstPage = (first as Success<ChatPage>).value;
    final second = await repository.pageBefore(
      shard: 0,
      cursor: firstPage.nextCursor,
      limit: 3,
    );
    final secondPage = (second as Success<ChatPage>).value;

    expect(firstPage.messages, hasLength(3));
    expect(firstPage.nextCursor, isNotNull);
    expect(secondPage.messages, isNotEmpty);
    expect(
      <String>{
        ...firstPage.messages.map((message) => message.id),
        ...secondPage.messages.map((message) => message.id),
      }.length,
      firstPage.messages.length + secondPage.messages.length,
    );
  });

  test('empty messages fail with typed repository error', () async {
    final repository = InMemoryChatRepository();
    addTearDown(repository.dispose);

    final result = await repository.sendMessage(
      userId: 'u1',
      body: '   ',
      shard: 0,
    );

    expect(result, isA<Failure<ChatMessage>>());
  });
}
