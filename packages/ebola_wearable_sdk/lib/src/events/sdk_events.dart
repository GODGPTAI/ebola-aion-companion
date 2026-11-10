import 'dart:async';

enum EbolaEventType { scanStarted, discovered, connecting, connected, disconnected, battery, captureStarted, captureCompleted, mediaImported, voiceStarted, voiceStopped, failure, licenceRejected }

class EbolaSdkEvent {
  final EbolaEventType type;
  final String? deviceId;
  final DateTime at;
  final Map<String, Object?> details;
  EbolaSdkEvent(this.type, {this.deviceId, Map<String, Object?>? details})
      : at = DateTime.now().toUtc(), details = Map.unmodifiable(details ?? const {});
}

class EbolaEventBus {
  final StreamController<EbolaSdkEvent> _controller = StreamController<EbolaSdkEvent>.broadcast(sync: true);
  bool _disposed = false;
  Stream<EbolaSdkEvent> get stream => _controller.stream;
  void emit(EbolaSdkEvent event) { if (!_disposed) _controller.add(event); }
  Future<void> dispose() async { _disposed = true; await _controller.close(); }
}
