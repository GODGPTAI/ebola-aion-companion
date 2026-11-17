// EBOLA AION - development-only hardware camera probe.
// UI branding is EBOLA AION. Third-party dependency identity must remain in
// technical/legal notices and package manifests as its licence requires.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:moyoung_glasses_ble_plugin/moyoung_glasses_ble.dart';

class EbolaAionCameraProbe extends StatefulWidget {
  const EbolaAionCameraProbe({super.key});
  @override
  State<EbolaAionCameraProbe> createState() => _EbolaAionCameraProbeState();
}

class _EbolaAionCameraProbeState extends State<EbolaAionCameraProbe> {
  final MoYoungGlassesBle _device = MoYoungGlassesBle();
  final List<String> _events = <String>[];
  final Map<String, String> _found = <String, String>{};
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  String? _selected;
  bool _ready = false;
  bool _connected = false;
  bool _busy = false;
  bool _cameraConsent = false;

  void _log(String message) {
    if (!mounted) return;
    setState(() {
      _events.insert(0, '${DateTime.now().toIso8601String()} $message');
      if (_events.length > 120) _events.removeLast();
    });
  }

  Future<void> _run(String title, Future<void> Function() job) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await job();
    } catch (error) {
      _log('$title FAILED: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _initialize() async {
    await _run('Initialize', () async {
      final result = await _device.initialize();
      final btEnabled = await _device.checkBluetoothEnable;
      if (result != true || btEnabled != true) {
        _log('NOT READY: initialization=$result, bluetooth=$btEnabled');
        return;
      }
      _subscriptions.add(_device.bleScanEveStm.listen((dynamic found) {
        final id = '${found.address}';
        final name = '${found.name}';
        if (!mounted || id.isEmpty) return;
        setState(() {
          _found[id] = name;
          _selected ??= id;
        });
        _log('Device discovered: $name'); // Don't leak MAC/address into UI logs.
      }, onError: (Object err) => _log('Scan stream error: $err')));
      _subscriptions.add(_device.connStateEveStm.listen((dynamic state) {
        _log('Connection state event received: ${state.connectState}');
      }, onError: (Object err) => _log('Connection stream error: $err')));
      _subscriptions.add(_device.actionResultEveStm.listen((dynamic event) {
        _log('Device action result: ${event['action']} code=${event['code']}');
      }, onError: (Object err) => _log('Action stream error: $err')));
      _subscriptions.add(_device.aiImageDataEveStm.listen((dynamic image) {
        _log('AI image event received (content not logged)');
      }, onError: (Object err) => _log('AI image stream error: $err')));
      setState(() => _ready = true);
      _log('EBOLA AION device bridge initialized');
    });
  }

  Future<void> _scan() async {
    await _run('Scan', () async {
      if (!_ready) throw StateError('Initialize first');
      setState(() { _found.clear(); _selected = null; });
      final started = await _device.startScan(10);
      _log('Scan request: $started (10 seconds)');
    });
  }

  Future<void> _connect() async {
    await _run('Connect', () async {
      if (!_ready || _selected == null) throw StateError('Select discovered glass');
      await _device.connect(ConnectBean(address: _selected!));
      _log('Connection request submitted; awaiting device state');
      _log(_connected ? 'GLASS CONNECTED' : 'CONNECTION FAILED');
    });
  }

  Future<void> _photo() async {
    await _run('Glass photo', () async {
      if (!_connected || !_cameraConsent) {
        throw StateError('Glass must be connected and camera consent enabled');
      }
      _log('Sending physical glass photo command');
      await _device.takePhoto(photoMode: 0);
      _log('PHOTO COMMAND SENT; capture and import NOT yet verified');
    });
  }

  Future<void> _importMedia() async {
    await _run('Media import', () async {
      if (!_connected || !_cameraConsent) throw StateError('Connect and consent first');
      // Local app-cache output only; do not send data to server from this probe.
      final dir = await Directory.systemTemp.createTemp('ebola_aion_glass_');
      _log('Starting glass Wi-Fi media sync');
      try {
        final wifi = await _device.isWifiRadioEnabled();
        _log('Phone Wi-Fi radio enabled: $wifi');
        if (wifi != true) throw StateError('Enable phone Wi-Fi');
        await _device.enableWifi(wifiType: 1);
        await _device.connectToDeviceWifi();
        final result = await _device.downloadMediaFilesToDir(targetDir: dir.path);
        _log('MEDIA IMPORT: success=${result['success']}, partial=${result['partial']}, '
            'count=${result['successCount']}, failures=${result['failCount']}');
        _log('Media stays in private temporary app storage; no upload performed');
      } catch (error) {
        _log('Media import failure: $error');
        rethrow;
      } finally {
        try { await _device.disableWifi(); } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) { subscription.cancel(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EBOLA AION — Glass Camera Test')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Physical smart-glasses camera only — no laptop or phone camera.'),
        const Text('Development test. Photo command sent is NOT proof of media receipt.'),
        SwitchListTile(title: const Text('Allow camera test for this session'),
          value: _cameraConsent, onChanged: (value) => setState(() => _cameraConsent = value)),
        FilledButton(onPressed: _busy || _ready ? null : _initialize, child: const Text('1. Initialize Device SDK')),
        FilledButton(onPressed: _busy || !_ready ? null : _scan, child: const Text('2. Find Glasses')),
        DropdownButton<String>(isExpanded: true, hint: const Text('Select glass'), value: _selected,
          items: _found.entries.map((e) => DropdownMenuItem(value: e.key,
            child: Text(e.value.isEmpty ? 'EBOLA AION Glass' : e.value))).toList(),
          onChanged: (v) => setState(() => _selected = v)),
        FilledButton(onPressed: _busy || _selected == null ? null : _connect, child: const Text('3. Connect Glass')),
        FilledButton(onPressed: _busy || !_connected || !_cameraConsent ? null : _photo,
          child: const Text('4. SHOOT PHOTO — GLASS CAMERA')),
        FilledButton(onPressed: _busy || !_connected || !_cameraConsent ? null : _importMedia,
          child: const Text('5. Download Glass Photo / Video')),
        const SizedBox(height: 12),
        const Text('Video start/stop and production Vault upload: NOT YET ENABLED.'),
        const Divider(),
        const Text('Device diagnostics', style: TextStyle(fontWeight: FontWeight.bold)),
        for (final event in _events) SelectableText(event, style: const TextStyle(fontSize: 12)),
      ]),
    );
  }
}
