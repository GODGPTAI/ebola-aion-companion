import '../../device_contract.dart';
import '../../core/sdk_errors.dart';
import 'g234_plugin_port.dart';
class EbolaG234ReadonlyAdapter implements EbolaWearableAdapter {
  final EbolaG234PluginPort port;
  final String model;
  bool _connected=false;
  EbolaG234ReadonlyAdapter(this.port, {required this.model}) {
    if (!const ['G2','G3','G4'].contains(model)) throw ArgumentError.value(model,'model');
  }
  @override String get adapterId => 'ebola.g234.readonly.v1.$model';
  @override Future<List<EbolaDevice>> scan() async => (await port.discover()).map((id) =>
    EbolaDevice(id:id, model:'EBOLA $model', adapterId:adapterId, capabilities:{EbolaCapability.battery})).toList(growable:false);
  @override Future<void> connect(String deviceId) async {await port.connect(deviceId); _connected=true;}
  @override Future<void> disconnect() async {_connected=false; await port.disconnect();}
  @override Future<Set<EbolaCapability>> getCapabilities() async => {EbolaCapability.battery};
  @override Future<int?> batteryPercent() async {if (!_connected) throw StateError('Connect first');return port.battery();}
  Never _unsupported() => throw const EbolaSdkError(EbolaErrorCode.unsupported,'Media control requires verified physical device + firmware');
  @override Future<EbolaCapturedAsset> takePhoto() async => _unsupported();
  @override Future<void> startVideo() async => _unsupported();
  @override Future<EbolaCapturedAsset> stopVideoAndImport() async => _unsupported();
  @override Stream<List<int>> microphonePcm({required bool userInitiated}) async* {if (!userInitiated) throw StateError('Consent required'); _unsupported();}
  @override Future<void> stopMicrophone() async {}
  @override Future<void> playAudio(Uint8ListOrPath audio) async => _unsupported();
  @override Future<List<EbolaCapturedAsset>> importMedia() async => _unsupported();
}
