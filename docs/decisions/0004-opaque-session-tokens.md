# 0004 - Opaque, server-side-validated tokens instead of JWT
Status: accepted
Context: AGENT.md allows JWT or a carefully documented opaque design. JWT needs a signing library and makes revocation hard.
Decision: access and refresh tokens are 256-bit random strings; only SHA-256 hashes are stored in `sessions`. Access tokens are validated by one indexed lookup per HTTP request and per WebSocket Hello. Refresh tokens rotate; reuse of a rotated token revokes the session.
Consequences: instant revocation, no custom crypto, no signing-key management. Cost: a database lookup per authentication (acceptable now; an ETS cache with short TTL is a later optimisation). Established WebSockets are not re-validated until reconnect (documented limitation).
