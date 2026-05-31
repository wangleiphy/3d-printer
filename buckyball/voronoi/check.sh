#!/usr/bin/env bash
cd "$(dirname "$0")"
root="$PWD"; while [ "$root" != "/" ] && [ ! -d "$root/tools" ]; do root="$(dirname "$root")"; done
/opt/anaconda3/bin/python "$root/tools/preflight.py" buckyball
echo; echo "→ Read PRINT_NOTES.md in this folder for the slicer settings."
