#!/usr/bin/env bash
# Pre-print safety check for 龙凤斧 (Dragon-and-Phoenix Axe). Run before slicing.
#   ./check.sh
cd "$(dirname "$0")"
fail=0
for p in head handle; do
  echo "==================== $p ===================="
  /opt/anaconda3/bin/python ../tools/preflight.py dragon_phoenix_axe_$p || fail=1
  echo
done
echo "→ Now read PRINT_NOTES.md in this folder for the slicer settings."
exit $fail
