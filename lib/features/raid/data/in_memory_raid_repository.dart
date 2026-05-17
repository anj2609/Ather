import 'dart:async';

import 'package:collection/collection.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/services/serial_transaction_runner.dart';
import '../../../core/utils/result.dart';
import '../domain/raid_join_receipt.dart';
import '../domain/raid_repository.dart';
import '../domain/raid_snapshot.dart';
import 'raid_slot_dto.dart';

final class InMemoryRaidRepository implements RaidRepository {
  InMemoryRaidRepository({
    TransactionRunner? transactionRunner,
    int capacity = AppConstants.raidCapacity,
  }) : _transactionRunner = transactionRunner ?? SerialTransactionRunner(),
       _capacity = capacity {
    _publish();
  }

  final TransactionRunner _transactionRunner;
  final int _capacity;
  final List<RaidSlotDto> _slots = <RaidSlotDto>[];
  final StreamController<RaidSnapshot> _controller =
      StreamController<RaidSnapshot>.broadcast();

  @override
  Stream<RaidSnapshot> watchRaid() async* {
    yield _snapshot();
    yield* _controller.stream;
  }

  @override
  Future<Result<RaidJoinReceipt>> joinRaid(String userId) {
    return _transactionRunner.run(() {
      final existing = _slots
          .where((slot) => slot.userId == userId)
          .firstOrNull;
      if (existing != null) {
        return Success<RaidJoinReceipt>(
          RaidJoinReceipt(
            userId: userId,
            slotIndex: existing.index,
            joinedAt: DateTime.fromMillisecondsSinceEpoch(
              existing.joinedAtMillis,
            ),
            idempotentReplay: true,
          ),
        );
      }

      if (_slots.length >= _capacity) {
        return const Failure<RaidJoinReceipt>(RaidFullFailure());
      }

      final now = DateTime.now();
      final slot = RaidSlotDto(
        index: _slots.length,
        userId: userId,
        joinedAtMillis: now.millisecondsSinceEpoch,
      );
      _slots.add(slot);
      _publish();

      return Success<RaidJoinReceipt>(
        RaidJoinReceipt(
          userId: userId,
          slotIndex: slot.index,
          joinedAt: now,
          idempotentReplay: false,
        ),
      );
    });
  }

  @override
  Future<void> reset() {
    return _transactionRunner.run(() {
      _slots.clear();
      _publish();
    });
  }

  void _publish() {
    _controller.add(_snapshot());
  }

  RaidSnapshot _snapshot() {
    return RaidSnapshot(
      capacity: _capacity,
      slots: List.unmodifiable(_slots.map((slot) => slot.toDomain())),
    );
  }

  Future<void> dispose() => _controller.close();
}
