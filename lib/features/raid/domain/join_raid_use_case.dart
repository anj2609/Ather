import '../../../core/utils/result.dart';
import 'raid_join_receipt.dart';
import 'raid_repository.dart';

final class JoinRaidUseCase {
  const JoinRaidUseCase(this._repository);

  final RaidRepository _repository;

  Future<Result<RaidJoinReceipt>> call(String userId) {
    return _repository.joinRaid(userId);
  }
}
