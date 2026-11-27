#!/usr/bin/env bash
# Test 3 (HU-24, criteria 2 and 3): the "new comment" push; tapping it opens
# #VIG-S013. Usage: tool/push/test_3_comment.sh [user]  (default ana, its author)
cd "$(dirname "$0")/../.." && node tool/push/send_push.mjs "${1:-ana}" \
  "Nuevo comentario" \
  "Nuevo comentario en el reporte #VIG-S013: Luis Herrera aportó a la discusión." "#VIG-S013"
