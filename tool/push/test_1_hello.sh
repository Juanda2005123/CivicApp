#!/usr/bin/env bash
# Test 1 (HU-24): a plain push reaches the phone. Try it with the app open, in
# the background and closed. Usage: tool/push/test_1_hello.sh [user]  (default ana)
cd "$(dirname "$0")/../.." && node tool/push/send_push.mjs "${1:-ana}" \
  "Prueba de VIGÍA" "Si ves esto, las notificaciones push funcionan."
