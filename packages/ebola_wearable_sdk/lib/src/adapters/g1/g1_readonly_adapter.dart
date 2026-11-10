import '../../device_contract.dart';
import '../../core/sdk_errors.dart';
import 'g1_ble_port.dart';

/// Safe G1 discovery+connect+battery diagnostics. Photo/video deliberately gated
/// until a tested firmware-specific transport is implemented with OEM rights.
class EbolaG1ReadonlyAdapter implements EbolaWearableAdapter {
  final EbolaG1BlePort port;
  bool _connected=false;
  EbolaG1ReadonlyAdapter(this.port);
  @override String get adapterId => 'ebola.g1.readonly.v1';
  @override Future<List<EbolaDevice>> scan() async => (await port.scanDeviceIds())
      .map((id) => EbolaDevice(id:id, model:'EBOLA G1', adapterId:adapterId,
      capabilities:{EbolaCapability.battery})).toList(growable:false);
  @override Future<void> connect(String deviceId) async { await port.connect(deviceId); _connected=true; }
  @override Future<void> disconnect() async { _connected=false; await port.disconnect(); }
  @override Future<Set<EbolaCapability>> getCapabilities() async => {EbolaCapability.battery};
  @override Future<int?> batteryPercent() async {
    if (!_connected) throw StateError('Connect first'); return port.readBatteryPercent();
  }
  Never _unsupported() => throw const EbolaSdkError(EbolaErrorCode.unsupported,'G1 media commands not validated on physical device');
  @override Future<EbolaCapturedAsset> takePhoto() async => _unsupported();
  @override Future<void> startVideo() async => _unsupported();
  @override Future<EbolaCapturedAsset> stopVideoAndImport() async => _unsupported();
  @override Stream<List<int>> microphonePcm({required bool userInitiated}) async* {
    if (!userInitiated) throw StateError('Explicit consent required'); _unsupported();
  }
  @override Future<void> stopMicrophone() async {}
  @override Future<void> playAudio(Uint8ListOrPath audio) async => _unsupported();
  @override Future<List<EbolaCapturedAsset>> importMedia() async => _unsupported();
}
