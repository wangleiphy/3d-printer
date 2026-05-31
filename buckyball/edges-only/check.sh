#!/usr/bin/env bash
# Pre-print safety check for this buckyball variant. Run before slicing/printing.
#   ./check.sh
cd "$(dirname "$0")"
root="$PWD"
while [ "$root" != "/" ] && [ ! -d "$root/tools" ]; do root="$(dirname "$root")"; done
/opt/anaconda3/bin/python "$root/tools/preflight.py" buckyball
echo
echo "→ Read PRINT_NOTES.md in this folder for the slicer settings."
