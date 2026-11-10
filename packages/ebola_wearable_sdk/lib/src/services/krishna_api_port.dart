/// Reuses existing authenticated KRISHNA Master Brain; no second brain created.
abstract class EbolaKrishnaApiPort {
  Future<String> ask({required String userText, required String conversationId,
    required String deviceId, required String locale});
  Future<String> describeVaultAsset({required String vaultReceiptId, required String prompt});
}
