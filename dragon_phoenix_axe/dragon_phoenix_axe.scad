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
socket_z      = -8;      // mm, where the socket starts in the head throat [tune in Task 4]

$fn = 64;
eps = 0.05;

// placeholder until modules land
if (part == "handle") sphere(d = knob_d);
else cube([blade_reach, head_thick, head_height], center = true);
