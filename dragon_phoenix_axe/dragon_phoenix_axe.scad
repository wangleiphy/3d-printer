// 龙凤斧 Dragon-and-Phoenix Axe — single-bit toy hatchet, Bambu Lab A1, PLA.
// Parametric: edit the values below and re-export (see PRINT_NOTES.md).
// Export each part with:  openscad -D 'part="head"' -o ..._head.stl dragon_phoenix_axe.scad

part = "all";            // "all" (assembled preview) | "head" | "handle"

// ---- Handle ----
handle_length = 210;     // mm, knob to underside of head
grip_d        = 22;      // mm, round grip (small-hand friendly)
knob_d        = 26;      // mm, end knob so it doesn't slip out
neck_d        = 18;      // mm, slim just under the head

// ---- Head ----
head_height   = 80;      // mm, toe to heel (vertical, Z)
blade_reach   = 73;      // mm, eye axis to cutting edge (X)
head_thick    = 22;      // mm, cheek to cheek (Y)
edge_round    = 4;       // mm, blunting radius on ALL head edges (safety)
corner_round  = 3;       // mm, silhouette corner fillet

// ---- Relief ----
relief_depth  = 1.2;     // mm, engraving depth
relief_dia    = 55;      // mm, art fits within this width on each cheek
relief_x      = -18;     // mm, art centre on the cheek (X)  [tune in Task 5]
relief_z      = 4;       // mm, art centre on the cheek (Z)  [tune in Task 5]

// ---- Hex socket / tenon join ----
tenon_af      = 12;      // mm across flats (handle tenon)
socket_clear  = 0.2;     // mm across flats (~0.1 mm/side), per golden-cudgel precedent
socket_depth  = 24;      // mm
socket_z      = 5;       // mm, socket ceiling height in the head throat (~socket_depth deep)

$fn = 64;
eps = 0.05;

module hex_prism(h, af) {            // af = across flats
    cylinder(h = h, r = af / sqrt(3), $fn = 6);
}

module handle() {
    union() {
        // smooth tapered shaft: knob -> grip swell -> slim neck (hull of spheres = clean & manifold)
        hull() {
            sphere(d = knob_d, $fn = $fn);
            translate([0, 0, handle_length * 0.5]) sphere(d = grip_d, $fn = $fn);
        }
        hull() {
            translate([0, 0, handle_length * 0.5]) sphere(d = grip_d, $fn = $fn);
            translate([0, 0, handle_length])       sphere(d = neck_d, $fn = $fn);
        }
        // hex tenon on top (plugs into head socket)
        translate([0, 0, handle_length - eps]) hex_prism(socket_depth, tenon_af);
    }
}

// 2-D single-bit axe silhouette in XY: +X = poll/eye side, -X = blade, Y = height.
// Eye centre at origin; handle enters from below (throat at bottom-centre).
module head_profile() {
    // Single-bit hatchet outline (corners rounded by the offset idiom): a short poll block
    // on the right, a flared blade on the left whose cutting edge is a convex arc from the
    // toe (top) through the tip to the heel (bottom). Bottom edge dips to the throat at x=0.
    offset(r = 3) offset(r = -3)
    polygon(points = [
        [ 30,                head_height * 0.19],   // poll top-right
        [-5,                 head_height * 0.24],   // eye top
        [-blade_reach * 0.78, head_height * 0.50],  // toe (top of cutting edge)
        [-blade_reach * 0.96, head_height * 0.275], // cutting edge upper
        [-blade_reach,        0],                    // cutting edge tip (far left)
        [-blade_reach * 0.96,-head_height * 0.275], // cutting edge lower
        [-blade_reach * 0.78,-head_height * 0.50],  // heel (bottom of cutting edge)
        [-5,                 -head_height * 0.24],   // eye bottom
        [ 30,               -head_height * 0.19],   // poll bottom-right
    ]);
}

// Fully-rounded blunt head: shrink the profile/thickness by edge_round, then Minkowski a
// sphere back on so EVERY edge (cheeks + blade) is rounded -> kid-safe, no sharp tip.
module head_solid() {
    minkowski() {
        rotate([90, 0, 0])
            linear_extrude(height = head_thick - 2 * edge_round, center = true)
                offset(r = -edge_round) head_profile();
        sphere(r = edge_round, $fn = 24);
    }
}

module head() {
    difference() {
        head_solid();
        // hex socket: a long downward prism that pierces the bottom throat (opens for the
        // handle tenon); its ceiling sits at z = socket_z, giving ~socket_depth usable depth.
        translate([0, 0, socket_z])
            rotate([180, 0, 0])
                hex_prism(60, tenon_af + socket_clear);
    }
}

if (part == "handle") handle();
else if (part == "head") head();
else { head(); translate([0, 0, socket_z - handle_length - socket_depth + eps]) handle(); }   // assembled preview
