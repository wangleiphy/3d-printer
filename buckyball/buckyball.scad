// C60 Buckyball — open wireframe cage (truncated icosahedron edge skeleton)
// 60 vertices, 90 edges (struts), 32 faces (12 pentagons + 20 hexagons).
// The print is the bond skeleton: 90 cylindrical struts joined by 60 ball
// joints, so the pentagon/hexagon openings stay see-through. Black filament.
//
// Parametric: change `diameter`, `strut_d`, or `joint_d` and re-export.

diameter = 50;    // outer diameter measured at the vertices (mm)
strut_d  = 3.5;   // bond strut diameter (mm)
joint_d  = 5.0;   // vertex ball-joint diameter (mm) — must stay clearly fatter than
                  // strut_d so struts plunge inside the node; too close (e.g. 4.0)
                  // makes strut/sphere surfaces graze tangent and CGAL emits
                  // non-manifold slivers at the junctions. 5.0 keeps the mesh clean.
hex_down = true;  // rest on a hexagonal face (soccer-ball seating) so the bottom
                  // struts are horizontal — clean line-contact, NO brim needed
flat     = 1.5;   // mm shaved off the very bottom to turn those lines into solid
                  // contact strips (0 = bare). A whole hexagon of contact, no brim.

$fn = 24;         // curve smoothness for cylinders & spheres

phi = (1 + sqrt(5)) / 2;   // golden ratio

// --- 60 vertices of the truncated icosahedron ----------------------------
// All even (cyclic) permutations of three base triples, every sign combo.
base = [
    [0,    1,       3*phi   ],
    [1,    2 + phi, 2*phi   ],
    [phi,  2,       2*phi + 1]
];

function cyclics(v) = [ [v[0],v[1],v[2]], [v[2],v[0],v[1]], [v[1],v[2],v[0]] ];
function signs(v)   = [ for (sx=[-1,1], sy=[-1,1], sz=[-1,1])
                            [sx*v[0], sy*v[1], sz*v[2]] ];

// raw point list (contains duplicates wherever a coordinate is 0)
raw = [ for (b = base) for (c = cyclics(b)) for (p = signs(c)) p ];

// keep the first occurrence of each point within epsilon
function seen(pt, lst, upto) =
    upto <= 0 ? false
    : len([ for (i = [0:upto-1]) if (norm(lst[i] - pt) < 1e-4) 1 ]) > 0;

V0 = [ for (i = [0:len(raw)-1]) if (!seen(raw[i], raw, i)) raw[i] ];

// --- scale so the vertex circumsphere diameter == `diameter` -------------
R0  = norm(V0[0]);                 // base circumradius (vertex-transitive: all equal)
k   = (diameter/2) / R0;
V   = [ for (p = V0) p * k ];

// --- edges: vertex pairs separated by the minimum pairwise distance ------
all_d = [ for (i = [0:len(V)-2], j = [i+1:len(V)-1]) norm(V[i] - V[j]) ];
emin  = min(all_d);
edges = [ for (i = [0:len(V)-2], j = [i+1:len(V)-1])
              if (norm(V[i] - V[j]) < emin * 1.02) [i, j] ];

// --- one cylinder strut spanning two points ------------------------------
module strut(p1, p2, r) {
    v   = p2 - p1;
    len = norm(v);
    az  = atan2(v[1], v[0]);       // azimuth in xy-plane
    pol = acos(v[2] / len);        // polar angle from +z
    translate(p1)
        rotate([0, 0, az])
            rotate([0, pol, 0])
                cylinder(h = len, r = r);
}

// --- orientation: seat a hexagonal face on the plate ---------------------
// Rotate the 3-fold axis (1,1,1) onto -z so a hexagon sits flat on the bed; its
// 6 vertices become coplanar at the bottom (verified) and the 6 struts between
// them lie horizontal — ideal first-layer contact.
//
// IMPORTANT: we bake the rotation into the vertex COORDINATES, not via rotate()
// on the finished solid. Rotating the CGAL solid after the union injects 6
// degenerate/non-manifold tessellation slivers on STL export; pre-rotating the
// points keeps the mesh watertight.
rot_ang  = hex_down ? acos(-1 / sqrt(3)) : 0;   // 125.26°
rot_axis = [-1, 1, 0];

function rotpt(p, axis, ang) =                  // Rodrigues rotation (degrees)
    let (k = axis / norm(axis), c = cos(ang), s = sin(ang))
    p * c + cross(k, p) * s + k * (k * p) * (1 - c);

Vr   = [ for (p = V) rotpt(p, rot_axis, rot_ang) ];   // seated vertices
zmin = min([ for (p = Vr) p[2] ]) - joint_d/2;        // lowest point of the cage

// --- assemble: 90 struts + 60 ball joints into one watertight solid ------
module buckyball() {
    union() {
        for (e = edges) strut(Vr[e[0]], Vr[e[1]], strut_d/2);
        for (p = Vr)    translate(p) sphere(d = joint_d);
    }
}

// Shave a thin flat onto the bottom (slab below z = zmin+flat) and drop that flat
// to z = 0 so the model rests on a solid hexagonal footprint instead of a point.
translate([0, 0, -(zmin + flat)])
    difference() {
        buckyball();
        if (flat > 0)
            translate([0, 0, zmin + flat - 500])
                cube(1000, center = true);
    }

echo(vertices = len(V), edges = len(edges), zmin = zmin, flat = flat);  // expect 60, 90
