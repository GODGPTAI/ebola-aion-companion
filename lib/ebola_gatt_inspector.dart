import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Read-only GATT diagnostic. Does not send camera commands, write
/// characteristics, request pairing PINs, or expose MAC addresses in logs.
class EbolaGattInspectorPage extends StatefulWidget {
  const EbolaGattInspectorPage({super.key});

  @override
  State<EbolaGattInspectorPage> createState() => _EbolaGattInspectorPageState();
}

class _EbolaGattInspectorPageState extends State<EbolaGattInspectorPage> {
  final Map<String, ScanResult> _found = {};
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  BluetoothDevice? _connected;
  List<BluetoothService> _services = [];
  String _status = 'Ready — scanning is read-only';
  bool _busy = false;

  @override
  void dispose() {
    _scanSubscription?.cancel();
    FlutterBluePlus.stopScan().catchError((Object _) {});
    final connected = _connected;
    if (connected != null) {
      connected.disconnect().catchError((Object _) {});
    }
    super.dispose();
  }

  Future<void> _scan() async {
    if (_busy) return;
    setState(() { _busy = true; _status = 'Scanning nearby BLE advertisements…'; _found.clear(); _services = []; });
    try {
      await FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        if (!mounted) return;
        setState(() {
          for (final result in results) {
            _found[result.device.remoteId.str] = result;
          }
        });
      });
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 12));
      await Future<void>.delayed(const Duration(seconds: 12, milliseconds: 250));
      if (mounted) setState(() => _status = 'Scan complete: ${_found.length} advertisers. Select V03 Pro to inspect GATT.');
    } catch (e) {
      if (mounted) setState(() => _status = 'Scan error: ${e.runtimeType}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _inspect(ScanResult candidate) async {
    if (_busy) return;
    setState(() { _busy = true; _services = []; _status = 'Connecting to selected BLE device…'; });
    final device = candidate.device;
    try {
      await FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();
      if (_connected != null && _connected != device) {
        await _connected!.disconnect();
      }
      await device.connect(timeout: const Duration(seconds: 15), autoConnect: false);
      _connected = device;
      if (mounted) setState(() => _status = 'GATT connected. Discovering services…');
      final services = await device.discoverServices();
      if (mounted) setState(() {
        _services = services;
        _status = 'GATT CONNECTED — ${services.length} services discovered. Read-only inspection; camera protocol not verified.';
      });
    } catch (e) {
      if (mounted) setState(() => _status = 'GATT connection/discovery failed: ${e.runtimeType}. OEM compatibility not proven.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final found = _found.values.toList()
      ..sort((a, b) {
        final aName = a.advertisementData.advName.toLowerCase().contains('v03') ? 1 : 0;
        final bName = b.advertisementData.advName.toLowerCase().contains('v03') ? 1 : 0;
        return bName.compareTo(aName);
      });
    return Scaffold(
      appBar: AppBar(title: const Text('EBOLA AI · GATT Inspector'), backgroundColor: const Color(0xFFD00016), foregroundColor: Colors.white),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Built-in BLE diagnostics · read only', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('No OEM authentication, camera capture, characteristic writes or pairing bypass. Disconnects on exit.'),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: _busy ? null : _scan, icon: const Icon(Icons.bluetooth_searching), label: const Text('SCAN BLE DEVICES')),
        const SizedBox(height: 12),
        SelectableText(_status),
        const Divider(),
        ...found.map((result) {
          final name = result.advertisementData.advName.isNotEmpty ? result.advertisementData.advName : '(unnamed)';
          final ids = result.advertisementData.manufacturerData.keys.join(', ');
          return Card(child: ListTile(
            title: Text(name),
            subtitle: Text('RSSI ${result.rssi} dBm · manufacturer IDs: ${ids.isEmpty ? 'none' : ids}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _busy ? null : () => _inspect(result),
          ));
        }),
        if (_services.isNotEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('GATT SERVICES / CHARACTERISTICS', style: TextStyle(fontWeight: FontWeight.bold))),
        ..._services.map((service) => Card(child: ExpansionTile(
          title: SelectableText('Service ${service.uuid}'),
          children: service.characteristics.map((c) => ListTile(
            title: SelectableText('${c.uuid}'),
            subtitle: Text('read=${c.properties.read} · notify=${c.properties.notify} · write=${c.properties.write}'),
          )).toList(),
        ))),
      ]),
    );
  }
}
