# Integration steps

1. Install Flutter/Dart locally and run `dart pub get`, `dart analyze`, `dart test`.
2. Reuse existing EBOLA user authentication. Never create another signup flow, user ID, sponsor link, or QR.
3. Implement `EbolaPermissionPort` via platform permissions.
4. Implement `EbolaG1BlePort` / `EbolaG234PluginPort` ONLY after firmware + legal compatibility verification.
5. Probe read-only capabilities first, verify device IDs and BLE addresses; do not attempt resets or OTA.
6. Implement a production server for licence binding, verified hardware attestation and replacement (the test gateway is unsafe for production).
7. Use `EbolaRemoteLicenceGateway` with short-lived per-user OAuth/session bearer token; HTTPS only.
8. Upload user media to existing `/relay/secure/secure_storage.php` service using an authenticated backend bridge, not a public file path.
9. Connect KRISHNA through existing `/relay/gptgpt6/ask_ai.php`, preserving user isolation.
10. Never advertise G1-G4 media commands as working until each physical model is tested.

No OEM source code, firmware dumps or decompiled APK assets are bundled. This is an original application interface with explicitly unimplemented firmware operations.
