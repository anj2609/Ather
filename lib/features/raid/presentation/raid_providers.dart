import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../data/in_memory_raid_repository.dart';
import '../domain/join_raid_use_case.dart';
import '../domain/raid_repository.dart';
import '../domain/raid_snapshot.dart';

final raidRepositoryProvider = Provider<RaidRepository>((ref) {
  final repository = InMemoryRaidRepository();
  ref.onDispose(repository.dispose);
  return repository;
});

final raidStreamProvider = StreamProvider<RaidSnapshot>((ref) {
  return ref.watch(raidRepositoryProvider).watchRaid();
});

final joinRaidUseCaseProvider = Provider<JoinRaidUseCase>((ref) {
  return JoinRaidUseCase(ref.watch(raidRepositoryProvider));
});

final localUserIdProvider =
    NotifierProvider<LocalUserIdNotifier, String>(LocalUserIdNotifier.new);

class LocalUserIdNotifier extends Notifier<String> {
  @override
  String build() => 'player-0001';

  void setUserId(String id) {
    state = id;
  }
}

final raidCapacityProvider = Provider<int>((ref) => AppConstants.raidCapacity);
