# XYZ calibration cube — print notes

A 20 mm cube with **X / Y / Z** carved into three adjacent faces. First test object for a
new printer/filament: print it, then measure each axis with calipers to check dimensional
accuracy and that fine emboss detail resolves.

![preview](xyz_cube_preview.png)

## At a glance
| | |
|---|---|
| Size | 20 × 20 × 20 mm |
| Letters | 0.8 mm deep, 10 mm tall, Liberation Sans Bold |
| Material | ~8 cm³ solid (less with infill) |
| Seats on | a full 20 × 20 mm face → **400 mm² footprint** |

## Before printing — run the safety check
```bash
./check.sh        # verifies the mesh and prints size, footprint, and reminders
```
Do **not** print if `check.sh` reports a mesh FAIL.

## Slicer settings (Bambu Studio, Bambu Lab A1)
- **Filament:** PLA. **Layer height:** 0.2 mm. **Walls:** 2–3, **infill:** 15 %.
- **Brim: none, supports: none** — it's a solid cube on a full flat face.
- Orient with the **Z** face up so the top letter prints cleanly.

## What to check after printing
- Measure X, Y, Z edges with calipers — each should read **20.00 mm** (±0.1–0.2 mm typical).
- If an axis is consistently off, adjust flow/steps; if letters are mushy, slow down or lower layer height.

## Safety checklist
**Operation**
- [ ] Room ventilated
- [ ] Nozzle (~200 °C) and bed (~60 °C) are hot — don't touch during/after
- [ ] Printer will **not** be left unattended
- [ ] Watching the **first layer**

**Mesh / design**
- [ ] `check.sh` reports watertight ✓ and VALID
- [ ] Bounding box reads 20 × 20 × 20 mm

## Re-tuning / regenerating
Edit `size`, `depth`, or `font_size` at the top of `xyz_calibration_cube.scad`, then from this folder:
```bash
openscad -o xyz_calibration_cube.stl xyz_calibration_cube.scad
/opt/anaconda3/bin/python ../tools/preview.py xyz_calibration_cube.stl
/opt/anaconda3/bin/python ../tools/stl_to_3mf.py xyz_calibration_cube.stl xyz_calibration_cube.3mf
./check.sh
```
