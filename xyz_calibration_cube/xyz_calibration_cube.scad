// XYZ Calibration Cube — first test object for the Bambu Lab A1
// Standard 20 mm cube with X / Y / Z embossed on three adjacent faces.
// Printing this verifies dimensional accuracy on each axis and that
// fine text/emboss detail resolves correctly.
//
// Parametric: change `size`, `depth`, or `font_size` and re-export.

size       = 20;    // cube edge length (mm) — the dimension to measure after printing
depth      = 0.8;   // how deep the letters are carved into the faces (mm)
font_size  = 10;    // letter height (mm)
font_face  = "Liberation Sans:style=Bold";

$fn = 64;           // curve smoothness

difference() {
    cube(size, center = true);

    // --- X on the +X face (right) ---
    translate([size/2 - depth + 0.01, 0, 0])
        rotate([90, 0, 90])
            linear_extrude(height = depth + 0.02)
                text("X", size = font_size, halign = "center",
                     valign = "center", font = font_face);

    // --- Y on the +Y face (back) ---
    translate([0, size/2 - depth + 0.01, 0])
        rotate([90, 0, 180])
            linear_extrude(height = depth + 0.02)
                text("Y", size = font_size, halign = "center",
                     valign = "center", font = font_face);

    // --- Z on the +Z face (top) ---
    translate([0, 0, size/2 - depth + 0.01])
        rotate([0, 0, 90])
            linear_extrude(height = depth + 0.02)
                text("Z", size = font_size, halign = "center",
                     valign = "center", font = font_face);
}
