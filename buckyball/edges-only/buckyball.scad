// C60 Buckyball — minimal symmetric EDGE frame (no nodes).
// Just the 90 edges of the truncated icosahedron, as simple flat-faced beams that
// fuse directly at the 60 vertices — no ball joints. Seated on a PENTAGON face
// (5-fold axis vertical = the solid's highest symmetry), with equal flats on the
// top and bottom faces, so it is mirror-symmetric and rests dead level.
//
// 60 vertices, 90 edges, 32 faces (12 pentagons + 20 hexagons).

diameter  = 50;    // outer diameter at the vertices (mm)
strut_w   = 4.0;   // across-flats width of the beams (mm) — thick enough to print well
flat      = 1.0;   // mm flattened off BOTH bottom and top faces (footprint + symmetry)
strut_fn  = 4;     // beam cross-section: 4 = square (simplest), 6 = hexagonal
weld      = 0.4;   // beams overrun each vertex by this much so junctions fuse solidly
node_k    = 1.4;   // junction node = convex hull of small solid markers set along each
                   // incident edge (NOT a sphere); fuses the 3 beams into a watertight
                   // node. A pure edge frame (no node) is non-manifold, so this is needed.

$fn = 24;

phi = (1 + sqrt(5)) / 2;

// pick the face that sits on the plate (its symmetry axis points down):
//   [0,1,phi] = pentagon  (5-fold, maximal symmetry)   [default]
//   [1,1,1]   = hexagon   (3-fold)
seat_axis = [0, 1, phi];

// --- 60 vertices of the truncated icosahedron ----------------------------
base = [ [0, 1, 3*phi], [1, 2+phi, 2*phi], [phi, 2, 2*phi+1] ];
function cyclics(v) = [ [v[0],v[1],v[2]], [v[2],v[0],v[1]], [v[1],v[2],v[0]] ];
function signs(v)   = [ for (sx=[-1,1], sy=[-1,1], sz=[-1,1]) [sx*v[0], sy*v[1], sz*v[2]] ];
raw = [ for (b=base) for (c=cyclics(b)) for (p=signs(c)) p ];
function seen(pt,lst,upto) = upto<=0 ? false
    : len([ for(i=[0:upto-1]) if (norm(lst[i]-pt)<1e-4) 1 ]) > 0;
V0 = [ for (i=[0:len(raw)-1]) if (!seen(raw[i],raw,i)) raw[i] ];
k  = (diameter/2) / norm(V0[0]);
V  = [ for (p=V0) p*k ];

// --- 90 edges: vertex pairs at the minimum spacing -----------------------
all_d = [ for (i=[0:len(V)-2], j=[i+1:len(V)-1]) norm(V[i]-V[j]) ];
emin  = min(all_d);
edges = [ for (i=[0:len(V)-2], j=[i+1:len(V)-1]) if (norm(V[i]-V[j])<emin*1.02) [i,j] ];

// circumradius giving the requested across-flats width
beam_r = (strut_fn==6) ? strut_w/sqrt(3) : strut_w/sqrt(2);

// one flat-faced beam spanning two points, overrun by `weld` at each end
module beam(p1, p2, r) {
    v = p2-p1; len = norm(v); u = v/len;
    translate(p1 - u*weld) rotate([0,0,atan2(v[1],v[0])]) rotate([0,acos(v[2]/len),0])
        cylinder(h = len + 2*weld, r = r, $fn = strut_fn);
}

// --- seat the chosen face on the plate (axis -> -z), baked into coords ----
down = [0,0,-1];
rax  = cross(seat_axis, down);
rang = acos((seat_axis*down) / norm(seat_axis));
function rotpt(p,axis,ang) = let(uu=axis/norm(axis), c=cos(ang), s=sin(ang))
    p*c + cross(uu,p)*s + uu*(uu*p)*(1-c);
Vr = [ for (p=V) rotpt(p, rax, rang) ];

vz_min = min([ for (p=Vr) p[2] ]);   // bottom pentagon plane (5 coplanar vertices)
vz_max = max([ for (p=Vr) p[2] ]);   // top pentagon plane

// neighbours of vertex i (its 3 edge partners)
function nbrs(i) = concat([ for(e=edges) if(e[0]==i) e[1] ],
                          [ for(e=edges) if(e[1]==i) e[0] ]);

// junction node = convex hull of small solid cubes set a short way along each
// incident edge; fuses the beams flush, no round bulge.
module node_at(i) {
    hull() for (j = nbrs(i))
        translate(Vr[i] + (Vr[j]-Vr[i])/norm(Vr[j]-Vr[i]) * beam_r*node_k)
            cube(beam_r*node_k, center=true);
}

module frame() {
    for (e=edges) beam(Vr[e[0]], Vr[e[1]], beam_r);
    if (node_k > 0) for (i=[0:len(Vr)-1]) node_at(i);
}

// flatten both faces and drop the bottom flat to z = 0
translate([0, 0, -(vz_min+flat)])
    difference() {
        frame();
        translate([0, 0, (vz_min+flat) - 500]) cube(1000, center=true);  // bottom flat
        translate([0, 0, (vz_max-flat) + 500]) cube(1000, center=true);  // top flat
    }

echo(vertices=len(V), edges=len(edges), beam_r=beam_r);  // expect 60, 90
