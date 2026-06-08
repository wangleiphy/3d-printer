// 和氏璧 (Héshìbì) — plain ritual jade *bì* disc, for the Bambu Lab A1.
//
// A flat annular disc: the classic *bì* form, clean and minimalist — fully
// symmetric top-to-bottom and rotationally, no rim, no pattern, no text. The
// proportion follows the Erya definition of a true bì — 肉倍好谓之璧 (the solid
// ring ≈ twice the hole) — so the hole diameter is outer_d / 5.
//
// Parametric: change the values below and re-export (see PRINT_NOTES.md).

outer_d     = 80;    // outer diameter (mm) — the dimension to measure after printing
hole_d      = 16;    // central hole diameter (mm) = outer_d/5 (classical 璧 ratio)
thickness   = 6;     // disc thickness (mm)
edge_radius = 2.5;   // rounding on the outer + inner rim edges (mm) — must be < thickness/2

$fn = 200;           // smoothness: facets around the revolution + segments per corner round

r_out = outer_d / 2;
r_in  = hole_d  / 2;

// The whole part is ONE 2D cross-section revolved 360° about Z — not a boolean
// stack. The profile is a rectangle spanning radius r_in → r_out, full
// thickness, with all four corners rounded by edge_radius (the standard
// offset(r) offset(-r) idiom). rotate_extrude turns it into a watertight,
// guaranteed-manifold disc that renders in seconds (no CGAL union to wait on)
// and sails through verify_3mf.py's half-edge checks.
rotate_extrude(angle = 360)
    translate([r_in, -thickness / 2])
        offset(r = edge_radius)
            offset(delta = -edge_radius)
                square([r_out - r_in, thickness]);
