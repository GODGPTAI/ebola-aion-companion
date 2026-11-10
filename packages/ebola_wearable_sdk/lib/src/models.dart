import 'device_contract.dart';

/// Product names and preliminary capabilities come from VOTO's 2025 brochure.
/// None of these profiles is a verified hardware-compatibility report.
enum EbolaGlassModel { g1, g2, g3, g4SportPro }

class EbolaModelProfile {
  final EbolaGlassModel model;
  final String name;
  final String candidateAdapterId;
  final String sourceSku;
  final Set<EbolaCapability> candidateCapabilities;
  final bool hardwareVerified;
  final String note;
  const EbolaModelProfile({required this.model, required this.name,
    required this.candidateAdapterId, required this.sourceSku,
    required this.candidateCapabilities, this.hardwareVerified = false,
    required this.note});
}

class EbolaModelCatalog {
  static const eyevue = 'ebola.eyevue.candidate.v1';
  static const daEcho = 'ebola.da_echo.candidate.v1';
  static const profiles = <EbolaGlassModel, EbolaModelProfile>{
    EbolaGlassModel.g1: EbolaModelProfile(
      model:EbolaGlassModel.g1,name:'EBOLA G1 Everyday',sourceSku:'VOTO-AI-G1',
      candidateAdapterId:eyevue,
      candidateCapabilities:{EbolaCapability.battery,EbolaCapability.photo,EbolaCapability.video,EbolaCapability.microphone,EbolaCapability.audioOutput,EbolaCapability.mediaTransfer},
      note:'EYEVUE / Hey Star. E09 protocol match not established.'),
    EbolaGlassModel.g2: EbolaModelProfile(
      model:EbolaGlassModel.g2,name:'EBOLA G2 Vision',sourceSku:'VOTO-AI-GEN2',
      candidateAdapterId:daEcho,
      candidateCapabilities:{EbolaCapability.battery,EbolaCapability.photo,EbolaCapability.video,EbolaCapability.microphone,EbolaCapability.audioOutput,EbolaCapability.mediaTransfer,EbolaCapability.wifiTransfer},
      note:'Da Echo; MoYoung SDK and firmware compatibility unverified.'),
    EbolaGlassModel.g3: EbolaModelProfile(
      model:EbolaGlassModel.g3,name:'EBOLA G3 Super Charge',sourceSku:'VOTO-AI-SUPERCHARGE3',
      candidateAdapterId:daEcho,
      candidateCapabilities:{EbolaCapability.battery,EbolaCapability.photo,EbolaCapability.video,EbolaCapability.microphone,EbolaCapability.audioOutput,EbolaCapability.mediaTransfer,EbolaCapability.wifiTransfer},
      note:'Da Echo; G3 video format and SDK compatibility unverified.'),
    EbolaGlassModel.g4SportPro: EbolaModelProfile(
      model:EbolaGlassModel.g4SportPro,name:'EBOLA G4 Sport Pro',sourceSku:'VOTO-AI-SPORTPRO',
      candidateAdapterId:daEcho,
      candidateCapabilities:{EbolaCapability.battery,EbolaCapability.photo,EbolaCapability.video,EbolaCapability.microphone,EbolaCapability.audioOutput,EbolaCapability.mediaTransfer,EbolaCapability.wifiTransfer},
      note:'Da Echo, IP67 brochure claim; SDK/firmware not tested.'),
  };
  static EbolaModelProfile byModel(EbolaGlassModel m) => profiles[m]!;
}
