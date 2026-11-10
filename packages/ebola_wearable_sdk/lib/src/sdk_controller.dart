import 'device_contract.dart';
import 'adapter_registry.dart';
import 'licensing.dart';

/// One high-level entry point used by the EBOLA mobile app.
/// A licence check occurs before each premium capture action.
class EbolaWearableSdk {
  final EbolaAdapterRegistry registry;
  final EbolaLicenseGate licenceGate;
  EbolaWearableSdk({required this.registry,required this.licenceGate});

  void _checkBinding(EbolaDeviceBinding binding) {
    if (binding.deviceId.trim().isEmpty ||
        !const {'G1','G2','G3','G4'}.contains(binding.modelCode.toUpperCase())) {
      throw ArgumentError('A device ID and supported model are required');
    }
  }

  Future<EbolaCapturedAsset> capturePhoto({required String adapterId,
      required EbolaDeviceBinding binding}) async {
    _checkBinding(binding);
    await licenceGate.requireActive(binding);
    final adapter = registry.byId(adapterId);
    if (adapter == null) throw StateError('No adapter registered: $adapterId');
    final features = await adapter.getCapabilities();
    if (!features.contains(EbolaCapability.photo)) {
      throw EbolaUnsupportedFeature('Photo capture unsupported on this device');
    }
    return adapter.takePhoto();
  }

  Future<void> startVideo({required String adapterId,
      required EbolaDeviceBinding binding}) async {
    _checkBinding(binding);
    await licenceGate.requireActive(binding);
    final adapter = registry.byId(adapterId);
    if (adapter == null) throw StateError('No adapter registered: $adapterId');
    final features = await adapter.getCapabilities();
    if (!features.contains(EbolaCapability.video)) {
      throw EbolaUnsupportedFeature('Video unsupported on this device');
    }
    await adapter.startVideo();
  }
}
