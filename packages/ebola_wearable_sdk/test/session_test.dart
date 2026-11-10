import 'package:test/test.dart';
import 'package:ebola_wearable_sdk/ebola_wearable_sdk.dart';
void main(){
 test('Mock device session connects, checks status and disconnects',() async {
   final mock=EbolaMockAdapter(); final bus=EbolaEventBus();
   final session=EbolaDeviceSession(mock,bus); final device=(await mock.scan()).first;
   await session.connect(device);
   expect(session.status,EbolaConnectionStatus.connected);
   session.requireConnected(device.id);
   await session.disconnect();
   expect(session.status,EbolaConnectionStatus.disconnected);
   await bus.dispose();
 });
}
