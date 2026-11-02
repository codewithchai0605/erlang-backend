# syntax=docker/dockerfile:1.7
#
# Production image for the Erlang/OTP chat backend. Works the same on Docker Desktop (Windows), docker compose
# and Render (https://render.com). Build context = the REPOSITORY ROOT (the backend needs ../proto):
#
#     docker build -t chat-backend .
#     docker run --rm -p 8080:8080 -e CHAT_DATABASE_URL=postgres://user:pass@host/db chat-backend
#
# Two stages, same Debian base: a release bundles the Erlang runtime (ERTS) but still links the system's
# OpenSSL/ncurses dynamically, so build and runtime images must come from the same distribution release.
# Override the Erlang version with:  docker build --build-arg OTP_VERSION=28 .   (minimum supported: 27)
ARG OTP_VERSION=29

# --------------------------------------------------------------------------- build stage
# The official full image ships erlang, rebar3, gcc, make and git (bcrypt compiles a C NIF).
FROM erlang:${OTP_VERSION} AS build

# 1) Dependencies first: this layer is rebuilt only when rebar.config / rebar.lock change, so day-to-day
#    code edits do not re-download and re-compile every dependency.
WORKDIR /src/backend
COPY backend/rebar.config backend/rebar.lock ./
RUN rebar3 get-deps

# 2) Sources. proto/ sits NEXT to backend/ because rebar.config refers to it as ../proto.
WORKDIR /src
COPY proto proto
COPY backend backend

# 3) Compile (generates the Protobuf module with gpb), then assemble the self-contained release.
WORKDIR /src/backend
RUN rebar3 as prod release

# --------------------------------------------------------------------------- runtime stage
FROM erlang:${OTP_VERSION}-slim AS runtime

# ca-certificates: CHAT_DB_SSL=verify validates the database certificate against the OS trust store.
# curl: HEALTHCHECK. tini: a tiny init so zombie processes are reaped and signals are forwarded.
# (Package versions are intentionally not pinned: Debian removes old versions from its mirrors.)
# hadolint ignore=DL3008
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl tini \
 && rm -rf /var/lib/apt/lists/* \
 && useradd --system --uid 10001 --no-create-home --shell /usr/sbin/nologin chat

COPY --from=build --chown=chat:chat /src/backend/_build/prod/rel/chat /app
COPY --chown=chat:chat docker/entrypoint.sh /app/entrypoint.sh
# Windows checkouts often have CRLF line endings; "/bin/sh^M: bad interpreter" would otherwise crash the container.
RUN sed -i 's/\r$//' /app/entrypoint.sh && chmod +x /app/entrypoint.sh

# CHAT_HTTP_BIND: inside a container the server must listen on all interfaces (the port is only reachable
#   from outside if you publish it). PORT is NOT set here: Render injects it, and the app falls back to 8080.
# ERL_EPMD_ADDRESS: Erlang's port-mapper daemon would listen on every interface by default; keep it on loopback.
# RELX_OUT_FILE_PATH: the start script writes the generated vm.args/sys.config here, so /app can stay read-only.
ENV CHAT_HTTP_BIND=0.0.0.0 \
    ERL_EPMD_ADDRESS=127.0.0.1 \
    RELX_OUT_FILE_PATH=/tmp \
    LANG=C.UTF-8

USER chat
WORKDIR /app
EXPOSE 10000

# Liveness only (the process is up and serving). /readyz additionally checks the database.
HEALTHCHECK --interval=15s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -fsS "http://127.0.0.1:${PORT:-10000}/healthz" || exit 1

ENTRYPOINT ["/usr/bin/tini", "--", "/app/entrypoint.sh"]
