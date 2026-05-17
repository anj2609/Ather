import 'package:flutter/foundation.dart';

import 'raid_slot.dart';

@immutable
final class RaidSnapshot {
  const RaidSnapshot({required this.capacity, required this.slots});

  final int capacity;
  final List<RaidSlot> slots;

  int get occupied => slots.length;

  int get remaining => capacity - occupied;

  bool get isFull => occupied >= capacity;

  bool containsUser(String userId) {
    return slots.any((slot) => slot.userId == userId);
  }
}
