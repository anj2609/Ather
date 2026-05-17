import 'package:flutter/foundation.dart';

@immutable
final class RaidJoinReceipt {
  const RaidJoinReceipt({
    required this.userId,
    required this.slotIndex,
    required this.joinedAt,
    required this.idempotentReplay,
  });

  final String userId;
  final int slotIndex;
  final DateTime joinedAt;
  final bool idempotentReplay;
}
