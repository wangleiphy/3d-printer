// C60 Buckyball — PURE ball-and-stick, perfectly symmetric.
// 60 sphere joints + 90 cylinder struts; nothing flattened or clipped anywhere.
// Seated on a pentagon face (5-fold axis vertical, rotation baked into the vertex
// coordinates, never applied to the finished solid). With brim_d = 0 (default) the
// model is fully icosahedrally symmetric and the 5 bottom balls just kiss the plate —
// add a BRIM IN THE SLICER (Bambu Studio) for adhesion instead of a modeled-in one.
// Set brim_d > 0 to bring back the modeled-in brim disc the 5 lowest balls sink
// `bite` deep into (snip off after printing; leaves 5 witness dots to sand).

diameter = 75;    // outer diameter at the vertices (mm)
strut_d  = 5.0;   // strut diameter (mm)
joint_d  = 7.5;   // ball-joint diameter (mm) — keep clearly > strut_d (clean mesh)
brim_d   = 0;     // modeled-in brim disc diameter (mm); 0 = none → add a brim in Bambu Studio
brim_h   = 0.6;   // brim thickness (mm) — ~3 layers at 0.2 mm; peels/snips off
bite     = 0.45;  // how deep the 5 bottom balls sink into the brim (fusion depth)

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

// seat a PENTAGON on the plate: rotate its 5-fold axis (0,1,phi) onto -z (baked in)
seat_axis = [0, 1, phi];
down = [0,0,-1];
rax  = cross(seat_axis, down);
rang = acos((seat_axis*down) / norm(seat_axis));
function rotpt(p,axis,ang) = let(uu=axis/norm(axis), c=cos(ang), s=sin(ang))
    p*c + cross(uu,p)*s + uu*(uu*p)*(1-c);
Vr = [ for (p=V) rotpt(p, rax, rang) ];          // seated vertices

// With a brim: raise the ball so its 5 lowest balls dip exactly `bite` into it.
// Without: seat the TESSELLATED bottom on z=0 — an OpenSCAD sphere has no pole
// vertex; its lowest facet is a flat cap at r*cos(180/$fn) below the centre.
zlow  = min([ for (p=Vr) p[2] ]) - joint_d/2;            // analytic ball bottom
zmesh = min([ for (p=Vr) p[2] ]) - joint_d/2*cos(180/$fn); // tessellated bottom cap
lift  = brim_d > 0 ? (brim_h - bite) - zlow : -zmesh;

module buckyball() {
    union() {
        for (e=edges) strut(Vr[e[0]], Vr[e[1]], strut_d/2);
        for (p=Vr)    translate(p) sphere(d=joint_d);
    }
}

union() {
    translate([0, 0, lift]) buckyball();
    if (brim_d > 0)
        cylinder(d=brim_d, h=brim_h);            // modeled-in brim on the plate (z=0)
}

echo(vertices=len(V), edges=len(edges), lift=lift,
     ball_bottom=brim_d > 0 ? brim_h - bite : 0);
