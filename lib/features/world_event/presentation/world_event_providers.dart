import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/world_event_clock.dart';

final worldBossStartsAtProvider =
    NotifierProvider<WorldBossStartsAtController, DateTime>(
      WorldBossStartsAtController.new,
    );

final class WorldBossStartsAtController extends Notifier<DateTime> {
  @override
  DateTime build() => _nextStartTime();

  void restart() {
    state = _nextStartTime();
  }

  DateTime _nextStartTime() {
    return DateTime.now().add(const Duration(minutes: 7, seconds: 30));
  }
}

final worldEventClockProvider = Provider<WorldEventClock>((ref) {
  return WorldEventClock(startsAt: ref.watch(worldBossStartsAtProvider));
});

final worldEventTickProvider = StreamProvider<WorldEventTick>((ref) {
  return ref.watch(worldEventClockProvider).watch();
});
