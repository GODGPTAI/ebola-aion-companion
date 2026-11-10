import 'package:test/test.dart';
import 'package:ebola_wearable_sdk/ebola_wearable_sdk.dart';
class FakeVault implements EbolaSecureMediaPort {
 bool wiped=false;
 @override Future<String> uploadToUserVault(EbolaMediaManifest manifest) async=>'vault-receipt';
 @override Future<bool> verifyVaultReceipt(String receipt) async=>receipt=='vault-receipt';
 @override Future<void> wipeTemporaryMedia(String localPath) async {wiped=true;}
}
void main(){
 test('Verified vault receipt precedes temporary media deletion',() async {
   final vault=FakeVault();
   final receipt=await EbolaMediaTransferCoordinator(vault).transfer(EbolaMediaManifest(
     deviceId:'d',localPath:'/tmp/photo',mimeType:'image/jpeg',sizeBytes:100,
     sha256Hex:List.filled(64,'a').join(),capturedAtUtc:DateTime.utc(2026)));
   expect(receipt,'vault-receipt'); expect(vault.wiped,isTrue);
 });
}
