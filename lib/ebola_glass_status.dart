// In-process hardware discovery telemetry, never simulated.
// State resets at app start; this does not persist personal hardware IDs.
import 'package:flutter/foundation.dart';

@immutable
class EbolaGlassStatus {
  final String phase;
  final String candidate;
  final String rssi;
  final String battery;
  final String connection;
  final int discoveryPercent;
  final bool connected;
  const EbolaGlassStatus({
    this.phase = 'Not started',
    this.candidate = 'None detected',
    this.rssi = '-- dBm',
    this.battery = 'Not queried',
    this.connection = 'Not connected',
    this.discoveryPercent = 0,
    this.connected = false,
  });
  EbolaGlassStatus copyWith({String? phase, String? candidate,
    String? rssi, String? battery, String? connection,
    int? discoveryPercent, bool? connected}) => EbolaGlassStatus(
      phase: phase ?? this.phase,
      candidate: candidate ?? this.candidate,
      rssi: rssi ?? this.rssi,
      battery: battery ?? this.battery,
      connection: connection ?? this.connection,
      discoveryPercent: discoveryPercent ?? this.discoveryPercent,
      connected: connected ?? this.connected,
    );
}

final ValueNotifier<EbolaGlassStatus> ebolaGlassStatus =
    ValueNotifier<EbolaGlassStatus>(const EbolaGlassStatus());
