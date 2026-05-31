#!/usr/bin/env python3
"""Verify a 3MF is correct: OPC structure, XML schema, mesh integrity,
and round-trip equivalence against the source STL."""
import sys, zipfile, struct, collections
import xml.etree.ElementTree as ET

mf = sys.argv[1] if len(sys.argv) > 1 else "xyz_calibration_cube.3mf"
stl = sys.argv[2] if len(sys.argv) > 2 else "xyz_calibration_cube.stl"
NS = "{http://schemas.microsoft.com/3dmanufacturing/core/2015/02}"
ok = True
def check(name, cond, detail=""):
    global ok
    ok = ok and cond
    print(f"  [{'PASS' if cond else 'FAIL'}] {name}{(' — ' + detail) if detail else ''}")

# ---- 1. OPC package structure ----
print("== OPC package ==")
z = zipfile.ZipFile(mf)
names = z.namelist()
check("[Content_Types].xml present", "[Content_Types].xml" in names)
check("_rels/.rels present", "_rels/.rels" in names)
check("3D/3dmodel.model present", "3D/3dmodel.model" in names)
check("zip CRC integrity", z.testzip() is None)

# content-types declares the model type
ct = z.read("[Content_Types].xml").decode()
check("content-types declares 3dmodel", "3dmanufacturing-3dmodel+xml" in ct)
# rels points at the model
rl = z.read("_rels/.rels").decode()
check("relationship targets /3D/3dmodel.model", "/3D/3dmodel.model" in rl)

# ---- 2. XML well-formed + schema essentials ----
# Handles both the simple inline form (our stl_to_3mf.py) and the 3MF *production
# extension* used by Bambu Studio project files, where the build item points at an
# object whose <mesh> lives in a referenced sub-model file via <component p:path=...>.
print("== model XML ==")
PNS = "{http://schemas.microsoft.com/3dmanufacturing/production/2015/06}"

def objects_in(model):
    return {o.get("id"): o for o in model.findall(f"{NS}resources/{NS}object")}

def resolve_mesh(model, objid, depth=0):
    """Return the <mesh> for objid, following production-extension components into
    sub-model files (.model) inside the same zip. None if not resolvable."""
    if depth > 8:
        return None
    o = objects_in(model).get(objid)
    if o is None:
        return None
    m = o.find(f"{NS}mesh")
    if m is not None:
        return m
    comp = o.find(f"{NS}components/{NS}component")
    if comp is not None:
        path = comp.get(f"{PNS}path") or comp.get("path")
        cid = comp.get("objectid")
        if path and path.lstrip("/") in z.namelist():
            return resolve_mesh(ET.fromstring(z.read(path.lstrip("/"))), cid, depth + 1)
        return resolve_mesh(model, cid, depth + 1)   # same-file component
    return None

root = ET.fromstring(z.read("3D/3dmodel.model"))
check("root is <model>", root.tag == NS + "model")
check('unit="millimeter"', root.get("unit") == "millimeter")
build = root.find(f"{NS}build/{NS}item")
check("build/item exists", build is not None)
build_id = build.get("objectid") if build is not None else None
check("build references an existing object", objects_in(root).get(build_id) is not None,
      f"objectid={build_id}")
mesh = resolve_mesh(root, build_id) if build_id else None
check("object/mesh exists (inline or via production sub-model)", mesh is not None)

# ---- 3. mesh integrity ----
print("== mesh integrity ==")
vlist = mesh.find(f"{NS}vertices").findall(f"{NS}vertex")
tlist = mesh.find(f"{NS}triangles").findall(f"{NS}triangle")
V = [(float(v.get("x")), float(v.get("y")), float(v.get("z"))) for v in vlist]
T = [(int(t.get("v1")), int(t.get("v2")), int(t.get("v3"))) for t in tlist]
nv, nt = len(V), len(T)
print(f"  vertices={nv}  triangles={nt}")
check("all triangle indices in range", all(0 <= i < nv for t in T for i in t))
check("no degenerate triangles (3 distinct verts)", all(len(set(t)) == 3 for t in T))
used = {i for t in T for i in t}
check("no orphan vertices", len(used) == nv, f"{nv-len(used)} unused")

# watertight + winding via half-edges
edges = collections.Counter()
directed = collections.Counter()
for a, b, c in T:
    for x, y in ((a, b), (b, c), (c, a)):
        edges[frozenset((x, y))] += 1
        directed[(x, y)] += 1
nonmanifold = sum(1 for e, c in edges.items() if c != 2)
check("watertight (every edge shared by exactly 2 faces)", nonmanifold == 0, f"{nonmanifold} bad edges")
# consistent winding: each directed edge appears once, its reverse once
bad_wind = sum(1 for (x, y), c in directed.items() if c != 1 or directed.get((y, x), 0) != 1)
check("consistent winding (each directed edge unique + paired)", bad_wind == 0, f"{bad_wind} issues")

def bbox(pts):
    mn = [min(p[i] for p in pts) for i in range(3)]
    mx = [max(p[i] for p in pts) for i in range(3)]
    return [round(mx[i]-mn[i], 4) for i in range(3)]
def volume(verts, tris):
    s = 0.0
    for a, b, c in tris:
        (x1,y1,z1),(x2,y2,z2),(x3,y3,z3) = verts[a], verts[b], verts[c]
        s += (x1*(y2*z3-y3*z2) - x2*(y1*z3-y3*z1) + x3*(y1*z2-y2*z1))/6.0
    return abs(s)
bb = bbox(V); vol = volume(V, T)
print(f"  bounding box = {bb[0]}×{bb[1]}×{bb[2]} mm")
check("bounding box non-degenerate", all(d > 0 for d in bb), str(bb))
print(f"  signed volume = {vol:.3f} mm³")
check("volume positive", vol > 0, f"{vol:.1f}")

# ---- 4. round-trip vs source STL ----
print("== round-trip vs STL ==")
raw = open(stl, "rb").read()
sV, sT = [], []
if raw[:5] == b"solid" and b"facet" in raw[:2000]:
    idx = {}; cur = []
    def vid(p):
        k = tuple(round(x,5) for x in p)
        if k not in idx: idx[k] = len(sV); sV.append(k)
        return idx[k]
    for line in raw.decode("utf-8","replace").splitlines():
        s = line.split()
        if len(s)==4 and s[0]=="vertex":
            cur.append(tuple(map(float,s[1:])))
            if len(cur)==3: sT.append(tuple(vid(p) for p in cur)); cur=[]
svol = volume(sV, sT); sbb = bbox(sV)
check("triangle count matches STL", nt == len(sT), f"3mf={nt} stl={len(sT)}")
check("bbox matches STL", bb == sbb, f"3mf={bb} stl={sbb}")
check("volume matches STL (<0.01 mm³)", abs(vol - svol) < 0.01, f"Δ={abs(vol-svol):.6f}")

print("\n" + ("✅ 3MF IS VALID — all checks passed" if ok else "❌ 3MF HAS PROBLEMS — see FAIL lines"))
sys.exit(0 if ok else 1)
