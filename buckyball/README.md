# Buckyball (C60) — design variants

Every folder is one self-contained variant with its own source, generated
`.stl`/`.3mf`/`_preview.png`, a `check.sh` pre-print safety check, and (most) a
`PRINT_NOTES.md`. They share the `../tools/` toolchain. Run `./check.sh` in a folder
before printing.

The exploration converged on **`voronoi/`** — a delicate, fully-symmetric Voronoi shell.

| variant | what it is | symmetry | footprint | mesh |
|---|---|---|---|---|
| **`voronoi/`** ⭐ | delicate icosahedral Voronoi web on the C60 form (75 mm) | full icosahedral | 167 mm² | watertight ✓ |
| `solid/` | solid faceted soccer-ball, engraved seams | full icosahedral | flat face | 4 non-manifold seams* |
| `edges-only/` | square-beam edge frame, **no node spheres**, pentagon-seated | 5-fold | 387 mm² | watertight ✓ |
| `symmetric-flats/` | round-strut cage, all 12 pentagons flattened equally | full icosahedral | 203 mm² | watertight ✓ |
| `faceted-struts/` | hexagonal-beam struts + ball joints, top/bottom flats | 3-fold | 223 mm² | watertight ✓ |
| `hex-seated/` | original round-strut cage, single bottom flat | 3-fold (asym.) | 202 mm² | watertight ✓ |

\* `solid/` has 4 non-manifold edges where the engraved seams meet vertices — cosmetically
irrelevant and auto-repaired by Bambu Studio on import, but it fails the strict `check.sh`.

## Notes
- Most variants are parametric OpenSCAD (`buckyball.scad`). **`voronoi/`** is computational
  (Python: `scipy` Voronoi + `trimesh`/`manifold3d`), so its source is `gen.py`, which
  writes the `.stl` and `.3mf` directly.
- "Maximally symmetric" for a buckyball means seating on a **pentagon** (5-fold axis) or
  flattening **all 12 pentagons** equally (full icosahedral) — a hexagon seat is only 3-fold.
- C60 is vertex-transitive but **not edge-transitive** (30 hexagon–hexagon + 60
  pentagon–hexagon edges), so no orientation makes all 90 edges equivalent.
