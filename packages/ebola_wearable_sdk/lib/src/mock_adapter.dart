import 'dart:async';
import 'device_contract.dart';

/// Safe simulated hardware for UI/automated tests. Does not connect to a real device.
class EbolaMockAdapter implements EbolaWearableAdapter {
  bool _connected = false;
  @override String get adapterId => 'ebola.mock.v1';
  final _device = const EbolaDevice(id: 'DEMO-G2-0001', model: 'EBOLA G2 DEMO',
      adapterId: 'ebola.mock.v1', capabilities: {EbolaCapability.battery});
  @override Future<List<EbolaDevice>> scan() async => [_device];
  @override Future<void> connect(String deviceId) async {
    if (deviceId != _device.id) throw StateError('Unknown demo device');
    _connected = true;
  }
  @override Future<void> disconnect() async { _connected = false; }
  void _requireConnection() { if (!_connected) throw StateError('Demo device not connected'); }
  @override Future<Set<EbolaCapability>> getCapabilities() async => _device.capabilities;
  @override Future<int?> batteryPercent() async { _requireConnection(); return 75; }
  @override Future<EbolaCapturedAsset> takePhoto() async {
    _requireConnection();
    throw EbolaUnsupportedFeature('Mock only: no real photograph. Use app fixture data in UI tests.');
  }
  @override Future<void> startVideo() async { _requireConnection();
    throw EbolaUnsupportedFeature('No video device connected'); }
  @override Future<EbolaCapturedAsset> stopVideoAndImport() async {
    throw EbolaUnsupportedFeature('No video device connected');
  }
  @override Stream<List<int>> microphonePcm({required bool userInitiated}) async* {
    _requireConnection();
    if (!userInitiated) throw StateError('Explicit recording initiation required');
    throw EbolaUnsupportedFeature('No actual microphone in mock');
  }
  @override Future<void> stopMicrophone() async {}
  @override Future<void> playAudio(Uint8ListOrPath audio) async {
    throw EbolaUnsupportedFeature('No actual speaker in mock');
  }
  @override Future<List<EbolaCapturedAsset>> importMedia() async {
    _requireConnection(); return [];
  }
}
