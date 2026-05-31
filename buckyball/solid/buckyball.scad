// C60 Buckyball — SOLID faceted soccer ball (truncated icosahedron).
// Convex solid with flat pentagon + hexagon faces (the hull of the 60 vertices);
// the 90 edges are engraved as seams for the soccer-ball look. Fully symmetric,
// seated on a flat hexagonal face so it rests dead-level — easiest to print, no
// supports or brim, big footprint.

diameter = 50;    // outer diameter at the vertices (mm)
seam_d   = 1.4;   // width of the engraved seam grooves (mm); 0 = smooth solid

$fn = 32;

phi = (1 + sqrt(5)) / 2;
base = [ [0, 1, 3*phi], [1, 2+phi, 2*phi], [phi, 2, 2*phi+1] ];
function cyclics(v) = [ [v[0],v[1],v[2]], [v[2],v[0],v[1]], [v[1],v[2],v[0]] ];
function signs(v)   = [ for (sx=[-1,1], sy=[-1,1], sz=[-1,1]) [sx*v[0], sy*v[1], sz*v[2]] ];
raw = [ for (b=base) for (c=cyclics(b)) for (p=signs(c)) p ];
function seen(pt,lst,upto) = upto<=0 ? false
    : len([ for(i=[0:upto-1]) if (norm(lst[i]-pt)<1e-4) 1 ]) > 0;
V0 = [ for (i=[0:len(raw)-1]) if (!seen(raw[i],raw,i)) raw[i] ];
k  = (diameter/2) / norm(V0[0]);
V  = [ for (p=V0) p*k ];
all_d = [ for (i=[0:len(V)-2], j=[i+1:len(V)-1]) norm(V[i]-V[j]) ];
emin  = min(all_d);
edges = [ for (i=[0:len(V)-2], j=[i+1:len(V)-1]) if (norm(V[i]-V[j])<emin*1.02) [i,j] ];

module strut(p1, p2, r) {  // used to carve seam grooves along edges
    v = p2-p1; len = norm(v);
    translate(p1) rotate([0,0,atan2(v[1],v[0])]) rotate([0,acos(v[2]/len),0])
        cylinder(h=len, r=r, $fn=16);
}

// seat a hexagonal face on the plate (3-fold axis (1,1,1) -> -z), baked into coords
rot_ang = acos(-1/sqrt(3));  rot_axis = [-1,1,0];
function rotpt(p,axis,ang) = let(u=axis/norm(axis), c=cos(ang), s=sin(ang))
    p*c + cross(u,p)*s + u*(u*p)*(1-c);
Vr = [ for (p=V) rotpt(p, rot_axis, rot_ang) ];

zbot = min([ for (p=Vr) p[2] ]);   // the bottom hexagon face lies in this plane

// solid body = convex hull of the 60 vertices (flat pentagon/hexagon faces)
module solid_ball() {
    hull() for (p=Vr) translate(p) sphere(r=0.01, $fn=6);
}

// drop the bottom face to z=0 and engrave the edge seams
translate([0, 0, -zbot])
    difference() {
        solid_ball();
        if (seam_d > 0)
            for (e=edges) strut(Vr[e[0]], Vr[e[1]], seam_d/2);
    }

echo(vertices=len(V), edges=len(edges), zbot=zbot);  // expect 60, 90
