import 'dart:async';

final class WorldEventTick {
  const WorldEventTick({required this.now, required this.startsAt});

  final DateTime now;
  final DateTime startsAt;

  Duration get remaining {
    final value = startsAt.difference(now);
    return value.isNegative ? Duration.zero : value;
  }
}

final class WorldEventClock {
  WorldEventClock({
    required this.startsAt,
    this.interval = const Duration(milliseconds: 100),
  });

  final DateTime startsAt;
  final Duration interval;

  Stream<WorldEventTick> watch() async* {
    yield WorldEventTick(now: DateTime.now(), startsAt: startsAt);
    yield* Stream.periodic(
      interval,
      (_) => WorldEventTick(now: DateTime.now(), startsAt: startsAt),
    );
  }
}
