# EBOLA SDK security boundary

- No OEM credentials, public Vault storage, bundled keys or hardcoded user tokens.
- One device per licence: production server enforces it transactionally; mock licence gateway is **TEST ONLY**.
- Device serial or MAC alone is not secure attestation; cloning defenses depend on actual hardware capabilities.
- Camera/mic are permission and explicit-consent gated; hardware indicator and local policies need testing.
- Per-user data only in existing Secure Vault; no canonical file under public uploads.
- On warranty replacement revoke the old device first, preserve account/sponsor/Vault and transfer entitlement.
- Always validate actual licence and application subscription separately.
- Do not publish the decompiled application, reverse-engineered assets, OEM proprietary SDK, or secrets.
