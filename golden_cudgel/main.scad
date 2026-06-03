// Smooth replacement main shaft for the imported golden_cudgel model.
// The original main.stl was a 9 mm diameter shaft with engraved characters.
// This version removes the character cuts, increases the diameter to 10 mm,
// and keeps the original hex sockets so the already-printed side pieces fit.

$fn = 192;

main_length = 150;        // mm
main_diameter = 10;       // mm

// The side-piece hex peg measures about 5.0 mm across flats.
side_hex_across_flats = 5.0;
socket_clearance = 0.2;   // mm across flats, i.e. about 0.1 mm per side
socket_depth = 5.2;       // mm, slightly deeper than the original 5 mm socket
lead_in_depth = 0.8;      // mm chamfer to help the side peg start cleanly
lead_in_extra = 0.3;      // mm extra across flats at the socket mouth

base_diameter = 34;       // mm sacrificial base diameter for the removable variant
base_thickness = 0.28;    // mm, roughly a first-layer sacrificial brim
base_overlap = 0.25;      // mm radial overlap with the shaft so it prints attached
eps = 0.02;

function hex_radius(across_flats) = across_flats / sqrt(3);

module hex_prism(h, across_flats) {
    cylinder(h = h, r = hex_radius(across_flats), $fn = 6, center = false);
}

module socket_cutouts() {
    socket_af = side_hex_across_flats + socket_clearance;
    lead_af = socket_af + lead_in_extra;

    // Bottom socket.
    translate([0, 0, -eps])
        hex_prism(socket_depth + eps, socket_af);
    translate([0, 0, -eps])
        cylinder(
            h = lead_in_depth + eps,
            r1 = hex_radius(lead_af),
            r2 = hex_radius(socket_af),
            $fn = 6,
            center = false
        );

    // Top socket.
    translate([0, 0, main_length - socket_depth])
        hex_prism(socket_depth + eps, socket_af);
    translate([0, 0, main_length - lead_in_depth])
        cylinder(
            h = lead_in_depth + eps,
            r1 = hex_radius(socket_af),
            r2 = hex_radius(lead_af),
            $fn = 6,
            center = false
        );
}

module removable_base() {
    difference() {
        cylinder(h = base_thickness, d = base_diameter, center = false);
        translate([0, 0, -eps])
            cylinder(
                h = base_thickness + 2 * eps,
                d = main_diameter - 2 * base_overlap,
                center = false
            );
    }
}

module main_shaft(with_base = false) {
    difference() {
        union() {
            cylinder(h = main_length, d = main_diameter, center = false);
            if (with_base)
                removable_base();
        }
        socket_cutouts();
    }
}

main_shaft();
