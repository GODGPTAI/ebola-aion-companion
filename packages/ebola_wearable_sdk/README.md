# EBOLA AION Wearable SDK — v0.3.1

Original Dart package for EBOLA G1/G2/G3/G4. Intended to be used by one EBOLA Android/Flutter companion application. Product brand and user interfaces use EBOLA branding. Existing `/login.php`, `/signup.php`, `/index.php`, `/dashboard.php`, `/krishna.php`, `ONE QR` and encrypted `/relay/secure/secure_storage.php` stay authoritative.

## What exists
- Common model catalog, capability contracts and adapter registry.
- Mock device; event bus, connection session and safe error model.
- G1 and G2/G3/G4 read-only adapter ports with injectable platform implementations.
- Device-bound licence gate, authenticated HTTPS request gateway (requires corresponding server routes), test-only replacement simulation.
- Permission, voice, KRISHNA, memory and secure Vault ports; checksum/receipt-dependent media transfer.
- Tests and example source.

## What does not exist yet
- Actual firmware-specific Android BLE transport or media commands for any model.
- Completed licence server, device attestation or hardware anti-cloning support.
- Live KRISHNA/Vault API bindings, signed APK, published GitHub or pub.dev package.

## Run
```sh
dart pub get
dart analyze
dart test
dart run example/bin/demo.dart
```

**Do not ship `EbolaTestOnlyLicenceGateway` in production.** Real-device feature tests are required when hardware arrives. See `docs/INTEGRATION.md`, `docs/SECURITY.md`.

## Shell / CI checks

Run `bash RUN_SDK_TESTS.sh`. Without Dart installed, it checks file manifests, local imports and JSON only. To compile and execute tests, push this package as a GitHub repository containing `.github/workflows/dart-sdk-ci.yml`. The CI workflow resolves dependencies, analyzes, tests, and runs the mock example. A passing CI run never proves actual BLE/camera hardware.

### Security hardening in 0.3.1

- Prevent cross-model licence use in the SDK facade and verify capture device identity.
- Mock device no longer advertises unimplemented media capabilities.
- Restrict HTTPS licence gateway origins and preserve configured base paths.
- Added tests for user consent, model mismatch, and licence transport.

Server-side licence APIs and hardware adapters still need implementation. No user system was modified.
