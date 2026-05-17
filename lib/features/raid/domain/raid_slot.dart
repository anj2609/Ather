import 'package:flutter/foundation.dart';

@immutable
final class RaidSlot {
  const RaidSlot({
    required this.index,
    required this.userId,
    required this.joinedAt,
  });

  final int index;
  final String userId;
  final DateTime joinedAt;
}
