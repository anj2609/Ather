import 'dart:async';

final class WorldEventTick {
  const WorldEventTick({required this.now, required this.startsAt});

  final DateTime now;
  final DateTime startsAt;

  Duration get remaining {
    final value = startsAt.difference(now);
    return value.isNegative ? Duration.zero : value;
  }

  bool get expired => remaining == Duration.zero;
}

final class WorldEventClock {
  WorldEventClock({
    required this.startsAt,
    this.interval = const Duration(milliseconds: 100),
  });

  final DateTime startsAt;
  final Duration interval;

  Stream<WorldEventTick> watch() async* {
    while (true) {
      final tick = WorldEventTick(now: DateTime.now(), startsAt: startsAt);
      yield tick;
      if (tick.expired) {
        return;
      }
      await Future<void>.delayed(interval);
    }
  }
}
