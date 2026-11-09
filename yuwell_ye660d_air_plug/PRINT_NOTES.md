# YE660D cuff air plug · fit prototype v1

This prototype approximates the white straight air connector shown with a Yuwell YE660D monitor and YE-62M cuff. Use it only for a gentle fit check with the monitor switched off. The dimensions, seal and pressure-measurement performance have not been verified. Do not use the prototype for blood pressure measurements.

## Geometry

The 5.0 mm diameter of the monitor plug is an assumed scale reference. The two visible sections follow the proportions of the reference photograph. The hose tail, two barbs, through-bore and chamfers are design assumptions.

| Feature | Nominal geometry (mm) |
| --- | --- |
| Monitor plug | Ø5.0 × 14 long |
| Collar | Ø9.5 × 13 long |
| Hose tail | 10 long, Ø4.2 root, Ø4.8 barb crest, Ø3.8 tip |
| Axial through-bore | Ø2.0 |
| Overall length | 37 |

Edit the named parameters in `YE660D-fit-v1.scad` to revise the fit. The STL and unsliced 3MF use millimetres.

## First print

`YE660D-fit-v1-A1.gcode.3mf` contains the toolpath sent for one part in Bambu Studio 2.9.1.70. It was sliced for a Bambu Lab A1, 0.4 mm nozzle, textured PEI plate and Bambu PLA Basic. The monitor end faces the plate. The job used yellow PLA in slot A2.

| Setting | Value |
| --- | --- |
| Layer height | 0.16 mm, first layer 0.20 mm |
| Walls and infill | 2 walls, 15% sparse infill |
| Brim | Automatic, width setting 5 mm, object gap 0.1 mm |
| Support | Automatic tree support, build plate only |
| Slicer estimate including supports | 1.46 g, 231 layers, 29 min 55 s |

Run `./check.sh` to compare the unsliced 3MF with the STL. Remove the external support and brim before checking the fit.
