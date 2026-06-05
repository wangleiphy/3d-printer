# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A workshop for designing 3D-printable objects as **parametric OpenSCAD models**, then carrying each one through a fixed export-and-verify pipeline to a `.3mf` package ready to slice in **Bambu Studio** (target printer: Bambu Lab A1). Each object is one self-contained `<name>.scad` file with tunable parameters at the top; everything else is produced from it. There is no build system, package manager, or test framework — the Python scripts *are* the toolchain.

## Layout

```
3d-printer/
  tools/                     shared toolchain (model-agnostic, argv-driven)
    preview.py               multi-angle preview PNG of any STL
    stl_to_3mf.py            STL -> minimal 3MF Core package
    verify_3mf.py            validate a 3MF (structure + mesh integrity)
    preflight.py             pre-print safety check (verify + size/footprint + reminders)
    bambu_print_3mf.py       mesh 3MF/STL -> print-ready Bambu PROJECT 3mf via the
                             BambuStudio CLI (A1 + PLA presets, slicer brim, tree supports
                             pre-set; key=value args override; reads back + verifies the
                             embedded settings — still verify the mesh with verify_3mf.py)
  <design>/                  one folder per object, e.g. buckyball/, xyz_calibration_cube/
    <name>.scad              parametric source (edit this)
    <name>.stl / .3mf / _preview.png   generated artifacts
    check.sh                 ./check.sh -> runs ../tools/preflight.py <name>
    PRINT_NOTES.md           human-read settings + safety checklist for this design
```

Scripts live once in `tools/` and are called from a design folder with `../tools/...`. They take explicit path args, so the cwd doesn't matter.

## Environment

- **OpenSCAD CLI:** `/opt/homebrew/bin/openscad` (also `OpenSCAD-2021.01.app`)
- **Python:** `/opt/anaconda3/bin/python` (needs `numpy`, `matplotlib`)
- **Bambu Studio:** `/Applications/BambuStudio.app` (open `.3mf` files here to slice)

## The routine (run from inside a design folder, e.g. `buckyball/`)

```bash
openscad -o buckyball.stl buckyball.scad                              # 1. render mesh (CGAL)
/opt/anaconda3/bin/python ../tools/preview.py buckyball.stl           # 2. eyeball it
/opt/anaconda3/bin/python ../tools/stl_to_3mf.py buckyball.stl buckyball.3mf   # 3. pack for Bambu
./check.sh                                                            # 4. verify + safety preflight
```

Then open the `.3mf` in Bambu Studio (`PRINT_NOTES.md` has this design's slicer settings). To change a model, edit the parameters at the top of its `.scad` and re-run these steps.

## Architecture / things to know before editing

- **OpenSCAD render is slow and CGAL-bound.** A `union()` of many primitives (e.g. the buckyball's 90 struts + 60 spheres) takes ~3 minutes to render to STL. The echoed `vertices`/`edges` counts print early, but the STL file only appears after the full CGAL pass completes — don't assume failure if it isn't there immediately. Keep `$fn` modest (≈24) to bound triangle count.

- **The 3MF is hand-built, not library-generated.** `stl_to_3mf.py` reads an STL (auto-detects ASCII vs binary), deduplicates vertices, and writes a minimal but spec-valid 3MF Core OPC zip by hand (`[Content_Types].xml`, `_rels/.rels`, `3D/3dmodel.model`). If you change the 3MF structure, `verify_3mf.py` must agree with it. The package `<Title>` is derived from the output filename.

- **Verification is the safety net — always pass both files.** `verify_3mf.py <model>.3mf <model>.stl` checks OPC structure, XML schema, mesh integrity (watertight via half-edge counts, consistent winding, no degenerate/orphan triangles), and a **round-trip against the source STL** (triangle count, bbox, and volume must match exactly). Omitting the second arg silently round-trips against the cube default and produces false FAILs. The absolute checks are object-agnostic (non-degenerate bbox, positive volume); dimensional correctness comes from the STL round-trip. **`check.sh` / `preflight.py` wraps this** and adds size + first-layer footprint (area of the lowest face) and the operation/mesh safety reminders; run `./check.sh` before every print, and don't print on a mesh FAIL.

- **`verify_3mf.py` understands both 3MF forms.** Our `stl_to_3mf.py` emits the simple form with the `<mesh>` inline in `3D/3dmodel.model`. A `.3mf` re-saved by Bambu Studio is a full *project* (plate thumbnails, slicer config) using the **3MF production extension**: the build item points at an object whose mesh lives in a referenced sub-model file (`<component p:path="/3D/Objects/object_1.model">`). The verifier follows that reference (`resolve_mesh`), so it validates both — don't "fix" a Bambu project 3MF by regenerating it; that throws away the saved print settings.

- **One preview script.** `tools/preview.py <model.stl> [out.png]` auto-bounds from the mesh and renders 4 angles (grey shading, any colour); default output is `<model>_preview.png`. Works for any centered object.

- **Parametric model convention.** Every `.scad` puts its tunable dimensions (size, strut/wall thickness, `$fn`) as named variables at the very top with comments, so a model can be rescaled by editing those and re-exporting. Models are centered on the origin.

- **Mesh-cleanliness footguns (cost real debugging time once).** OpenSCAD reports `Simple: yes` even when the *tessellated STL* has degenerate triangles / non-manifold edges, so it does not catch these — `verify_3mf.py`'s half-edge checks do. Two specific traps in strut-and-node models like the buckyball: (1) **Don't `rotate()` the finished CGAL solid** to orient it — that injects non-manifold slivers on export; instead bake the rotation into the vertex *coordinates* and build the primitives at rotated positions. (2) **Keep node spheres clearly fatter than the struts** (`joint_d` ≳ `strut_d` + ~1 mm); when they're nearly equal the cylinder and sphere surfaces graze tangent and CGAL emits non-manifold junctions. When chasing such a defect, isolate one variable at a time with `openscad -D 'var=val' -o /tmp/x.stl` (no file edits) and locate the bad edges by coordinate before guessing.

## Conventions

- **Adding a new design:** make a `<design>/` folder with `<name>.scad`, then copy a `check.sh` (edit the one `<name>` argument) and a `PRINT_NOTES.md` from an existing design as templates. Run the routine from inside the folder.
- Keep changes scoped to one design + the shared `tools/`. When generalizing a shared script, preserve its behavior for the other designs that already use it (both designs' `check.sh` are the regression test — run them).
- A design's `<name>.stl`, `<name>_preview.png`, and `<name>.3mf` are generated artifacts — regenerate them from the `.scad`; don't hand-edit. (Exception: a `.3mf` re-saved by Bambu Studio is a print-ready project — keep it, don't regenerate over it.)
- **Plate adhesion: use a gapped slicer brim, never a modeled-in one.** A brim modeled into the mesh is welded to the part and tears delicate structures on removal. Keep models fully symmetric (no flats/feet/brims; point contact is fine) and generate a print-ready project with `tools/bambu_print_3mf.py` (outer brim 8 mm, 0.1 mm brim–object gap, tree supports pre-set).
- This directory is a git repository (`github.com:wangleiphy/3d-printer`); generated artifacts are committed alongside sources.
