# Proposed authenticated API contract — not yet deployed

POST /api/wearables/licence/activate
POST /api/wearables/licence/validate
POST /api/wearables/licence/deactivate
POST /api/wearables/licence/replace

Bodies contain `device_id`, `model_code`, optional device attestation, and for replace an approved warranty case ID plus old and new device bindings.

Response schema: `{ "allowed": true|false, "state": "active|revoked|...", "licence_id": "...", "reason": "...", "valid_until": "..." }`.

Server obligations: authenticated user, authorization, rate limiting, transaction + unique active hardware binding, cryptographic device proof where available, immutable audit log, warranty approval validation, expiry control, replay protection, and safe revocation. Do not trust client-supplied model/serial by itself. Endpoint paths in the SDK are proposals, not existing routes.
