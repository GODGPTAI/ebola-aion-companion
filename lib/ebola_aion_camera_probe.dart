import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
// EBOLA AION - V03 integrated diagnostic build 2026-11-21.
// EBOLA AION - development-only hardware camera probe.
// UI branding is EBOLA AION. Third-party dependency identity must remain in
// technical/legal notices and package manifests as its licence requires.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:moyoung_glasses_ble_plugin/moyoung_glasses_ble.dart';
import 'package:moyoung_glasses_ble_plugin/impl/moyoung_glasses_contants.dart' as mg;
import 'ebola_glass_status.dart';

class EbolaAionCameraProbe extends StatefulWidget {
  const EbolaAionCameraProbe({super.key});
  @override
  State<EbolaAionCameraProbe> createState() => _EbolaAionCameraProbeState();
}

class _EbolaAionCameraProbeState extends State<EbolaAionCameraProbe> with WidgetsBindingObserver {
  final MoYoungGlassesBle _device = MoYoungGlassesBle();
  final List<String> _events = <String>[];
  final Map<String, String> _found = <String, String>{};
  // Unfiltered raw BLE observations for troubleshooting only; not OEM connect targets.
  final Map<String, String> _rawNearby = <String, String>{};
  // OEM SDK discoveries are the only connectable candidates.
  // Raw BLE advertisements are observations, not verified SDK targets.
  final Map<String, String> _oemFound = <String, String>{};
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  String? _selected;
  bool _ready = false;
  bool _connected = false;
  // EBOLA_V03_DEVICE_DASH_V1 - local diagnostic state, not OEM authentication.
  String _batteryReport = 'Not queried';
  String _lastBleCandidate = 'None detected';
  int _rawBleCount = 0;
  bool _busy = false;
  bool _cameraConsent = false;
  // Imported photos remain local to the phone; no server upload.
  final List<File> _importedPhotos = <File>[];
  String _mediaStatus = 'No photos imported yet';
  // EBOLA_V03_VOICE_VIDEO_V1: local UI state, NOT device capture acknowledgement.
  final SpeechToText _speech = SpeechToText();
  bool _voiceListening = false;
  bool _videoCommandSent = false;
  String _connectionPhase = 'Not connected';
  String _signalReport = '-- dBm';
  String _scanPhase = 'Idle';
  StreamSubscription<BluetoothAdapterState>? _adapterWatch;
  bool _autoScanRequested = false;
  bool _rawScanCompleted = false;
  DateTime? _lastResumedScan;
  String _scanHint = 'Turn on both glasses and keep them close to your phone.';
  // The 100% bar represents DISCOVERY FINISHED, never connected/verified.


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Device discovery is read-only. Camera use still requires consent.
    _adapterWatch = FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.on && !_autoScanRequested) {
        _autoScanRequested = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _autoDiscover();
        });
      } else if (state != BluetoothAdapterState.on) {
        _autoScanRequested = false;
        if (mounted) setState(() {
          _connectionPhase = 'Bluetooth off';
          _connected = false;
          ebolaGlassStatus.value = ebolaGlassStatus.value.copyWith(
            connected: false, connection: 'Bluetooth off', discoveryPercent: 0);

        });
      }
    }, onError: (Object error) => _log('Bluetooth monitor error: $error'));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted || _busy || _connected) return;
    final now = DateTime.now();
    if (_lastResumedScan != null &&
        now.difference(_lastResumedScan!) < const Duration(seconds: 35)) return;
    _lastResumedScan = now;
    // Rescan only when discovery has no usable candidate. Do not auto-connect.
    if (_found.isEmpty && _ready) {
      _log('APP RESUMED: retrying BLE discovery (no camera command)');
      _scan();
    }
  }

  Future<void> _autoDiscover() async {
    if (_busy) return;
    setState(() => _scanPhase = 'Initializing SDK');
    ebolaGlassStatus.value = ebolaGlassStatus.value.copyWith(
      phase: 'Initializing SDK', discoveryPercent: 10);
    if (!_ready) await _initialize();
    if (!mounted || !_ready) {
      if (mounted) setState(() => _scanPhase = 'SDK initialization failed');
      return;
    }
    await _discoverAndConnect();
  }

  // OEM discovery is authoritative for camera BLE. Do not overlap a generic
  // Bluetooth scan with an active SDK connection attempt.
  Future<void> _discoverAndConnect() async {
    if (!mounted || !_ready || _busy) return;
    setState(() {
      _scanPhase = 'Searching V03 Pro through OEM SDK';
      _scanHint = 'SDK scanning first; RAW BLE is diagnostic fallback only.';
      _found.clear();
      _oemFound.clear();
      _selected = null;
      _rawNearby.clear();
      _rawBleCount = 0;
    });
    ebolaGlassStatus.value = ebolaGlassStatus.value.copyWith(
      phase: 'OEM SDK scanning', discoveryPercent: 40);
    await _sdkDiscoveryFallback();
    if (!mounted) return;
    _log('DISCOVERY RESULT: OEM candidates=${_oemFound.length}');
    if (_oemFound.isNotEmpty) {
      // Scan has finished, so the busy guard no longer suppresses connect().
      await _connectKnownV03();
      if (!mounted) return;
      if (_connectionPhase.startsWith('Connecting') ||
          _connectionPhase.startsWith('Awaiting') || _connected) {
        setState(() => _scanPhase = _connectionPhase);
        _log('RAW diagnostic scan skipped: SDK connection is in progress');
        return;
      }
      setState(() => _scanPhase =
          'SDK candidate found - select and tap Connect Glass');
      _log('SDK device available for manual connection; RAW scan skipped');
      return;
    }
    // RAW scan is only useful when the OEM scan returned no devices.
    _log('OEM SDK returned zero devices; beginning independent RAW BLE diagnostic');
    await _rawBleScan();
    if (!mounted) return;
    setState(() => _scanPhase = _rawScanCompleted
        ? 'OEM 0; RAW BLE devices=$_rawBleCount - inspect diagnostics'
        : 'BLE scanning failed - inspect diagnostics');
    ebolaGlassStatus.value = ebolaGlassStatus.value.copyWith(
      phase: _scanPhase, discoveryPercent: _rawScanCompleted ? 100 : 40);
  }

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
      final scanPerm = await Permission.bluetoothScan.request();
      final connectPerm = await Permission.bluetoothConnect.request();
      _log('SDK PREFLIGHT bluetoothScan=$scanPerm bluetoothConnect=$connectPerm');
      if (!scanPerm.isGranted || !connectPerm.isGranted) {
        _log('SDK initialization blocked: allow Nearby Devices permission');
        throw StateError('Nearby Devices permission denied');
      }
      final result = await _device.initialize();
      final btEnabled = await _device.checkBluetoothEnable;
      if (result != true || btEnabled != true) {
        _log('NOT READY: initialization=$result, bluetooth=$btEnabled');
        throw StateError('OEM SDK init failed (initialize=$result bluetooth=$btEnabled)');
      }
      _subscriptions.add(_device.bleScanEveStm.listen((dynamic found) {
        final id = '${found.address}';
        final name = '${found.name}';
        if (!mounted || id.isEmpty) return;
        setState(() {
          _oemFound[id] = name;
          _found[id] = name;
          _selected ??= id;
        });
        _log('OEM SDK DEVICE: $name (connectable candidate, not yet connected)');
      }, onError: (Object err) => _log('Scan stream error: $err')));
      // SDK 1.4.0 ConnectStateBean.connectState is an INT, not the word
      // "connected". Compare to the OEM constants, never a guessed bool.
      _subscriptions.add(_device.connStateEveStm.listen((dynamic state) {
        final dynamic rawCode = state.connectState;
        final int? code = rawCode is int ? rawCode : int.tryParse('$rawCode');
        final success = code != null && code == mg.ConnectionState.connected;
        final lost = code == mg.ConnectionState.disconnected ||
            code == mg.ConnectionState.disconnecting;
        final phase = success ? 'Connected (SDK event)' :
            code == mg.ConnectionState.connecting ? 'Connecting (SDK event)' :
            code == mg.ConnectionState.disconnecting ? 'Disconnecting' :
            code == mg.ConnectionState.disconnected ? 'Disconnected' :
            'Unknown SDK state $code';
        if (!mounted) return;
        setState(() {
          _connectionPhase = phase;
          if (success) _connected = true;
          if (lost || code == mg.ConnectionState.connecting) {
            _connected = false;
            if (lost) _batteryReport = 'Not queried';
          }
        });
        ebolaGlassStatus.value = ebolaGlassStatus.value.copyWith(
          connected: _connected,
          connection: phase,
          battery: _connected ? _batteryReport : 'Not queried');
        _log('OEM connection state=$code phase=$phase; sdkConnected=$success');
      }, onError: (Object err) => _log('Connection stream error: $err')));
      _subscriptions.add(_device.batteryEveStm.listen((dynamic battery) {
        final value = battery is Map ? battery['battery'] : null;
        final charging = battery is Map ? battery['charging'] : null;
        if (!_connected) return; // Never show a disconnected glass as live.
        final report = value == null ? 'Response: $battery' :
            '$value%${charging == true ? ' (charging)' : ''}';
        if (mounted) setState(() => _batteryReport = report);
        ebolaGlassStatus.value = ebolaGlassStatus.value.copyWith(battery: report);
        _log('OEM battery event received; percentage=${value ?? "unknown"}, charging=${charging ?? "unknown"}');
      }, onError: (Object err) => _log('Battery stream error: $err')));
      _subscriptions.add(_device.actionResultEveStm.listen((dynamic event) {
        _log('Device action result: ${event['action']} code=${event['code']}');
      }, onError: (Object err) => _log('Action stream error: $err')));
      _subscriptions.add(_device.aiImageDataEveStm.listen((dynamic image) {
        _log('AI image event received (content not logged)');
      }, onError: (Object err) => _log('AI image stream error: $err')));
      setState(() => _ready = true);
      _log('EBOLA AION device bridge initialized; MoYoung scan listener attached');
    });
  }

  // Find Glasses runs OEM discovery first; Android raw discovery is diagnostics only.
  // Scan itself never sends a camera command. Auto-connect requires OEM V03 discovery.
  // Auto-connect only to a V03 address reported by the OEM SDK.
  // Raw scanner results are never accepted as connection credentials.
  Future<void> _connectKnownV03() async {
    if (!mounted || _connected || !_ready) return;
    if (_busy) {
      _log('AUTO CONNECT BLOCKED: SDK scan still busy; finish scan first');
      return;
    }
    String? v03;
    for (final entry in _oemFound.entries) {
      if (entry.value.toLowerCase().contains('v03')) {
        v03 = entry.key;
        break;
      }
    }
    if (v03 == null) {
      _log('AUTO CONNECT: OEM candidates exist but none advertise V03; select the correct OEM device manually');
      return;
    }
    setState(() => _selected = v03);
    _log('AUTO CONNECT: V03 discovered by OEM SDK; requesting connection');
    await _connect();
  }

  Future<void> _scan() async {
    if (_busy || !_ready) {
      _log('SCAN BLOCKED: SDK not ready or another operation is running');
      return;
    }
    await _discoverAndConnect();
  }

  Future<void> _connect() async {
    await _run('Connect', () async {
      if (!_ready || _selected == null || !_oemFound.containsKey(_selected)) {
        throw StateError('Select a glass discovered by the OEM SDK');
      }
        final model = (_oemFound[_selected] ?? '').toLowerCase();
        if (model.contains('aimb') || model.contains('g2pro')) {
          throw StateError('AIMB-G2 Pro discovered, but DZZ camera protocol is not verified. Bluetooth audio remains available.');
        }
      if (mounted) setState(() { _connected = false; _connectionPhase = 'Connecting - waiting for SDK confirmation'; });
      ebolaGlassStatus.value = ebolaGlassStatus.value.copyWith(
        connected: false, connection: 'Awaiting SDK confirmation');
      try {
        await _device.connect(ConnectBean(address: _selected!));
        _log('Connection request submitted; waiting for asynchronous SDK confirmation');
        // Diagnostic watchdog only: never asserts a connection or disconnects.
        Future<void>.delayed(const Duration(seconds: 12), () {
          if (!mounted || _connected ||
              !_connectionPhase.startsWith('Connecting')) return;
          _log('SDK CONNECT TIMEOUT: no Connected event after 12 seconds; '
              'check SDK/device compatibility and native logs');
          setState(() => _connectionPhase = 'No SDK Connected event received');
        });
      } catch (error) {
        if (mounted) setState(() => _connectionPhase = 'SDK connect request failed');
        _log('OEM CONNECT REQUEST ERROR: $error');
        rethrow;
      }
    });
  }

  Future<void> _sdkDiscoveryFallback() async {
    await _run('OEM SDK discovery fallback', () async {
      _log('Requesting 10-second OEM SDK scan (separate from raw BLE)');
      if (mounted) setState(() => _scanHint =
          'Scanning for OEM-compatible glasses using the device SDK.');
      try {
        // Prevent the Android generic scanner from competing with the OEM scanner.
        await FlutterBluePlus.stopScan();
        final started = await _device.startScan(10);
        _log('OEM SDK SCAN request=$started');
        if (started != true) {
          _log('OEM SDK SCAN DID NOT START: SDK returned $started');
        }
        await Future<void>.delayed(const Duration(seconds: 11));
        _log('OEM SDK SCAN finished; OEM candidates=${_oemFound.length}');
      } catch (error) {
        _log('OEM SDK SCAN ERROR: $error');
      }
    });
  }

  Future<void> _rawBleScan() async {
    _rawScanCompleted = false;
    await _run('Raw BLE scan', () async {
      final seen = <String>{};
      if (mounted) setState(() => _rawNearby.clear());
      StreamSubscription<List<ScanResult>>? subscription;
      try {
        setState(() {
          _scanPhase = 'Checking Bluetooth, location services and permissions';
          _scanHint = 'Looking for BLE advertisements (not Classic audio pairing).';
        });
        final scanPermission = await Permission.bluetoothScan.request();
        final connectPermission = await Permission.bluetoothConnect.request();
        final locationService = await Permission.locationWhenInUse.serviceStatus;
        final locationPermission = await Permission.locationWhenInUse.status;
        _log('PREFLIGHT scan=$scanPermission connect=$connectPermission '
            'locationService=$locationService locationPermission=$locationPermission');
        final adapter = await FlutterBluePlus.adapterState.first;
        _log('PREFLIGHT adapter=$adapter');
        if (scanPermission != PermissionStatus.granted ||
            connectPermission != PermissionStatus.granted ||
            adapter != BluetoothAdapterState.on) {
          setState(() => _scanHint = 'Turn Bluetooth ON and allow Nearby devices permission in Android Settings.');
          throw StateError('BLE blocked: Bluetooth or Nearby devices permission');
        }
        if (locationService != ServiceStatus.enabled) {
          _log('LOCATION SERVICE OFF: Some phones suppress BLE discovery. '
              'Turn Android Location ON, then retry. No coordinates are accessed.');
          setState(() => _scanHint =
              'Enable Android Location switch (GPS) and retry. No GPS coordinates are collected.');
        } else if (!locationPermission.isGranted) {
          _log('LOCATION PERMISSION NOT GRANTED: scan will still run. '
              'Some Android devices need Location permission for BLE discovery.');
        }
        // Subscribe before starting the scan; do not filter out advertisers.
        subscription = FlutterBluePlus.onScanResults.listen((results) {
          for (final result in results) {
            final id = result.device.remoteId.toString();
            if (id.isEmpty) continue;
            final adv = result.advertisementData;
            final name = adv.advName.isNotEmpty ? adv.advName :
                (result.device.platformName.isNotEmpty ?
                    result.device.platformName : '(unnamed)');
            final isFirstSight = seen.add(id);
            // Repeated advertisements may gain a name later: update the record.
            // Display ALL advertisements, even unnamed ones. This list is
            // diagnostic only; never auto-connect to these raw addresses.
            if (mounted) {
              setState(() => _rawNearby[id] = '$name  |  ${result.rssi} dBm');
            }
            final lower = name.toLowerCase();
            if (lower.contains('v03') || lower.contains('aimb') ||
                lower.contains('g2pro') || lower.contains('glass')) {
              if (!mounted) continue;
              setState(() {
                _lastBleCandidate = '$name / RSSI ${result.rssi}';
                _signalReport = '${result.rssi} dBm (scan RSSI)';
              });
              ebolaGlassStatus.value = ebolaGlassStatus.value.copyWith(
                candidate: name, rssi: '${result.rssi} dBm (scan)',
                phase: 'Discovered $name', discoveryPercent: 75);
              if (isFirstSight) {
                _log('GLASS ADVERTISEMENT FOUND: $name RSSI=${result.rssi}; '
                    'camera protocol NOT verified');
              }
            } else {
              if (isFirstSight) {
                _log('BLE ADVERTISEMENT: $name RSSI=${result.rssi}');
              }
            }
          }
        }, onError: (Object error) => _log('RAW BLE STREAM ERROR: $error'));

        // Scan 1, then a second fresh scan only when the first returns nothing.
        // Avoid simultaneous OEM/FlutterBluePlus scans.
        for (var pass = 1; pass <= 2; pass++) {
          if (pass == 2 && seen.isNotEmpty) break;
          _log('RAW BLE PASS $pass STARTED (12 seconds)');
          if (mounted) setState(() => _scanPhase = 'BLE scan pass $pass of 2');
          await FlutterBluePlus.stopScan();
          await Future<void>.delayed(const Duration(milliseconds: 500));
          await FlutterBluePlus.startScan(timeout: const Duration(seconds: 12));
          await Future<void>.delayed(const Duration(milliseconds: 12400));
          _log('RAW BLE PASS $pass COMPLETE: unique devices=${seen.length}');
        }
        if (mounted) {
          setState(() {
            _rawBleCount = seen.length;
            if (seen.isEmpty) {
              _scanHint = '0 BLE advertisements. Turn both glasses ON, '
                  'close their OEM apps, enable Android Location, and retry nearby.';
            } else if (_found.isEmpty) {
              _scanHint = '${seen.length} BLE advertisers found; compare with OEM candidates. '
                  'Check that the glasses advertise in pairing mode.';
            } else {
              _scanHint = '${_oemFound.length} OEM candidates available. Select a glass. '
                  'Camera connection not yet authenticated.';
            }
          });
        }
        _rawScanCompleted = true;
        _log('RAW BLE SCAN COMPLETE uniqueDevices=${seen.length} '
            'OEMCandidates=${_oemFound.length}');
      } catch (error) {
        _log('RAW BLE ERROR: $error');
        if (mounted) setState(() => _scanHint = 'Raw BLE failed; OEM scan was attempted separately. Check SDK diagnostics.');
        rethrow;
      } finally {
        await subscription?.cancel();
        try { await FlutterBluePlus.stopScan(); } catch (_) {}
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
          if (words.contains('photo') || words.contains('picture') || words.contains('फोटो')) {
            _photo();
          } else if (words.contains('stop') && (words.contains('video') || words.contains('record')) || words.contains('वीडियो बंद')) {
            _stopGlassVideo();
          } else if ((words.contains('start') || words.contains('record') || words.contains('shoot')) && words.contains('video') || words.contains('वीडियो चालू')) {
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
        ebolaGlassStatus.value = ebolaGlassStatus.value.copyWith(
          battery: battery.toString());
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
        // The OEM transfer result alone is not evidence of a valid JPEG.
        // Inspect actual files and show only images physically downloaded.
        final files = await dir.list(recursive: true, followLinks: false)
            .where((item) => item is File)
            .cast<File>()
            .toList();
        final photos = <File>[];
        for (final file in files) {
          final lower = file.path.toLowerCase();
          if (!(lower.endsWith('.jpg') || lower.endsWith('.jpeg') ||
              lower.endsWith('.png') || lower.endsWith('.webp'))) continue;
          if (await file.length() == 0) continue;
          photos.add(file);
        }
        photos.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
        if (mounted) {
          setState(() {
            _importedPhotos
              ..clear()
              ..addAll(photos);
            _mediaStatus = photos.isEmpty
                ? 'Transfer finished; no nonempty photo files found'
                : '${photos.length} photo(s) imported to this phone';
          });
        }
        _log('LOCAL PHOTO FILES VERIFIED: ${photos.length}');
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
    WidgetsBinding.instance.removeObserver(this);
    _speech.cancel();
    _adapterWatch?.cancel();
    for (final subscription in _subscriptions) { subscription.cancel(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB71C1C),
          brightness: Brightness.light,
        ),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: const Color(0xFF161616),
          displayColor: const Color(0xFF161616),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFB71C1C),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFE5E5E5),
            disabledForegroundColor: const Color(0xFF555555),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFB71C1C),
          foregroundColor: Colors.white,
        ),
      ),
      child: Scaffold(
      appBar: AppBar(title: const Text('EBOLA AION - Glass Camera Test')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Physical smart-glasses camera only - no laptop or phone camera.'),
        const Text('Development test. Photo command sent is NOT proof of media receipt.'),
        Card(color: const Color(0xFFFFF4F4), child: Padding(
          padding: const EdgeInsets.all(12), child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('EBOLA AI | AUTO DEVICE TEST', style: TextStyle(
              color: Color(0xFFB71C1C), fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_scanPhase, style: const TextStyle(color: Color(0xFF161616))),
            const SizedBox(height: 5),
            Text(_scanHint, style: const TextStyle(
              color: Color(0xFF5B3333), fontSize: 12)),
            const SizedBox(height: 6),
            Text('Connection: $_connectionPhase', style: const TextStyle(color: Color(0xFF161616))),
            Text('Signal: $_signalReport', style: const TextStyle(color: Color(0xFF161616))),
            const Text('No automatic camera recording or upload. Capture requires consent.',
              style: TextStyle(color: Color(0xFF555555), fontSize: 11)),
          ]))),
        SwitchListTile(title: const Text('Allow camera test for this session'),
          value: _cameraConsent, onChanged: (value) => setState(() => _cameraConsent = value)),
        FilledButton(onPressed: _busy || _ready ? null : _initialize, child: const Text('1. Initialize Device SDK')),
        FilledButton(onPressed: _busy || !_ready ? null : _scan, child: const Text('2. Find Glasses')),
        DropdownButton<String>(isExpanded: true,
          dropdownColor: Colors.white,
          style: const TextStyle(color: Color(0xFF161616), fontSize: 16),
          hint: const Text('Select glass', style: TextStyle(color: Color(0xFF161616))),
          value: _selected,
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
        ),
        const SizedBox(height: 8),
        Text('ALL BLE ADVERTISEMENTS (${_rawNearby.length})',
          style: const TextStyle(fontWeight: FontWeight.bold)),
        if (_rawNearby.isEmpty)
          const Text('No BLE advertisements received yet. Check Nearby devices permission and Bluetooth.'),
        for (final entry in _rawNearby.entries)
          Text(entry.value, style: const TextStyle(fontSize: 12)),
        Text('OEM SDK candidates: ${_oemFound.length} (only these can connect)'),
        const Text('SDK scan is authoritative. Raw advertisements do not prove SDK compatibility.'),
        FilledButton(onPressed: _busy || !_ready ? null : _scan,
          child: const Text('RETRY FULL BLE DISCOVERY (raw + OEM)')),
        FilledButton(onPressed: _busy || _selected == null ? null : _connect, child: const Text('3. Connect Glass')),
        FilledButton(onPressed: _busy || !_connected || !_cameraConsent ? null : _photo,
          child: const Text('4. SHOOT PHOTO - GLASS CAMERA')),
        FilledButton(onPressed: _busy || !_connected || !_cameraConsent ? null : _importMedia,
          child: const Text('5. Download Glass Photo / Video')),
        const SizedBox(height: 12),
        Text('PHOTO DISPLAY  |  $_mediaStatus',
          style: const TextStyle(color: Color(0xFF161616), fontWeight: FontWeight.bold)),
        if (_importedPhotos.isEmpty)
          const Text('Connect Glass, allow camera test, take a photo, then tap Download Glass Photo / Video.'),
        for (final photo in _importedPhotos.take(10))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Image.file(photo, height: 240, fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                const Text('Downloaded file cannot be decoded as an image')),
          ),
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
      ),
    );
  }
}
