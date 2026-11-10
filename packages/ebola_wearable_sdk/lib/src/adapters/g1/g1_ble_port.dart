/// App/Android implementation supplies the real BLE stack. No UUID or packets
/// are hardcoded until the exact glasses firmware is confirmed on hardware.
abstract class EbolaG1BlePort {
  Future<List<String>> scanDeviceIds();
  Future<void> connect(String deviceId);
  Future<void> disconnect();
  Future<int?> readBatteryPercent();
  Future<Map<String, Object?>> readDeviceInformation();
  Future<void> close();
}
