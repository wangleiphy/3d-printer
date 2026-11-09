#!/usr/bin/env bash
set -eu
cd "$(dirname "$0")"
python3 ../tools/verify_3mf.py YE660D-fit-v1.3mf YE660D-fit-v1.stl
