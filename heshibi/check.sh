#!/usr/bin/env bash
# Pre-print safety check for the 和氏璧 (Héshìbì) jade disc. Run this before slicing/printing.
#   ./check.sh
cd "$(dirname "$0")"
/opt/anaconda3/bin/python ../tools/preflight.py heshibi
echo
echo "→ Now read PRINT_NOTES.md in this folder for the slicer settings."
