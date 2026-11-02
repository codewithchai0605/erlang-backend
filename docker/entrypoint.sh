#!/bin/sh
# Container entrypoint. Keeps the Erlang VM as the process that receives SIGTERM (via exec) so that
# `docker stop` / Render deploys trigger the application's graceful shutdown (close sockets with 1001,
# record last-seen times) instead of a hard kill.
set -eu

# Erlang's distribution protocol needs a cookie even though we never cluster nodes (and bind distribution
# to loopback). Generate a random one when the operator did not provide CHAT_NODE_COOKIE.
if [ -z "${CHAT_NODE_COOKIE:-}" ]; then
  CHAT_NODE_COOKIE="$(head -c 24 /dev/urandom | base64 | tr -dc 'A-Za-z0-9')"
  export CHAT_NODE_COOKIE
fi

exec /app/bin/chat foreground
