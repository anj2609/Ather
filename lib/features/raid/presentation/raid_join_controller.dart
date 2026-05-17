import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../domain/raid_join_receipt.dart';
import 'raid_providers.dart';

sealed class JoinState {
  const JoinState();
}

final class JoinIdle extends JoinState {
  const JoinIdle();
}

final class JoinSubmitting extends JoinState {
  const JoinSubmitting();
}

final class JoinSucceeded extends JoinState {
  const JoinSucceeded(this.receipt);

  final RaidJoinReceipt receipt;
}

final class JoinRejected extends JoinState {
  const JoinRejected(this.failure);

  final AppFailure failure;
}

final joinControllerProvider =
    NotifierProvider.autoDispose<JoinController, JoinState>(JoinController.new);

final class JoinController extends Notifier<JoinState> {
  @override
  JoinState build() => const JoinIdle();

  Future<void> join() async {
    if (state is JoinSubmitting) {
      return;
    }

    state = const JoinSubmitting();
    final userId = ref.read(localUserIdProvider);
    final useCase = ref.read(joinRaidUseCaseProvider);
    final result = await useCase(userId);
    state = result.fold(
      onSuccess: JoinSucceeded.new,
      onFailure: JoinRejected.new,
    );
  }
}
