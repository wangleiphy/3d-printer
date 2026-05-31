#!/usr/bin/env python3
"""Pre-print safety check for a design. Run from inside its folder:

    python ../tools/preflight.py <name>

Does three things:
  1. MESH/PACKAGE — re-runs verify_3mf.py (watertight, winding, round-trip vs STL)
  2. SIZE & ADHESION — bounding-box dimensions and the first-layer footprint
     (area of the lowest flat face = what actually grips the plate)
  3. REMINDERS — operation + mesh safety to check before you hit print

Exit code is non-zero if the mesh/package verification fails — so check.sh can gate on it.
"""
import sys, os, subprocess, struct
import numpy as np

name = sys.argv[1] if len(sys.argv) > 1 else None
if not name:
    sys.exit("usage: preflight.py <name>   (expects <name>.3mf and <name>.stl in cwd)")

tools = os.path.dirname(os.path.abspath(__file__))
mf, stl = f"{name}.3mf", f"{name}.stl"
for f in (mf, stl):
    if not os.path.exists(f):
        sys.exit(f"missing {f} — run the render/3mf steps first (see PRINT_NOTES.md)")

# ---- 1. mesh / package verification (single source of truth) ----
print(f"── 1. mesh & package: {mf} ──")
res = subprocess.run([sys.executable, os.path.join(tools, "verify_3mf.py"), mf, stl],
                     capture_output=True, text=True)
mesh_ok = res.returncode == 0
for line in res.stdout.splitlines():
    if any(k in line for k in ("FAIL", "watertight", "winding", "VALID", "PROBLEMS")):
        print("   " + line.strip())
print(f"   => {'PASS — mesh is watertight & valid' if mesh_ok else 'FAIL — do NOT print; see above'}")

# ---- 2. size & first-layer footprint, straight from the STL ----
raw = open(stl, "rb").read()
cur, T = [], []
if raw[:5] == b"solid" and b"facet" in raw[:2000]:
    for ln in raw.decode("utf-8", "replace").splitlines():
        s = ln.split()
        if len(s) == 4 and s[0] == "vertex":
            cur.append(tuple(map(float, s[1:])))
            if len(cur) == 3:
                T.append(cur); cur = []
    T = np.array(T, np.float32)
else:
    n = struct.unpack("<I", raw[80:84])[0]; off = 84
    T = np.empty((n, 3, 3), np.float32)
    for i in range(n):
        off += 12
        for v in range(3):
            T[i, v] = struct.unpack_from("<3f", raw, off); off += 12
        off += 2

lo, hi = T.reshape(-1, 3).min(0), T.reshape(-1, 3).max(0)
size = hi - lo
z = T[:, :, 2]
zmin = z.min()
on_bottom = (np.abs(z - zmin) < 0.05).all(1)          # triangles on the lowest face
nrm = np.cross(T[:, 1] - T[:, 0], T[:, 2] - T[:, 0])
area = 0.5 * np.linalg.norm(nrm, axis=1)
foot = area[on_bottom].sum()
print("\n── 2. size & bed adhesion ──")
print(f"   bounding box : {size[0]:.1f} × {size[1]:.1f} × {size[2]:.1f} mm")
print(f"   footprint    : {foot:.0f} mm² on the bottom face")
print("   " + ("=> tiny footprint — add a brim or a flat base, or it may not stick"
               if foot < 80 else "=> solid footprint for the first layer"))

# ---- 3. safety reminders ----
print("\n── 3. before you print (read PRINT_NOTES.md for this design's settings) ──")
for r in [
    "OPERATION  ⚠ ventilate the room — molten plastic emits fumes (esp. ABS/ASA; PLA milder)",
    "OPERATION  ⚠ nozzle ~200 °C and bed ~60 °C are HOT — don't touch during/after a print",
    "OPERATION  ⚠ never leave the printer running unattended — fire risk",
    "OPERATION  ⚠ watch the FIRST LAYER go down — 90% of failures show up there; cancel & re-level if it won't stick",
    "MESH       ✓ mesh verified watertight above (slicer won't mis-fill)",
    "MESH       ✓ confirm the bounding box above matches the size you intend",
    "MESH       ✓ confirm the footprint is enough to hold (or that a brim is enabled)",
]:
    print("   " + r)

sys.exit(0 if mesh_ok else 1)
