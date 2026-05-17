import '../../../core/utils/result.dart';
import 'raid_join_receipt.dart';
import 'raid_snapshot.dart';

abstract interface class RaidRepository {
  Stream<RaidSnapshot> watchRaid();

  Future<Result<RaidJoinReceipt>> joinRaid(String userId);

  Future<void> reset();
}
