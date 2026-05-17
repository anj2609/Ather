sealed class AppFailure {
  const AppFailure(this.message);

  final String message;
}

final class RaidFullFailure extends AppFailure {
  const RaidFullFailure() : super('Raid is full');
}

final class AlreadyJoinedFailure extends AppFailure {
  const AlreadyJoinedFailure() : super('Already joined');
}

final class RepositoryFailure extends AppFailure {
  const RepositoryFailure(super.message);
}
