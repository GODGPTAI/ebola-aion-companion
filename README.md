# EBOLA AION Android Companion App (v0.1.0)

**Publisher:** GODGPTAI GREENS INNOVATION AND AI TECHNOLOGIES PRIVATE LIMITED.

First Flutter UI + safe mock-device companion app for **EBOLA G1, G2, G3, G4**. This package includes the existing **EBOLA Wearable SDK v0.3.1** as a local Dart path dependency, not a rewritten SDK.

## Current functional scope
- Red/white mobile UI; EBOLA logo and model imagery for G3/G4.
- Model cards for G1–G4 with clear hardware-validation status.
- Real SDK `EbolaMockAdapter` scan/connect/disconnect and simulated battery display.
- Official website links to existing `/login.php`, `/dashboard.php`, `/krishna.php`, `/developerebolaaiindex.php`, `/videoaiworkforce.php`.
- No duplicate signup, no hardcoded token, no local Vault storage.
- GitHub Actions Android **debug APK** build and widget tests.

## Not implemented / not claimed
No real Bluetooth device discovery, firmware matching, on-glasses photo/video capture, 120-language translation, background navigation, secure app authentication bridge, hardware attestation, or production licence activation. These require physical hardware and tested vendor SDK/protocol access. No accessibility navigation feature is safe for road crossing.

## Build locally

Requires Flutter stable, Android SDK and Java. This repository intentionally omits generated Android runner files and generates them once using Flutter CLI.

```bash
flutter create --platforms=android --project-name ebola_aion_companion --org com.godgptai .
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Find `build/app/outputs/flutter-apk/app-debug.apk` locally. In GitHub, Actions > latest successful **EBOLA AION Android APK** run > Artifacts > **EBOLA-AION-Companion-Android-Debug-APK**. Debug APK is for internal development, not Play Store distribution.

## Existing backend
The production server has `/relay/wearables/licence/{activate,validate,deactivate,replace}` backed by a tested PHP/MySQL service. This app **does not automatically reuse a browser's login session as a Bearer licence token**. A dedicated authorized sign-in/token exchange and secure device identity must be implemented and independently tested before enabling licence buttons. Never put admin tokens or production secrets in a mobile bundle.

## GitHub repository recommendation
Keep `GODGPTAI/ebola-wearable-sdk` as SDK source repository. Create a separate **private** `GODGPTAI/ebola-aion-companion` repository for this Flutter app. Do not overwrite the existing SDK repo. The bundled path dependency can later be changed to an authenticated private Git dependency when release workflows are established.

## Credits and rights
Product images are project assets; verify commercial rights before public release. Any later third-party SDK integration requires compliance with applicable licensing and attribution terms. Manufacturer-specific source or confidential credentials must not enter public repositories.
