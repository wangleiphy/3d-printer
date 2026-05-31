// C60 Buckyball — round-strut cage, MAXIMALLY symmetric (full icosahedral).
// Seated on a pentagon face (5-fold axis vertical) and clipped on ALL 12 pentagon
// faces by the same amount, so every pentagon is identical and the ball sits the
// same way on any of its 12 faces. 60 vertices, 90 struts, 12 pentagons + 20 hexagons.

diameter = 50;    // outer diameter at the vertices (mm)
strut_d  = 3.5;   // strut diameter (mm)
joint_d  = 5.0;   // ball-joint diameter (mm) — keep clearly > strut_d (clean mesh)
flat     = 1.0;   // mm shaved off EVERY pentagon face (the flat that seats on the bed).
                  // Small on purpose: the cut then passes through the bottom pentagon's
                  // 5 horizontal struts, giving a wide ~200 mm² footprint. Larger values
                  // cut above those struts and the footprint collapses.

$fn = 24;

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

module strut(p1, p2, r) {
    v = p2-p1; len = norm(v);
    translate(p1) rotate([0,0,atan2(v[1],v[0])]) rotate([0,acos(v[2]/len),0])
        cylinder(h=len, r=r);
}

// the 12 pentagon-normal directions (icosahedron vertices)
ico = concat(
    [ for (a=[-1,1], b=[-1,1]) [0, a, b*phi] ],
    [ for (a=[-1,1], b=[-1,1]) [a, b*phi, 0] ],
    [ for (a=[-1,1], b=[-1,1]) [b*phi, 0, a] ]
);

// seat a PENTAGON on the plate: rotate its 5-fold axis (0,1,phi) onto -z (baked in)
seat_axis = [0, 1, phi];
down = [0,0,-1];
rax  = cross(seat_axis, down);
rang = acos((seat_axis*down) / norm(seat_axis));
function rotpt(p,axis,ang) = let(uu=axis/norm(axis), c=cos(ang), s=sin(ang))
    p*c + cross(uu,p)*s + uu*(uu*p)*(1-c);
Vr    = [ for (p=V) rotpt(p, rax, rang) ];          // seated vertices
ico_r = [ for (d=ico) rotpt(d, rax, rang) ];        // seated pentagon normals

face_dist = max([ for (p=V) p * (ico[0]/norm(ico[0])) ]);  // 25 -> ~23.48 mm
depth     = face_dist - flat;                              // cut plane distance

module buckyball() {
    union() {
        for (e=edges) strut(Vr[e[0]], Vr[e[1]], strut_d/2);
        for (p=Vr)    translate(p) sphere(d=joint_d);
    }
}

// half-space { x : x·dir <= depth }
module halfspace(dir, depth) {
    d = dir/norm(dir); B = 1000;
    rotate([0,0,atan2(d[1],d[0])]) rotate([0,acos(d[2]),0])
        translate([0,0,depth - B]) cube([2*B, 2*B, 2*B], center=true);
}

// clip all 12 pentagon faces equally (intersection => a dodecahedral trim),
// then drop the bottom pentagon (at z = -depth) to z = 0.
translate([0, 0, depth])
    intersection() {
        buckyball();
        intersection_for (i = [0:len(ico_r)-1]) halfspace(ico_r[i], depth);
    }

echo(vertices=len(V), edges=len(edges), face_dist=face_dist, depth=depth);
