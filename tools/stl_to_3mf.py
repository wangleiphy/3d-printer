#!/usr/bin/env python3
"""Convert an STL (ASCII or binary) into a valid 3MF Core package for Bambu Studio."""
import struct, sys, zipfile, datetime, os

src = sys.argv[1] if len(sys.argv) > 1 else "xyz_calibration_cube.stl"
dst = sys.argv[2] if len(sys.argv) > 2 else "xyz_calibration_cube.3mf"
title = os.path.splitext(os.path.basename(dst))[0].replace("_", " ")

raw = open(src, "rb").read()
ascii_mode = raw[:5] == b"solid" and b"facet" in raw[:2000]

verts, tris = [], []
index = {}
def vid(p):
    k = (round(p[0], 5), round(p[1], 5), round(p[2], 5))
    if k not in index:
        index[k] = len(verts); verts.append(k)
    return index[k]

if ascii_mode:
    cur = []
    for line in raw.decode("utf-8", "replace").splitlines():
        s = line.split()
        if len(s) == 4 and s[0] == "vertex":
            cur.append(tuple(map(float, s[1:])))
            if len(cur) == 3:
                tris.append(tuple(vid(p) for p in cur)); cur = []
else:
    n = struct.unpack("<I", raw[80:84])[0]; off = 84
    for _ in range(n):
        off += 12
        tri = []
        for _ in range(3):
            tri.append(struct.unpack_from("<3f", raw, off)); off += 12
        off += 2
        tris.append(tuple(vid(p) for p in tri))

print(f"{src}: {len(verts)} vertices, {len(tris)} triangles")

vx = "\n".join(f'     <vertex x="{x:.5f}" y="{y:.5f}" z="{z:.5f}"/>' for (x, y, z) in verts)
tx = "\n".join(f'     <triangle v1="{a}" v2="{b}" v3="{c}"/>' for (a, b, c) in tris)

model = f'''<?xml version="1.0" encoding="UTF-8"?>
<model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02">
 <metadata name="Application">Claude + OpenSCAD</metadata>
 <metadata name="Title">{title}</metadata>
 <resources>
  <object id="1" type="model">
   <mesh>
    <vertices>
{vx}
    </vertices>
    <triangles>
{tx}
    </triangles>
   </mesh>
  </object>
 </resources>
 <build>
  <item objectid="1"/>
 </build>
</model>
'''

content_types = '''<?xml version="1.0" encoding="UTF-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
 <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
 <Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml"/>
</Types>
'''

rels = '''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
 <Relationship Target="/3D/3dmodel.model" Id="rel0" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>
</Relationships>
'''

with zipfile.ZipFile(dst, "w", zipfile.ZIP_DEFLATED) as z:
    z.writestr("[Content_Types].xml", content_types)
    z.writestr("_rels/.rels", rels)
    z.writestr("3D/3dmodel.model", model)

import os
print(f"wrote {dst}: {os.path.getsize(dst)} bytes")
