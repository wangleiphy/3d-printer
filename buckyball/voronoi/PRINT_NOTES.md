# Buckyball (C60) — Voronoi shell — print notes

A delicate, **icosahedrally-symmetric Voronoi** web on the truncated-icosahedron form.
One generic seed point is replicated by the 60 rotations of the buckyball's own symmetry
group, so the cell pattern is organic *and* fully symmetric (and aligned to the solid).
Each spherical-Voronoi edge is a thin rounded strut projected onto the C60 surface.

![preview](buckyball_preview.png)

## At a glance
| | |
|---|---|
| Outer size | ~77 × 80 × 73 mm (75 mm across the vertices) |
| Pattern | 60 cells, 150 struts, 2.4 mm strut diameter |
| Symmetry | full icosahedral, aligned to the C60 — **nothing cut or fused anywhere** |
| Footprint | ~0 mm² (rests on its lowest nodes) — **enable a brim in Bambu Studio** |

**No modeled-in brim, foot, or flattening** (`FLAT=0`, `FOOT_D=0`, `BRIM_D=0`): peeling
the modeled-in brim off damaged the delicate web. Use a **slicer brim in Bambu Studio**
instead (see settings below) — it releases much more gently. The old base options are
still in `gen.py` (set `FLAT`/`FOOT_D`/`BRIM_D` > 0) if ever wanted again.

Size is set by `DIAM` at the top of `gen.py` (`python gen.py 75`); strut and node
diameters scale with it, so it stays equally delicate.

## How it's made (different from the OpenSCAD models)
This shape needs computational geometry, so its **source is `gen.py`** (Python:
`scipy` Voronoi + `trimesh`/`manifold3d` for fast watertight booleans), which writes
`buckyball.stl` **and** `buckyball.3mf` directly. To regenerate / re-tune:
```bash
/opt/anaconda3/bin/python gen.py [diam_mm]      # e.g. gen.py 75
./check.sh
```
Knobs at the top of `gen.py`: `STRUT_D` (delicacy), `SEED` (changes the cell pattern),
`FLAT`/`FOOT_D`/`BRIM_D` (modeled-in base — all 0 now). For a **finer** web, replicate
2 seeds (≈120 cells); for **coarser**, put the seed on a symmetry axis.

## Before printing — run the safety check
```bash
./check.sh        # verifies the mesh; prints size, footprint, reminders
```

## Slicer settings (Bambu Studio, Bambu Lab A1) — this one needs support
**Shortcut: open `buckyball_print.3mf`** — a ready-made Bambu project with everything
below already set (A1 0.4 nozzle, Bambu PLA Basic, 0.20 mm Standard, textured PEI,
outer brim 8 mm with 0.1 mm gap, tree supports). Regenerate it with
`/opt/anaconda3/bin/python ../../tools/bambu_print_3mf.py buckyball.3mf buckyball_print.3mf`.
Opening the plain `buckyball.3mf` instead needs the settings set by hand:

- **Filament:** black PLA. **Layer height:** 0.16–0.20 mm. **Walls:** the 1.6 mm struts
  print as a few perimeters — no infill needed.
- **Supports: ON, tree (auto).** A thin spherical web has overhangs all over the lower
  hemisphere; tree supports are needed for a clean result. The open cells make them
  reachable for removal.
- **Brim: enable in the slicer** — *Others → Brim type: outer brim*, width ~5 mm,
  **brim–object gap 0.1 mm** (the gap is what makes it release without tearing the web;
  the modeled-in brim had none, which is why peeling it hurt the structure).
- **Supports are still required** for the upper overhangs (a hollow sphere arcs over its
  open cells) — the brim fixes the *base*, not the floating struts. Bambu will warn about
  "floating regions"; that's expected — enable tree supports and slice.
- Drop on the plate as-is; the slicer brim pops free after printing (run a blade around
  it if it resists — don't pull upward on the web).

## Safety checklist
**Operation**
- [ ] Room ventilated (PLA fumes) · nozzle ~200 °C / bed ~60 °C are hot
- [ ] Printer **not** left unattended · watching the **first layer**
- [ ] Removing tree supports gently — the struts are delicate

**Mesh / design**
- [ ] `check.sh` reports watertight ✓ and VALID
- [ ] Tree supports enabled **and** slicer brim enabled (the model has no base of its own)

> An older Bambu Studio project (with its slicer settings) is kept as
> `buckyball_bambu_project.3mf` — open it to recover the settings, but slice the
> regenerated `buckyball.3mf`.
