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
  String _batteryLabel = 'Not checked';
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    FlutterBluePlus.stopScan().catchError((Object _) {});
    final connected = _connected;
    if (connected != null) {
      connected.disconnect().catchError((Object _) {});
    }
    super.dispose();
  }

  /// BLE advertisements can omit the name even if the same glass was named
  /// in an earlier scan. This is a *candidate*, never OEM authentication.
  String _candidateName(ScanResult result) {
    final adv = result.advertisementData.advName.trim();
    if (adv.isNotEmpty) return adv;
    return result.device.platformName.trim();
  }

  bool _isV03Candidate(ScanResult result) {
    final name = _candidateName(result).toLowerCase();
    final nameMatches = name == 'v03 pro' || name == 'v03pro' ||
        name == 'aimb-g2 pro' || name == 'aimb-g2pro';
    // 61679 was OBSERVED on this user's V03 Pro, not a universal vendor ID.
    // It only marks a provisional candidate. GATT is still inspected safely.
    return nameMatches || result.advertisementData.manufacturerData.containsKey(61679);
  }

  String _candidateLabel(ScanResult result) {
    final name = _candidateName(result);
    if (name.isNotEmpty) return name;
    if (result.advertisementData.manufacturerData.containsKey(61679)) {
      return 'Possible V03 Pro (unverified)';
    }
    return '(unknown)';
  }

  /// One action: scan, uniquely identify V03 Pro, connect, read GATT and battery.
  /// Never connects to an unnamed or ambiguous device automatically.
  Future<void> _oneTapConnect() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = 'One-tap: scanning V03 name + observed manufacturer marker…';
      _found.clear();
      _services = [];
      _batteryLabel = 'Not checked';
    });
    ScanResult? match;
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
      await FlutterBluePlus.stopScan();
      final matches = _found.values.where(_isV03Candidate).toList();
      if (matches.length == 1) {
        match = matches.single;
      } else if (mounted) {
        setState(() => _status = matches.isEmpty
            ? 'V03 Pro not found in this scan. Turn on/restart glass, disconnect other apps, and retry. No GATT connection.'
            : '${matches.length} possible V03 devices found. Select the correct glass below; auto-connect blocked.');
      }
    } catch (e) {
      if (mounted) setState(() => _status = 'Auto scan failed: ${e.runtimeType}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (match != null && mounted) await _inspect(match);
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
      if (mounted) setState(() => _status = 'Scan complete: ${_found.length} BLE advertisers, ${_found.values.where(_isV03Candidate).length} V03 candidates. Select your glass to inspect GATT.');
    } catch (e) {
      if (mounted) setState(() => _status = 'Scan error: ${e.runtimeType}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _inspect(ScanResult candidate) async {
    if (_busy) return;
    setState(() { _busy = true; _services = []; _batteryLabel = 'Not checked'; _status = 'Connecting to selected BLE device…'; });
    final device = candidate.device;
    try {
      await FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();
      if (_connected != null && _connected != device) {
        await _connected!.disconnect();
      }
      await device.connect(timeout: const Duration(seconds: 15), autoConnect: false);
      _connected = device;
      await _connectionSubscription?.cancel();
      _connectionSubscription = device.connectionState.listen((state) {
        if (!mounted || _connected != device) return;
        if (state == BluetoothConnectionState.disconnected) {
          setState(() {
            _connected = null;
            _services = [];
            _batteryLabel = 'Not connected';
            _status = 'GATT disconnected. Reconnect to inspect again.';
          });
        }
      });
      if (mounted) setState(() => _status = 'GATT connected. Discovering services…');
      final services = await device.discoverServices();
      String battery = 'Battery service unavailable';
      for (final service in services) {
        if (service.uuid.str.toLowerCase() != '180f') continue;
        for (final characteristic in service.characteristics) {
          if (characteristic.uuid.str.toLowerCase() == '2a19' && characteristic.properties.read) {
            try {
              final data = await characteristic.read();
              battery = data.isNotEmpty ? '${data.first}%' : 'Battery returned no data';
            } catch (error) {
              battery = 'Battery read failed: ${error.runtimeType}';
            }
          }
        }
      }
      if (mounted) setState(() {
        _services = services;
        _batteryLabel = battery;
        _status = 'GATT CONNECTED — ${services.length} services discovered. BLE only; OEM camera NOT connected.';
      });
    } catch (e) {
      if (mounted) setState(() => _status = 'GATT connection/discovery failed: ${e.runtimeType}. OEM compatibility not proven.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show only named V03 candidates / the observed V03 manufacturer marker.
    // Do not present unrelated phones, earbuds or watches as glasses.
    final found = _found.values.where(_isV03Candidate).toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi));
    return Scaffold(
      appBar: AppBar(title: const Text('EBOLA AI · GATT Inspector'), backgroundColor: const Color(0xFFD00016), foregroundColor: Colors.white),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Built-in BLE diagnostics · read only', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('No OEM authentication, camera capture, characteristic writes or pairing bypass. Disconnects on exit.'),
        const Text('Candidate filter: V03 Pro name or previously observed manufacturer ID 61679. Other BLE devices hidden.'),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: _busy ? null : _oneTapConnect, icon: const Icon(Icons.link), label: const Text('ONE TAP CONNECT V03 PRO')),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: _busy ? null : _scan, icon: const Icon(Icons.bluetooth_searching), label: const Text('MANUAL BLE SCAN')),
        const SizedBox(height: 12),
        SelectableText(_status),
        Text('Glass battery: $_batteryLabel'),
        const Divider(),
        ...found.map((result) {
          final name = _candidateLabel(result);
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
