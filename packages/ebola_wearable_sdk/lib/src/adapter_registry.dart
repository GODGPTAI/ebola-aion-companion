import 'device_contract.dart';

/// Vendor adapters are registered locally. Do not assume matching brand names mean protocol compatibility.
class EbolaAdapterRegistry {
  final Map<String, EbolaWearableAdapter> _adapters = {};
  void register(EbolaWearableAdapter adapter) {
    if (_adapters.containsKey(adapter.adapterId)) {
      throw StateError('Adapter ID already registered');
    }
    _adapters[adapter.adapterId] = adapter;
  }
  EbolaWearableAdapter? byId(String id) => _adapters[id];
  Iterable<String> get adapterIds => _adapters.keys;
}
