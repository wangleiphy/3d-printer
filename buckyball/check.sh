#!/usr/bin/env bash
# Pre-print safety check for the buckyball. Run this before slicing/printing.
#   ./check.sh
cd "$(dirname "$0")"
/opt/anaconda3/bin/python ../tools/preflight.py buckyball
echo
echo "→ Now read PRINT_NOTES.md in this folder for the slicer settings."
