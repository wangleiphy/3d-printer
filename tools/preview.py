#!/usr/bin/env python3
"""Render a multi-angle preview PNG of any STL (ASCII or binary), auto-bounded.

  python ../tools/preview.py <model.stl> [out.png]

Default output is <model>_preview.png next to the STL. Grey shading reads well for
any filament colour. Works for any centered object (cube, buckyball, ...).
"""
import struct, sys, os
import numpy as np
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d.art3d import Poly3DCollection

if len(sys.argv) < 2:
    sys.exit("usage: preview.py <model.stl> [out.png]")
fn  = sys.argv[1]
out = sys.argv[2] if len(sys.argv) > 2 else os.path.splitext(fn)[0] + "_preview.png"
raw = open(fn, "rb").read()
is_ascii = raw[:5] == b"solid" and b"facet" in raw[:2000]

tris = []
if is_ascii:
    cur = []
    for line in raw.decode("utf-8", "replace").splitlines():
        s = line.split()
        if len(s) == 4 and s[0] == "vertex":
            cur.append(tuple(map(float, s[1:])))
            if len(cur) == 3:
                tris.append(cur); cur = []
    tris = np.array(tris, np.float32)
else:
    n = struct.unpack("<I", raw[80:84])[0]
    off = 84
    tris = np.empty((n, 3, 3), np.float32)
    for i in range(n):
        off += 12
        for v in range(3):
            tris[i, v] = struct.unpack_from("<3f", raw, off); off += 12
        off += 2
print("triangles:", len(tris))

lo = tris.reshape(-1, 3).min(0); hi = tris.reshape(-1, 3).max(0)
ctr = (lo + hi) / 2; rad = (hi - lo).max() / 2 * 1.05

def shade(tris, light=np.array([0.3, 0.4, 0.85])):
    nrm = np.cross(tris[:, 1] - tris[:, 0], tris[:, 2] - tris[:, 0])
    nrm /= (np.linalg.norm(nrm, axis=1, keepdims=True) + 1e-9)
    b = 0.22 + 0.78 * np.clip(nrm @ (light / np.linalg.norm(light)), 0, 1)
    g = 0.20 + 0.55 * b
    return np.stack([g, g, g, np.ones_like(g)], 1)

fc = shade(tris)
views = [(18, -55, "iso"), (0, 0, "front"), (90, -90, "top"), (18, 35, "iso · turned")]
fig = plt.figure(figsize=(13, 3.4), facecolor="white")
for idx, (el, az, name) in enumerate(views, 1):
    ax = fig.add_subplot(1, 4, idx, projection="3d")
    ax.add_collection3d(Poly3DCollection(tris, facecolors=fc,
                                         edgecolor="none", antialiased=True))
    for axis, c in zip("xyz", ctr):
        getattr(ax, f"set_{axis}lim")(c - rad, c + rad)
    ax.set_box_aspect((1, 1, 1)); ax.view_init(elev=el, azim=az)
    ax.set_title(name, fontsize=10); ax.set_axis_off()
plt.tight_layout()
plt.savefig(out, dpi=120, bbox_inches="tight")
print("wrote", out)
