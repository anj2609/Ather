import 'dart:async';

import '../../../core/errors/app_failure.dart';
import '../../../core/utils/result.dart';
import '../domain/chat_message.dart';
import '../domain/chat_page.dart';
import '../domain/chat_repository.dart';
import 'chat_message_dto.dart';

final class InMemoryChatRepository implements ChatRepository {
  final List<ChatMessageDto> _messages = <ChatMessageDto>[
    ChatMessageDto(
      id: 'seed-1',
      userId: 'system',
      body: 'Aether rift stabilized. Vanguard squads may queue.',
      sentAtMillis: DateTime.now()
          .subtract(const Duration(minutes: 2))
          .millisecondsSinceEpoch,
      shard: 0,
      bucket: _bucketFor(DateTime.now().subtract(const Duration(minutes: 2))),
    ),
    ChatMessageDto(
      id: 'seed-2',
      userId: 'raid-lead',
      body: 'Hold burst cooldowns until the shield phase collapses.',
      sentAtMillis: DateTime.now()
          .subtract(const Duration(seconds: 40))
          .millisecondsSinceEpoch,
      shard: 0,
      bucket: _bucketFor(DateTime.now().subtract(const Duration(seconds: 40))),
    ),
  ];
  final StreamController<List<ChatMessage>> _controller =
      StreamController<List<ChatMessage>>.broadcast();

  InMemoryChatRepository() {
    _publish();
  }

  @override
  Stream<List<ChatMessage>> watchLatestWindow({
    required int shard,
    required int limit,
  }) async* {
    yield _latest(shard: shard, limit: limit);
    yield* _controller.stream.map((messages) {
      return _latestFrom(messages: messages, shard: shard, limit: limit);
    });
  }

  @override
  Future<Result<ChatPage>> pageBefore({
    required int shard,
    required String? cursor,
    required int limit,
  }) async {
    final filtered =
        _messages.where((message) => message.shard == shard).toList()
          ..sort((a, b) => b.sentAtMillis.compareTo(a.sentAtMillis));

    final start = cursor == null
        ? 0
        : filtered.indexWhere((message) => message.id == cursor) + 1;
    if (start < 0) {
      return const Failure<ChatPage>(RepositoryFailure('Invalid cursor'));
    }

    final slice = filtered.skip(start).take(limit).toList();
    return Success<ChatPage>(
      ChatPage(
        messages: List.unmodifiable(slice.map((message) => message.toDomain())),
        nextCursor: slice.length == limit ? slice.last.id : null,
      ),
    );
  }

  @override
  Future<Result<ChatMessage>> sendMessage({
    required String userId,
    required String body,
    required int shard,
  }) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return const Failure<ChatMessage>(
        RepositoryFailure('Message cannot be empty'),
      );
    }

    final now = DateTime.now();
    final dto = ChatMessageDto(
      id: '${now.microsecondsSinceEpoch}-$userId',
      userId: userId,
      body: trimmed,
      sentAtMillis: now.millisecondsSinceEpoch,
      shard: shard,
      bucket: _bucketFor(now),
    );
    _messages.add(dto);
    _publish();
    return Success<ChatMessage>(dto.toDomain());
  }

  void _publish() {
    final ordered = _messages.toList()
      ..sort((a, b) => b.sentAtMillis.compareTo(a.sentAtMillis));
    _controller.add(
      List.unmodifiable(ordered.map((message) => message.toDomain())),
    );
  }

  List<ChatMessage> _latest({required int shard, required int limit}) {
    final ordered = _messages.toList()
      ..sort((a, b) => b.sentAtMillis.compareTo(a.sentAtMillis));
    return _latestFrom(
      messages: List.unmodifiable(ordered.map((message) => message.toDomain())),
      shard: shard,
      limit: limit,
    );
  }

  List<ChatMessage> _latestFrom({
    required List<ChatMessage> messages,
    required int shard,
    required int limit,
  }) {
    final filtered = messages.where((message) => message.shard == shard);
    return List.unmodifiable(filtered.take(limit));
  }

  Future<void> dispose() => _controller.close();

  static String _bucketFor(DateTime time) {
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    return '${time.year}$month$day$hour';
  }
}
