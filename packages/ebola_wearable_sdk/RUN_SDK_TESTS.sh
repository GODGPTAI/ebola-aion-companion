#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
echo '=== EBOLA SDK FILE AUDIT ==='
python3 tools/static_audit.py
if command -v dart >/dev/null 2>&1; then
  echo '=== DART PUB GET ==='
  dart pub get
  echo '=== DART ANALYZE ==='
  dart analyze --fatal-infos=false --fatal-warnings=false
  echo '=== DART TEST ==='
  dart test --reporter expanded
  echo '=== MOCK DEMO ==='
  dart run example/bin/demo.dart
else
  echo 'DART_NOT_INSTALLED: compilation, tests and executable demo SKIPPED'
  echo 'Use included GitHub Actions workflow on a Dart-enabled runner.'
fi
