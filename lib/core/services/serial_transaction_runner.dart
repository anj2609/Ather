import 'dart:async';

abstract interface class TransactionRunner {
  Future<T> run<T>(FutureOr<T> Function() transaction);
}

final class SerialTransactionRunner implements TransactionRunner {
  Future<void> _tail = Future<void>.value();

  @override
  Future<T> run<T>(FutureOr<T> Function() transaction) {
    final completer = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        completer.complete(await transaction());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }
}
