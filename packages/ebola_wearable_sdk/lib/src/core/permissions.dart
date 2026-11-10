enum EbolaPermission { bluetoothScan, bluetoothConnect, microphone, camera, nearbyWifi, location, notifications }
/// Must be implemented through Android/iOS permission prompts in the host app.
abstract class EbolaPermissionPort {
  Future<bool> isGranted(EbolaPermission permission);
  Future<bool> request(EbolaPermission permission);
}
class EbolaDenyByDefaultPermissions implements EbolaPermissionPort {
  @override Future<bool> isGranted(EbolaPermission permission) async => false;
  @override Future<bool> request(EbolaPermission permission) async => false;
}
