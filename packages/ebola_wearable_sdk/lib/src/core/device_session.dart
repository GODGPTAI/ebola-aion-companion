import '../device_contract.dart';
import '../events/sdk_events.dart';

/// Owns the current adapter connection and makes transitions explicit.
class EbolaDeviceSession {
  final EbolaWearableAdapter adapter;
  final EbolaEventBus events;
  EbolaConnectionStatus _status = EbolaConnectionStatus.disconnected;
  String? _deviceId;
  EbolaDeviceSession(this.adapter, this.events);
  EbolaConnectionStatus get status => _status;
  String? get deviceId => _deviceId;

  Future<void> connect(EbolaDevice target) async {
    if (_status != EbolaConnectionStatus.disconnected) {
      throw StateError('Disconnect previous device first');
    }
    if (target.adapterId != adapter.adapterId) throw StateError('Adapter mismatch');
    _status = EbolaConnectionStatus.connecting;
    events.emit(EbolaSdkEvent(EbolaEventType.connecting, deviceId: target.id));
    try {
      await adapter.connect(target.id);
      _deviceId = target.id;
      _status = EbolaConnectionStatus.connected;
      events.emit(EbolaSdkEvent(EbolaEventType.connected, deviceId: target.id));
    } catch (error) {
      _status = EbolaConnectionStatus.disconnected;
      events.emit(EbolaSdkEvent(EbolaEventType.failure, deviceId: target.id,
          details: {'operation':'connect', 'error': error.runtimeType.toString()}));
      rethrow;
    }
  }
  Future<void> disconnect() async {
    try { await adapter.disconnect(); }
    finally {
      final previous = _deviceId;
      _deviceId = null;
      _status = EbolaConnectionStatus.disconnected;
      events.emit(EbolaSdkEvent(EbolaEventType.disconnected, deviceId: previous));
    }
  }
  void requireConnected(String id) {
    if (_status != EbolaConnectionStatus.connected || _deviceId != id) {
      throw StateError('Target device is not connected');
    }
  }
}
