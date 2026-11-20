#!/usr/bin/env bash
# EBOLA AION internal CI: retry ONLY transient Maven/Gradle download failures.
set -Eeuo pipefail
if [[ $# -ne 2 ]]; then
  echo 'Usage: ebola_gradle_retry.sh <flutter-target-dart> <output-apk-name>' >&2
  exit 64
fi
TARGET="$1"
OUTPUT="$2"
case "$TARGET" in
  lib/ebola_aion_red_white_app.dart|lib/ebola_aion_camera_probe_main.dart) ;;
  *) echo "Unexpected build target: $TARGET" >&2; exit 64 ;;
esac
case "$OUTPUT" in
  ebola-aion-neon-debug.apk|ebola-aion-camera-probe-debug.apk) ;;
  *) echo "Unexpected artifact: $OUTPUT" >&2; exit 64 ;;
esac
mkdir -p build/ebola-ci-logs build/app/outputs/flutter-apk
for attempt in 1 2 3 4; do
  log="build/ebola-ci-logs/${OUTPUT%.apk}-attempt-${attempt}.log"
  echo "=== Build $TARGET attempt $attempt/4 ==="
  if flutter build apk --debug --target "$TARGET" 2>&1 | tee "$log"; then
    apk='build/app/outputs/flutter-apk/app-debug.apk'
    if [[ ! -s "$apk" ]]; then
      echo "Flutter reported success but $apk missing/empty" >&2
      exit 70
    fi
    cp "$apk" "build/app/outputs/flutter-apk/$OUTPUT"
    echo "BUILD PASS: $OUTPUT (compiler only; NOT physical glass connection)"
    exit 0
  fi
  if ! grep -Eiq '(429|Too Many Requests|Read timed out|Connection reset|Temporary failure in name resolution|503 Service Unavailable|502 Bad Gateway)' "$log"; then
    echo "Non-network build failure: inspect $log; no retry to mask source errors" >&2
    exit 1
  fi
  if [[ "$attempt" -eq 4 ]]; then
    echo "Transient Maven/Gradle network failure persisted after four attempts" >&2
    exit 1
  fi
  case "$attempt" in 1) backoff=45 ;; 2) backoff=120 ;; 3) backoff=240 ;; esac
  echo "Transient dependency download error; waiting ${backoff}s before next attempt."
  sleep "$backoff"
done
