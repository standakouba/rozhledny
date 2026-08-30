#!/usr/bin/env bash
# Overpass instance bezne vypadavaji. Zkousime dokola, dokud nedojedou data.
export PATH="$PATH:/c/src/flutter/bin"
cd /d/projects/rozhledny || exit 1
for i in $(seq 1 12); do
  echo "=== pokus $i ($(date +%H:%M:%S)) ==="
  if dart run tools/fetch_osm.dart 2>&1; then
    echo "=== USPECH v pokusu $i ==="
    exit 0
  fi
  echo "--- neuspech, cekam 180s ---"
  sleep 180
done
echo "=== VZDAVAM SE po 12 pokusech ==="
exit 1
