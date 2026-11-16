import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

void main() { WidgetsFlutterBinding.ensureInitialized(); runApp(const G2TestApp()); }

class G2TestApp extends StatelessWidget {
  const G2TestApp({super.key});
  @override Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'EBOLA AION G2 — Real BLE Test',
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFFD60920), scaffoldBackgroundColor: Colors.white),
    home: const G2TestHome(),
  );
}

class G2TestHome extends StatefulWidget {
  const G2TestHome({super.key});
  @override State<G2TestHome> createState() => _G2TestHomeState();
}

class _G2TestHomeState extends State<G2TestHome> {
  final Map<String, ScanResult> _found = <String, ScanResult>{};
  final List<String> _logs = <String>[];
  StreamSubscription<List<ScanResult>>? _scanSub;
  BluetoothDevice? _connected;
  bool _scanning = false, _working = false;
  int? _battery;
  String _status = 'Not connected';

  void _log(String value) {
    if (!mounted) return;
    setState(() { _logs.insert(0, '${DateTime.now().toLocal().toIso8601String().substring(11,19)}  $value'); if (_logs.length > 60) _logs.removeLast(); });
  }

  Future<bool> _permissions() async {
    final scan = await Permission.bluetoothScan.request();
    final connect = await Permission.bluetoothConnect.request();
    // Required on some Android 11-and-earlier devices for BLE scans.
    final location = await Permission.locationWhenInUse.request();
    _log('Permissions: scan=$scan, connect=$connect, location=$location');
    if (scan.isPermanentlyDenied || connect.isPermanentlyDenied) {
      _log('Bluetooth permission denied; enable it in Android App Settings.');
      return false;
    }
    return scan.isGranted || location.isGranted;
  }

