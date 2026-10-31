# Security

## Implemented

- **Passwords**: bcrypt via the `bcrypt` library (no custom hashing). Length 8-72 bytes (bcrypt ignores bytes past 72, so longer input is rejected, not truncated). Login for unknown users burns equal CPU (`dummy_verify`) and returns the same generic error.
- **Tokens**: opaque 256-bit random access and refresh tokens; only SHA-256 hashes are stored. Access TTL default 15 min, refresh 30 days. **Refresh rotation with reuse detection**: presenting an already-rotated refresh token revokes the whole session and closes its live sockets. Logout and logout-all revoke server-side and close live sockets immediately.
- **Client storage**: tokens live only in the platform secure store (flutter_secure_storage), never in the cache database or logs.
- **Authorization**: every conversation operation checks membership (`chat_conversations:require_member/2`); non-members get PERMISSION_DENIED.
- **Input validation**: usernames, display names, UUIDs, client message ids, text (UTF-8, no NUL, bounded) validated after decoding; JSON bodies limited to 16 KB; WebSocket frames limited by config.
- **SQL injection**: every query is parameterised; no SQL is built from input.
- **Rate limits**: per-IP on register/login/refresh/hello, per-user on user lookup and sends (fixed windows in ETS). Limits are config values.
- **Origins**: browser origins must be listed in `CHAT_ALLOWED_ORIGINS` for CORS and WebSocket; native apps send no Origin.
- **Logging**: structured events; never passwords, tokens, or message text. Database errors log only the SQLSTATE.
- **Exposure**: `/metrics` answers only to loopback peers; the Erlang distribution port is bound to 127.0.0.1; DB credentials come from the environment.

## Known limitations (be honest about these before deploying)

1. **No TLS in the app.** Terminate TLS at a reverse proxy (Caddy/nginx) and keep the backend on loopback. Without TLS, tokens and messages cross the network in clear text. Client dev builds use `http://`/`ws://`; production builds must use `https://`/`wss://`.
2. **Behind a proxy, client IP rate limiting sees the proxy's IP.** `X-Forwarded-For` is deliberately not trusted yet. Block `/metrics` at the proxy (it appears loopback through the proxy).
3. **No end-to-end encryption**: the server can read stored messages. No encryption at rest beyond what the database host provides.
4. **Established WebSockets outlive the 15-minute access token** (authentication happens at connect time); they are closed on logout/revocation, not on token expiry.
5. **Refresh retry after a lost response is treated as reuse** and signs the user out; a short grace window would be friendlier but weakens theft detection (documented trade-off).
6. **Username lookup and registration reveal whether a username exists.** Mitigated by rate limits only.
7. The PostgreSQL connection is unencrypted (assumes localhost or a private network); `epgsql` TLS options are not configured.
8. No account recovery, email verification, or device management UI yet.
9. Dependency versions are unpinned until the first resolve (see ADR 0002); audit them when locking.
