import 'package:aethercore/features/world_event/domain/world_event_clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('world event ticks clamp negative remaining duration to zero', () {
    final tick = WorldEventTick(
      now: DateTime(2026, 5, 17, 12, 0, 1),
      startsAt: DateTime(2026, 5, 17, 12),
    );

    expect(tick.remaining, Duration.zero);
    expect(tick.expired, isTrue);
  });

  test('world event clock emits 100ms cadence compatible ticks', () async {
    final clock = WorldEventClock(
      startsAt: DateTime.now().add(const Duration(seconds: 1)),
      interval: const Duration(milliseconds: 100),
    );

    final ticks = await clock.watch().take(2).toList();

    expect(ticks, hasLength(2));
    expect(ticks.last.remaining <= ticks.first.remaining, isTrue);
  });

  test('world event clock emits one expired tick and closes', () async {
    final clock = WorldEventClock(
      startsAt: DateTime.now().subtract(const Duration(seconds: 1)),
    );

    final ticks = await clock.watch().toList();

    expect(ticks, hasLength(1));
    expect(ticks.single.expired, isTrue);
  });
}
