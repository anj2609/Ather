import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/world_event_clock.dart';

final worldBossStartsAtProvider = Provider<DateTime>((ref) {
  return DateTime.now().add(const Duration(minutes: 7, seconds: 30));
});

final worldEventClockProvider = Provider<WorldEventClock>((ref) {
  return WorldEventClock(startsAt: ref.watch(worldBossStartsAtProvider));
});

final worldEventTickProvider = StreamProvider<WorldEventTick>((ref) {
  return ref.watch(worldEventClockProvider).watch();
});
