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
echo "==================== head print orientation ===================="
/opt/anaconda3/bin/python ../tools/check_3mf_orientation.py \
  dragon_phoenix_axe_head_handle_print.3mf \
  --label "combined head" \
  --object-id 1 \
  --max-y 30 \
  --min-z 95 || fail=1
echo
echo "==================== handle print orientation ===================="
/opt/anaconda3/bin/python ../tools/check_3mf_orientation.py \
  dragon_phoenix_axe_head_handle_print.3mf \
  --label "combined handle" \
  --object-id 2 \
  --max-x 30 \
  --max-y 30 \
  --min-z 240 \
  --max-z 250 || fail=1
echo
echo "→ Now read PRINT_NOTES.md in this folder for the slicer settings."
exit $fail
