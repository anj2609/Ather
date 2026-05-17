import '../domain/raid_slot.dart';

final class RaidSlotDto {
  const RaidSlotDto({
    required this.index,
    required this.userId,
    required this.joinedAtMillis,
  });

  final int index;
  final String userId;
  final int joinedAtMillis;

  RaidSlot toDomain() {
    return RaidSlot(
      index: index,
      userId: userId,
      joinedAt: DateTime.fromMillisecondsSinceEpoch(joinedAtMillis),
    );
  }
}
