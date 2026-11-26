#!/usr/bin/env bash
# Test 2 (HU-24, criteria 1 and 3): the "report validated" push; tapping it opens
# #VIG-S001. Usage: tool/push/test_2_validated.sh [user]  (default ana, its author)
cd "$(dirname "$0")/../.." && node tool/push/send_push.mjs "${1:-ana}" \
  "¡Reporte validado por la comunidad!" \
  "Tu reporte #VIG-S001 alcanzó 10 apoyos (+500 XP)." "#VIG-S001"
