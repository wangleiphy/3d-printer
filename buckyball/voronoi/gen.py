#!/usr/bin/env python3
"""Generate a delicate, icosahedrally-symmetric Voronoi shell on the truncated-
icosahedron (C60) form, and write a watertight buckyball.stl.

Voronoi seeds are one generic point replicated by the 60 rotations of the buckyball's
own symmetry group, so the web is symmetric AND aligned to the solid. Each spherical
Voronoi edge becomes a thin rounded strut projected onto the truncated-icosahedron
surface; the result is hollow, see-through, and fully symmetric.
"""
import sys, numpy as np, trimesh
from scipy.spatial import SphericalVoronoi
from scipy.spatial.transform import Rotation as Rot

phi = (1+5**.5)/2
DIAM    = float(sys.argv[1]) if len(sys.argv)>1 else 75.0   # outer diameter across vertices (mm)
sc      = DIAM/50.0          # scale relative to the original 50 mm design
R_OUT   = DIAM/2             # circumradius (mm)
STRUT_D = 1.6*sc            # strut diameter — scales with size (stays equally delicate)
NODE_D  = 2.2*sc            # node diameter
FLAT    = 1.5*sc            # mm flattened off the bottom for a base
FOOT_D  = 18.0              # small flat foot diameter (mm); 0 = none. Snip off after print.
FOOT_H  = 0.6              # foot thickness (mm) — a few layers
BRIM_D  = 45.0             # wide modeled-in brim diameter (mm); 0 = none. Plate adhesion.
BRIM_H  = 0.4              # brim thickness (mm) — ~2 layers; peels off like a slicer brim
SEED    = np.array([0.34, 0.13, 0.93])   # one generic seed (defines the cell pattern)

# ---- truncated icosahedron: 60 vertices + 32 face planes -------------------
base=[[0,1,3*phi],[1,2+phi,2*phi],[phi,2,2*phi+1]]
cyc=lambda v:[[v[0],v[1],v[2]],[v[2],v[0],v[1]],[v[1],v[2],v[0]]]
sgn=lambda v:[[a*v[0],b*v[1],c*v[2]] for a in(-1,1) for b in(-1,1) for c in(-1,1)]
raw=[p for b in base for c in cyc(b) for p in sgn(c)]
V=[]
for p in raw:
    if not any(np.linalg.norm(np.array(p)-q)<1e-6 for q in V): V.append(np.array(p,float))
V=np.array(V); V=V/np.linalg.norm(V[0])*R_OUT
ico=[]                                   # 12 pentagon normals (icosahedron verts)
for a in(-1,1):
    for b in(-1,1): ico+=[[0,a,b*phi],[a,b*phi,0],[b*phi,0,a]]
dod=[[a,b,c] for a in(-1,1) for b in(-1,1) for c in(-1,1)]          # 20 hexagon normals
for a in(-1,1):
    for b in(-1,1): dod+=[[0,a/phi,b*phi],[a/phi,b*phi,0],[b*phi,0,a/phi]]
ico=[np.array(d)/np.linalg.norm(d) for d in ico]
dod=[np.array(d)/np.linalg.norm(d) for d in dod]
fd_pent=max(V@ico[0]); fd_hex=max(V@dod[0])
faces=[(n,fd_pent) for n in ico]+[(n,fd_hex) for n in dod]
def surf_r(u):                           # distance to the polyhedron surface along u
    return min(fd/np.dot(u,n) for n,fd in faces if np.dot(u,n)>1e-6)

# ---- the 60 rotations of THIS polyhedron (closure of two generators) -------
def Rax(axis,deg): return Rot.from_rotvec(np.deg2rad(deg)*np.array(axis)/np.linalg.norm(axis)).as_matrix()
gens=[Rax([0,1,phi],72), Rax([1,1,1],120)]
G=[np.eye(3)]; frontier=[np.eye(3)]
while frontier:
    nf=[]
    for g in frontier:
        for h in gens:
            M=h@g
            if not any(np.allclose(M,X,atol=1e-6) for X in G): G.append(M); nf.append(M)
    frontier=nf
