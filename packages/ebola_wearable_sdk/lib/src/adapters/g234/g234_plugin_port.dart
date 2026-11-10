/// Implemented by a separately licensed and firmware-verified native/Flutter
/// plug-in. Public EBOLA apps never require brand-specific UX or code.
abstract class EbolaG234PluginPort {
  Future<List<String>> discover();
  Future<void> connect(String deviceId);
  Future<void> disconnect();
  Future<int?> battery();
  Future<Map<String, bool>> queryFeatures();
  Future<void> close();
}
