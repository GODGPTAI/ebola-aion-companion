import 'adapter_registry.dart';
import 'device_contract.dart';
import 'core/device_session.dart';
import 'events/sdk_events.dart';
import 'licensing.dart';

/// Optional high-level coordinator, with explicit lifecycle and mandatory
/// user consent before media actions. Existing v0.2 EbolaWearableSdk unchanged.
class EbolaSdkFacade {
  final EbolaAdapterRegistry registry;
  final EbolaLicenseGate licences;
  final EbolaEventBus events;
  EbolaSdkFacade({required this.registry,required this.licences,required this.events});
  final Map<String, EbolaDeviceSession> _sessions = {};
  EbolaDeviceSession sessionFor(EbolaWearableAdapter adapter) =>
      _sessions.putIfAbsent(adapter.adapterId,()=>EbolaDeviceSession(adapter,events));
  Future<List<EbolaDevice>> discover(String adapterId) async {
    final adapter=registry.byId(adapterId);
    if (adapter==null) throw StateError('Unregistered adapter');
    events.emit(EbolaSdkEvent(EbolaEventType.scanStarted));
    final devices=await adapter.scan();
    for(final d in devices) {events.emit(EbolaSdkEvent(EbolaEventType.discovered,deviceId:d.id));}
    return devices;
  }
  Future<EbolaCapturedAsset> photo({required EbolaDevice device,
    required EbolaDeviceBinding binding,required bool userApproved}) async {
    if (!userApproved) throw StateError('Explicit camera consent required');
    if (device.id!=binding.deviceId) throw StateError('Device/licence mismatch');
    if (!_modelMatchesBinding(device.model, binding.modelCode)) {
      throw StateError('Device model/licence mismatch');
    }
    final adapter=registry.byId(device.adapterId);
    if (adapter==null) throw StateError('Unregistered adapter');
    sessionFor(adapter).requireConnected(device.id);
    try { await licences.requireActive(binding); }
    catch (_) { events.emit(EbolaSdkEvent(EbolaEventType.licenceRejected,deviceId:device.id));rethrow; }
    if (!(await adapter.getCapabilities()).contains(EbolaCapability.photo)) {
      throw EbolaUnsupportedFeature('Photo unsupported');
    }
    events.emit(EbolaSdkEvent(EbolaEventType.captureStarted,deviceId:device.id));
    try {
      final result = await adapter.takePhoto();
      if (result.deviceId != device.id) {
        throw StateError('Capture result came from a different device');
      }
      events.emit(EbolaSdkEvent(EbolaEventType.captureCompleted, deviceId: device.id));
      return result;
    } catch (error) {
      events.emit(EbolaSdkEvent(EbolaEventType.failure, deviceId: device.id,
          details: {'operation':'photo', 'error':error.runtimeType.toString()}));
      rethrow;
    }
  }
  bool _modelMatchesBinding(String model, String code) {
    final text = model.toUpperCase();
    final expected = code.trim().toUpperCase();
    if (!const {'G1','G2','G3','G4'}.contains(expected)) return false;
    return RegExp(r'(^|[^A-Z0-9])' + expected + r'([^A-Z0-9]|$)').hasMatch(text);
  }

  Future<void> dispose() async {
    for(final session in _sessions.values) {await session.disconnect();}
    await events.dispose();
  }
}
