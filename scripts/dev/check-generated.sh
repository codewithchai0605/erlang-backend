#!/usr/bin/env bash
# CI check: committed Dart protocol code must match proto/chat/v1/chat.proto.
set -euo pipefail
cd "$(dirname "$0")/../.."
bash scripts/dev/gen-proto.sh
git diff --exit-code -- client/lib/core/protocol/gen || { echo "Generated code is stale: commit the regenerated files."; exit 1; }
