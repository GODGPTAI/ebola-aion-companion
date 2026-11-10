import 'package:test/test.dart';
import 'package:ebola_wearable_sdk/ebola_wearable_sdk.dart';
void main(){
 test('Voice parser maps primary intents',(){
   final parser=EbolaVoiceIntentParser();
   expect(parser.parse('Please read this label'),EbolaVoiceIntent.readText);
   expect(parser.parse('Take a picture'),EbolaVoiceIntent.capturePhoto);
   expect(parser.parse('Stop recording'),EbolaVoiceIntent.stopVideo);
 });
}