  Future<void> _scan() async {
    if (_working || _scanning) return;
    setState(() { _working = true; _found.clear(); _battery = null; });
    try {
      if (!await _permissions()) { _log('Permissions unavailable'); return; }
      final state = await FlutterBluePlus.adapterState.firstWhere((state) => state != BluetoothAdapterState.unknown).timeout(const Duration(seconds: 8));
      _log('Bluetooth adapter: $state');
      if (state != BluetoothAdapterState.on) {
        _log('Turn Bluetooth ON in phone Settings, then scan again.');
        return;
      }
      await _scanSub?.cancel();
      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        if (!mounted) return;
        setState(() {
          for (final r in results) { _found[r.device.remoteId.str] = r; }
        });
      }, onError: (Object err) => _log('Scan stream error: $err'));
      setState(() { _scanning = true; });
      _log('BLE scan started (15 seconds); G2 must be awake and advertising.');
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
      await Future<void>.delayed(const Duration(seconds: 16));
      _log('BLE scan finished; ${_found.length} devices discovered.');
    } catch (e) {
      _log('BLE scan failed: $e');
    } finally {
      try { await FlutterBluePlus.stopScan(); } catch (_) {}
      if (mounted) setState(() { _scanning = false; _working = false; });
    }
  }

  Future<void> _connect(ScanResult result) async {
    if (_working || _scanning) return;
    setState(() { _working = true; _battery = null; _status = 'Connecting...'; });
    try {
      if (!await _permissions()) return;
      if (_connected != null) await _disconnect();
      final d = result.device;
      _log('Connecting to BLE device ${d.remoteId.str} (${result.advertisementData.advName})');
      await d.connect(timeout: const Duration(seconds: 18), autoConnect: false);
      _connected = d;
      if (mounted) setState(() => _status = 'BLE GATT connected');
      _log('BLE GATT connected; this does NOT prove V03 camera protocol compatibility.');
      await _readBattery();
    } catch (e) {
      _log('Connect error: $e');
      if (mounted) setState(() => _status = 'Connection failed');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _readBattery() async {
    final d = _connected;
    if (d == null) { _log('Connect to a BLE device first.'); return; }
    setState(() => _battery = null);
    try {
      final services = await d.discoverServices();
      _log('Discovered ${services.length} GATT services.');
      // Standard Battery Service 0x180F / Battery Level characteristic 0x2A19.
      for (final s in services) {
        if (s.uuid.toString().toLowerCase().contains('180f')) {
          for (final c in s.characteristics) {
            if (c.uuid.toString().toLowerCase().contains('2a19')) {
              final bytes = await c.read();
              if (bytes.isNotEmpty && bytes.first <= 100) {
                if (mounted) setState(() => _battery = bytes.first);
                _log('G2 BLE battery: ${bytes.first}% (standard GATT read)');
                return;
              }
            }
          }
        }
      }
      _log('Standard GATT battery characteristic not exposed; OEM protocol required.');
    } catch (e) { _log('Battery read error: $e'); }
  }

  Future<void> _disconnect() async {
    final d = _connected;
    _connected = null;
    if (mounted) setState(() { _status = 'Not connected'; _battery = null; });
    if (d != null) {
      try { await d.disconnect(); _log('Disconnected'); } catch (e) { _log('Disconnect error: $e'); }
    }
  }

  @override void dispose() {
    _scanSub?.cancel();
    FlutterBluePlus.stopScan().catchError((Object _) {});
    _connected?.disconnect();
    super.dispose();
  }

  @override Widget build(BuildContext context) {
    final items = _found.values.toList()..sort((a,b) => b.rssi.compareTo(a.rssi));
    return Scaffold(
      appBar: AppBar(title: const Text('EBOLA AION · G2 Test'), backgroundColor: const Color(0xFFD60920), foregroundColor: Colors.white),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('REAL BLUETOOTH LAB · V1.1', style: TextStyle(color: Color(0xFFBA001A), fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('V03 Pro • G2 Hardware Verification', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Connection: $_status', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Battery: ${_battery == null ? "Unavailable / not verified" : "$_battery%"}'),
          const SizedBox(height: 6),
          const Text('BLE scan only. Some glasses advertise a separate Classic Bluetooth audio name. Discovery does not prove camera access.', style: TextStyle(fontSize: 12)),
        ]))),
        const SizedBox(height: 8),
        FilledButton.icon(onPressed: (_working || _scanning) ? null : _scan, icon: const Icon(Icons.bluetooth_searching), label: Text(_scanning ? 'Scanning...' : 'Scan for G2 (15 sec)')),
        OutlinedButton.icon(onPressed: _connected == null ? null : _readBattery, icon: const Icon(Icons.battery_std), label: const Text('Read real GATT Battery')),
        OutlinedButton.icon(onPressed: _connected == null ? null : _disconnect, icon: const Icon(Icons.bluetooth_disabled), label: const Text('Disconnect')),
        const SizedBox(height: 16),
        Text('Nearby BLE devices (${items.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (items.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('No devices yet. Turn on the glasses and tap Scan. If your G2 only uses Classic Bluetooth, it may not appear.')),
        for (final r in items) Card(child: ListTile(
          title: Text(r.advertisementData.advName.isEmpty ? '(Unnamed BLE device)' : r.advertisementData.advName),
          subtitle: Text('${r.device.remoteId.str}\nRSSI: ${r.rssi} dBm'),
          trailing: const Icon(Icons.link),
          onTap: (_working || _scanning) ? null : () => _connect(r),
        )),
        const SizedBox(height: 12),
        const Text('Photo / Video', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('PENDING OEM ADAPTER: A BLE connection alone does not implement V03 Pro camera commands or Wi-Fi media transfer. No simulated success.'))),
        const SizedBox(height: 12),
        Row(children: [const Expanded(child: Text('Live hardware log', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))), IconButton(onPressed: () { setState(_logs.clear); }, icon: const Icon(Icons.delete_outline), tooltip: 'Clear log')]),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF8F1F1), borderRadius: BorderRadius.circular(12)),
          child: SelectableText(_logs.isEmpty ? 'No test run yet.' : _logs.join('\n'), style: const TextStyle(fontSize: 12))),
        const SizedBox(height: 16),
        const Text('Developer hardware diagnostics only. Never activate paid device licences from this test screen.', style: TextStyle(fontSize: 12, color: Colors.black54)),
      ])),
    );
  }
}
