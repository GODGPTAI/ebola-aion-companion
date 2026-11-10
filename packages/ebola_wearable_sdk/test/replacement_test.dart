import 'package:test/test.dart';
import 'package:ebola_wearable_sdk/ebola_wearable_sdk.dart';
import 'package:ebola_wearable_sdk/src/licence/mock_licence_gateway.dart';
void main(){
 test('Test replacement revokes old hardware binding',() async {
   final gw=EbolaTestOnlyLicenceGateway();
   const old=EbolaDeviceBinding(deviceId:'OLD',modelCode:'G2');
   const replacement=EbolaDeviceBinding(deviceId:'NEW',modelCode:'G2');
   expect((await gw.activate(old)).allowed,isTrue);
   final result=await gw.replace(approvedCaseId:'DEMO-APPROVED-1',oldDevice:old,replacement:replacement);
   expect(result.allowed,isTrue);
   expect((await gw.validate(old)).allowed,isFalse);
   expect((await gw.validate(replacement)).allowed,isTrue);
 });
}
