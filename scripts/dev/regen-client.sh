#!/usr/bin/env bash
# One command for everything generated on the Flutter side. Run from anywhere, in Git Bash on Windows.
# Needed after: pulling changes to proto/chat/v1/chat.proto or client/lib/core/db/app_database.dart.
set -euo pipefail
cd "$(dirname "$0")/../../client"
flutter pub get
bash ../scripts/dev/gen-proto.sh                                   # Dart protobuf code from the .proto
dart run build_runner build --delete-conflicting-outputs           # Drift database code
echo "Generated. Next: flutter analyze && flutter test"