assert len(G)==60, f"group has {len(G)} elements"
# sanity: group preserves the vertex set
assert all(any(np.linalg.norm(M@V[0]-w)<1e-4 for w in V) for M in G)

# ---- symmetric Voronoi ------------------------------------------------------
s=SEED/np.linalg.norm(SEED)
pts=[]
for M in G:
    q=M@s
    if not any(np.linalg.norm(q-p)<1e-6 for p in pts): pts.append(q)
pts=np.array(pts)
sv=SphericalVoronoi(pts,radius=1.0,center=np.zeros(3)); sv.sort_vertices_of_regions()
# merge near-duplicate Voronoi vertices (symmetric seeds make some coincide)
merged=[]; idmap=[]
for v in sv.vertices:
    k=next((k for k,m in enumerate(merged) if np.linalg.norm(v-m)<2e-3), -1)
    if k<0: idmap.append(len(merged)); merged.append(v)
    else: idmap.append(k)
merged=np.array(merged)
edges=set()
for reg in sv.regions:
    for a in range(len(reg)):
        i,j=idmap[reg[a]], idmap[reg[(a+1)%len(reg)]]
        if i!=j: edges.add((min(i,j),max(i,j)))
P=np.array([u/np.linalg.norm(u)*surf_r(u/np.linalg.norm(u)) for u in merged])  # projected
edges=sorted(e for e in edges if np.linalg.norm(P[e[0]]-P[e[1]])>0.5)
print(f"cells={len(pts)}  voronoi_vertices={len(P)}  struts={len(edges)}")

# ---- seat a pentagon face down, build the mesh -----------------------------
Rseat=Rot.align_vectors([[0,0,-1]],[[0,1,phi]])[0].as_matrix()
P=P@Rseat.T
parts=[]
for i,j in edges:
    parts.append(trimesh.creation.cylinder(radius=STRUT_D/2, segment=[P[i],P[j]], sections=12))
for p in P:
    parts.append(trimesh.creation.icosphere(subdivisions=1, radius=NODE_D/2).apply_translation(p))
mesh=trimesh.boolean.union(parts)
zbot=mesh.bounds[0][2]; zcut=zbot+FLAT
# small flat foot: a disc that reaches UP into the ball to engulf the lowest struts
# (so it fuses into ONE body), then trimmed flush by the flatten below. Snip off after.
if FOOT_D>0:
    z0, z1 = zbot-2.0, zcut+FOOT_H
    foot=trimesh.creation.cylinder(radius=FOOT_D/2, height=z1-z0, sections=64)
    foot.apply_translation([0,0,(z0+z1)/2])
    mesh=trimesh.boolean.union([mesh,foot])
# flatten the bottom flush and drop it to z=0
box=trimesh.creation.box(extents=[400,400,400]); box.apply_translation([0,0,zcut-200])
mesh=trimesh.boolean.difference([mesh,box])
mesh.apply_translation([0,0,-zcut])
# wide thin brim fused under the base (the foot alone detached mid-print): welds to
# the foot and the flattened lowest struts; peel/snip off after printing like a brim.
if BRIM_D>0:
    brim=trimesh.creation.cylinder(radius=BRIM_D/2, height=BRIM_H, sections=64)
    brim.apply_translation([0,0,BRIM_H/2])
    mesh=trimesh.boolean.union([mesh,brim])
mesh.export("buckyball.stl")
mesh.export("buckyball.3mf")     # direct, shared-vertex 3MF (preserves watertightness)
print(f"watertight={mesh.is_watertight}  faces={len(mesh.faces)}  "
      f"size={mesh.extents[0]:.1f}x{mesh.extents[1]:.1f}x{mesh.extents[2]:.1f}mm")
