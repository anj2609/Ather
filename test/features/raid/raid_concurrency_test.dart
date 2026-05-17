import 'package:aethercore/core/errors/app_failure.dart';
import 'package:aethercore/core/utils/result.dart';
import 'package:aethercore/features/raid/data/in_memory_raid_repository.dart';
import 'package:aethercore/features/raid/domain/raid_join_receipt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    '50 simultaneous join requests deterministically allocate 15 slots',
    () async {
      final repository = InMemoryRaidRepository();
      addTearDown(repository.dispose);

      final gate = Future<void>.delayed(Duration.zero);
      final results = await Future.wait(
        List.generate(50, (index) async {
          await gate;
          return repository.joinRaid('player-$index');
        }),
      );

      final successes = results.whereType<Success<RaidJoinReceipt>>().toList();
      final failures = results.whereType<Failure<RaidJoinReceipt>>().toList();
      final fullFailures = failures.where(
        (failure) => failure.failure is RaidFullFailure,
      );
      final slots = successes.map((success) => success.value.slotIndex).toList()
        ..sort();

      expect(successes, hasLength(15));
      expect(failures, hasLength(35));
      expect(fullFailures, hasLength(35));
      expect(slots, List.generate(15, (index) => index));

      final snapshot = await repository.watchRaid().first;
      expect(snapshot.occupied, 15);
      expect(snapshot.isFull, isTrue);
    },
  );

  test('join is idempotent for the same user id', () async {
    final repository = InMemoryRaidRepository();
    addTearDown(repository.dispose);

    final first = await repository.joinRaid('same-user');
    final second = await repository.joinRaid('same-user');

    final firstReceipt = (first as Success<RaidJoinReceipt>).value;
    final secondReceipt = (second as Success<RaidJoinReceipt>).value;

    expect(firstReceipt.slotIndex, 0);
    expect(firstReceipt.idempotentReplay, isFalse);
    expect(secondReceipt.slotIndex, 0);
    expect(secondReceipt.idempotentReplay, isTrue);

    final snapshot = await repository.watchRaid().first;
    expect(snapshot.occupied, 1);
  });

  test('reset clears allocated slots and publishes a new snapshot', () async {
    final repository = InMemoryRaidRepository();
    addTearDown(repository.dispose);

    await repository.joinRaid('player-1');
    await repository.reset();

    final snapshot = await repository.watchRaid().first;
    expect(snapshot.occupied, 0);
    expect(snapshot.remaining, 15);
  });
}
