#!/usr/bin/env bash
# Pre-print safety check for the XYZ calibration cube. Run this before slicing/printing.
#   ./check.sh
cd "$(dirname "$0")"
/opt/anaconda3/bin/python ../tools/preflight.py xyz_calibration_cube
echo
echo "→ Now read PRINT_NOTES.md in this folder for the slicer settings."
