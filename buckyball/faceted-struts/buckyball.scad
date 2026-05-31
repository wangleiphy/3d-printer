// C60 Buckyball — FACETED frame with flat-faced struts.
// Same truncated-icosahedron skeleton, but every strut is a hexagonal-prism beam
// (flat sides) instead of a round rod, for a geometric/faceted look. Seated on a
// hexagonal face with matching flats top & bottom, so it is mirror-symmetric.

diameter  = 50;    // outer diameter at the vertices (mm)
strut_w   = 3.6;   // across-flats width of the hex-prism struts (mm)
joint_d   = 5.2;   // node diameter (mm) — keep clearly > strut_w (clean mesh)
flat      = 1.5;   // mm shaved off BOTH bottom and top hexagon faces (symmetric)
strut_fn  = 6;     // 6 = hexagonal beams (flat-faced); 4 = square beams
joint_fn  = 18;    // node smoothness

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

// hex-prism beam between two points. r = circumradius so width-across-flats = strut_w.
module beam(p1, p2, r) {
    v = p2-p1; len = norm(v);
    translate(p1) rotate([0,0,atan2(v[1],v[0])]) rotate([0,acos(v[2]/len),0])
        cylinder(h=len, r=r, $fn=strut_fn);
}

rot_ang = acos(-1/sqrt(3));  rot_axis = [-1,1,0];
function rotpt(p,axis,ang) = let(u=axis/norm(axis), c=cos(ang), s=sin(ang))
    p*c + cross(u,p)*s + u*(u*p)*(1-c);
Vr = [ for (p=V) rotpt(p, rot_axis, rot_ang) ];

zmin = min([ for (p=Vr) p[2] ]) - joint_d/2;
zmax = max([ for (p=Vr) p[2] ]) + joint_d/2;

// circumradius so a hex prism (across-flats = strut_w) has the right width
beam_r = (strut_fn == 6) ? strut_w / sqrt(3) : strut_w / sqrt(2);

module buckyball() {
    union() {
        for (e=edges) beam(Vr[e[0]], Vr[e[1]], beam_r);
        for (p=Vr)    translate(p) sphere(d=joint_d, $fn=joint_fn);
    }
}

translate([0, 0, -(zmin+flat)])
    difference() {
        buckyball();
        if (flat > 0) {
            translate([0, 0, (zmin+flat) - 500]) cube(1000, center=true);
            translate([0, 0, (zmax-flat) + 500]) cube(1000, center=true);
        }
    }

echo(vertices=len(V), edges=len(edges), beam_r=beam_r);  // expect 60, 90
