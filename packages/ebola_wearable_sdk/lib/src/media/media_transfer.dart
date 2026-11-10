import 'media_manifest.dart';
/// The SDK never calls a public-media storage endpoint. Host app must use
/// authenticated Vault service, verify receipt, then clear offline temp media.
abstract class EbolaSecureMediaPort {
  Future<String> uploadToUserVault(EbolaMediaManifest manifest);
  Future<bool> verifyVaultReceipt(String receipt);
  Future<void> wipeTemporaryMedia(String localPath);
}
class EbolaMediaTransferCoordinator {
  final EbolaSecureMediaPort port;
  EbolaMediaTransferCoordinator(this.port);
  Future<String> transfer(EbolaMediaManifest manifest) async {
    if (manifest.sizeBytes <= 0 || !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(manifest.sha256Hex)) {
      throw ArgumentError('Valid byte count and SHA256 checksum required');
    }
    final receipt = await port.uploadToUserVault(manifest);
    if (!await port.verifyVaultReceipt(receipt)) throw StateError('Vault receipt not verified');
    await port.wipeTemporaryMedia(manifest.localPath);
    return receipt;
  }
}
