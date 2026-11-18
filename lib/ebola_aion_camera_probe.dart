import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
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
  // EBOLA_V03_DEVICE_DASH_V1 â€” local diagnostic state, not OEM authentication.
  String _batteryReport = 'Not queried';
  String _lastBleCandidate = 'None detected';
  int _rawBleCount = 0;
  bool _busy = false;
  bool _cameraConsent = false;
  // EBOLA_V03_VOICE_VIDEO_V1: local UI state, NOT device capture acknowledgement.
  final SpeechToText _speech = SpeechToText();
  bool _voiceListening = false;
  bool _videoCommandSent = false;

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
      final perms = await [Permission.bluetoothScan, Permission.bluetoothConnect].request();
      if (perms.values.any((p) => !p.isGranted)) {
        throw StateError('Nearby devices permission required. Allow Bluetooth access in Android Settings.');
      }
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

    Future<void> _rawBleScan() async {
    await _run('Raw BLE scan', () async {
      final seen = <String>{};
      StreamSubscription<List<ScanResult>>? subscription;
      try {
        _log('RAW BLE SCAN STARTED (12 seconds, read-only)');
        subscription = FlutterBluePlus.onScanResults.listen(
          (results) {
            for (final result in results) {
              final id = result.device.remoteId.toString();
              if (!seen.add(id)) continue;
              final adv = result.advertisementData;
              final name = adv.advName.isNotEmpty
                  ? adv.advName
                  : (result.device.platformName.isNotEmpty
                      ? result.device.platformName
                      : '(unnamed)');
              if (mounted && (name.toLowerCase().contains('v03') ||
                  name.toLowerCase().contains('glass') ||
                  name.toLowerCase().contains('jl') ||
                  name.toLowerCase().contains('ai'))) {
                setState(() => _lastBleCandidate = '$name / RSSI ${result.rssi}');
              }
              _log('RAW BLE FOUND name=$name id=$id rssi=${result.rssi} '
                  'services=${adv.serviceUuids.join(',')}');
            }
          },
          onError: (Object error) => _log('RAW BLE STREAM ERROR: $error'),
        );
        await FlutterBluePlus.startScan(timeout: const Duration(seconds: 12));
        await Future<void>.delayed(const Duration(seconds: 13));
        if (mounted) setState(() => _rawBleCount = seen.length);
        _log('RAW BLE SCAN COMPLETE; unique devices=${seen.length}');
      } finally {
        await subscription?.cancel();
      }
    });
  }
  // Device ACK and actual saved media must be verified separately.
  Future<void> _startGlassVideo() async {
    await _run('Start glasses video', () async {
      if (!_connected || !_cameraConsent) {
        throw StateError('Connect glasses and enable camera consent first');
      }
      await _device.startVideo(duration: 60);
      if (mounted) setState(() => _videoCommandSent = true);
      _log('VIDEO START COMMAND SENT; firmware recording NOT yet confirmed');
    });
  }

  Future<void> _stopGlassVideo() async {
    await _run('Stop glasses video', () async {
      if (!_connected || !_cameraConsent) {
        throw StateError('Connect glasses and enable camera consent first');
      }
      await _device.stopVideo();
      if (mounted) setState(() => _videoCommandSent = false);
      _log('VIDEO STOP COMMAND SENT; imported file NOT yet verified');
    });
  }

  Future<void> _voiceCommand() async {
    if (_busy || _voiceListening) return;
    if (!_connected || !_cameraConsent) {
      _log('VOICE: first connect camera-capable BLE device and allow consent');
      return;
    }
    try {
      final available = await _speech.initialize(
        onError: (error) {
          _log('VOICE ERROR: $error');
          if (mounted) setState(() => _voiceListening = false);
        },
        onStatus: (status) {
          _log('VOICE STATUS: $status');
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _voiceListening = false);
          }
        },
      );
      if (!available) { _log('VOICE recognizer unavailable on this phone'); return; }
      if (mounted) setState(() => _voiceListening = true);
      _log('VOICE: say take photo / start video / stop video');
      await _speech.listen(
        listenFor: const Duration(seconds: 12),
        pauseFor: const Duration(seconds: 3),
        onResult: (result) {
          if (!result.finalResult) return;
          final words = result.recognizedWords.toLowerCase().trim();
          _log('VOICE heard: $words');
          _speech.stop();
          if (mounted) setState(() => _voiceListening = false);
          if (words.contains('photo') || words.contains('picture') || words.contains('à¤«à¥‹à¤Ÿà¥‹')) {
            _photo();
          } else if (words.contains('stop') && (words.contains('video') || words.contains('record')) || words.contains('à¤µà¥€à¤¡à¤¿à¤¯à¥‹ à¤¬à¤‚à¤¦')) {
            _stopGlassVideo();
          } else if ((words.contains('start') || words.contains('record') || words.contains('shoot')) && words.contains('video') || words.contains('à¤µà¥€à¤¡à¤¿à¤¯à¥‹ à¤šà¤¾à¤²à¥‚')) {
            _startGlassVideo();
          } else if (words.contains('camera on') || words.contains('camera open')) {
            _log('Camera ready only after BLE connect; no continuous preview API verified');
          } else if (words.contains('led') || words.contains('light off')) {
            _log('Hardware privacy LED is firmware-controlled; no LED override');
          } else {
            _log('Voice command not recognized as photo/video action');
          }
        },
      );
    } catch (error) {
      _log('VOICE COMMAND FAILED: $error');
      if (mounted) setState(() => _voiceListening = false);
    }
  }
  Future<void> _refreshGlassBattery() async {
    await _run('Read glass battery', () async {
      if (!_connected) {
        _log('BATTERY: Camera BLE connection is not ready; Android audio battery is separate');
        if (mounted) setState(() => _batteryReport = 'Camera BLE not connected');
        return;
      }
      try {
        final battery = await _device.queryBattery();
        if (mounted) setState(() => _batteryReport = battery.toString());
        _log('OEM BATTERY RESPONSE: $battery');
      } catch (error) {
        if (mounted) setState(() => _batteryReport = 'Read failed');
        _log('OEM BATTERY READ FAILED: $error');
      }
    });
  }
  Future<void> _photo() async {
    await _run('Glass photo', () async {
      if (!_connected || !_cameraConsent) {
        throw StateError('Glass must be connected and camera consent enabled');
      }
      _log('Sending physical glass photo command');
      await _device.takePhoto(photoMode: 0);
      await SystemSound.play(SystemSoundType.click);
      _log('PHONE SHUTTER CLICK REQUESTED');
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
    _speech.cancel();
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
        Card(
          color: const Color(0xFFFFF7F7),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('EBOLA AION  |  DEVICE COMMAND CENTRE',
                style: TextStyle(color: Color(0xFFB71C1C), fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Camera BLE: ${_connected ? "Connected (SDK report)" : "Not connected"}'),
              Text('Nearby BLE devices: $_rawBleCount'),
              Text('Candidate (not authenticated): $_lastBleCandidate'),
              Text('Camera BLE battery: $_batteryReport'),
              const Text('Phone Bluetooth audio and Camera BLE are separate connections.',
                style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _busy || !_connected ? null : _refreshGlassBattery,
                icon: const Icon(Icons.battery_full),
                label: const Text('READ GLASSES BATTERY'),
              ),
            ]),
          ),
        ),FilledButton(onPressed: _busy || !_ready ? null : _rawBleScan, child: const Text('RAW BLE SCAN: 12 seconds')),
        FilledButton(onPressed: _busy || _selected == null ? null : _connect, child: const Text('3. Connect Glass')),
        FilledButton(onPressed: _busy || !_connected || !_cameraConsent ? null : _photo,
          child: const Text('4. SHOOT PHOTO — GLASS CAMERA')),
        FilledButton(onPressed: _busy || !_connected || !_cameraConsent ? null : _importMedia,
          child: const Text('5. Download Glass Photo / Video')),
        FilledButton(onPressed: _busy || !_connected || !_cameraConsent ? null : _voiceCommand,
          child: Text(_voiceListening ? 'VOICE LISTENING...' : 'VOICE: TAKE PHOTO / START VIDEO / STOP VIDEO')),
        FilledButton(onPressed: _busy || !_connected || !_cameraConsent ? null : _startGlassVideo,
          child: const Text('START GLASS VIDEO (up to 60 s request)')),
        FilledButton(onPressed: _busy || !_connected || !_cameraConsent ? null : _stopGlassVideo,
          child: const Text('STOP GLASS VIDEO')),        const SizedBox(height: 12),
        const Text('Voice/photo/video are device commands, not proof of capture. Production Vault upload NOT ENABLED. LED is firmware controlled.'),
        const Divider(),
        const Text('Device diagnostics', style: TextStyle(fontWeight: FontWeight.bold)),
        for (final event in _events) SelectableText(event, style: const TextStyle(fontSize: 12)),
      ]),
    );
  }
}
