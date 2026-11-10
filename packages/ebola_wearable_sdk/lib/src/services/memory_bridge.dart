/// Only store memories via existing user-scoped backend + encrypted Vault.
abstract class EbolaMemoryBridge {
  Future<String> saveEvidence({required String vaultReceiptId,required String description});
  Future<List<String>> searchEvidence(String query);
}
