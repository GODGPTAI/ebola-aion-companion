import 'dart:async';
class EbolaConnectionPolicy {
  final Duration connectTimeout;
  final int maxAttempts;
  final Duration retryDelay;
  const EbolaConnectionPolicy({this.connectTimeout=const Duration(seconds:20),this.maxAttempts=2,this.retryDelay=const Duration(milliseconds:500)});
  Future<T> run<T>(Future<T> Function() operation) async {
    Object? last;
    for (var attempt=0; attempt<maxAttempts; attempt++) {
      try { return await operation().timeout(connectTimeout); }
      catch (e) { last=e; if (attempt+1<maxAttempts) await Future<void>.delayed(retryDelay); }
    }
    throw StateError('Connection attempts failed: $last');
  }
}
