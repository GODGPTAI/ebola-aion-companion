import 'package:test/test.dart';
import 'package:ebola_wearable_sdk/ebola_wearable_sdk.dart';
void main() {
  test('Event bus publishes and closes', () async {
    final bus=EbolaEventBus(); final types=<EbolaEventType>[];
    final subscription=bus.stream.listen((e)=>types.add(e.type));
    bus.emit(EbolaSdkEvent(EbolaEventType.connected,deviceId:'D1'));
    expect(types,[EbolaEventType.connected]);
    await subscription.cancel(); await bus.dispose();
  });
}
