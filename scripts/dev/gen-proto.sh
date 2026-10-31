
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

command -v protoc >/dev/null || {
    echo "protoc not found"
    exit 1
}

DART_PLUGIN="$(command -v protoc-gen-dart || true)"

if [[ -z "$DART_PLUGIN" ]]; then
    DART_PLUGIN="$(pwd)/scripts/dev/protoc-gen-dart"
    export PATH="$(dirname "$DART_PLUGIN"):$PATH"
fi

mkdir -p client/lib/core/protocol/gen

protoc \
    --plugin="protoc-gen-dart=$DART_PLUGIN" \
    -I proto/chat/v1 \
    --dart_out=client/lib/core/protocol/gen \
    proto/chat/v1/chat.proto

echo "Generated client/lib/core/protocol/gen"
