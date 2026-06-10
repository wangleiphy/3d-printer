# 龙凤斧 — Dragon-and-Phoenix Axe — Design Spec

**Date:** 2026-06-10
**Design folder (to be created):** `dragon_phoenix_axe/`
**Target printer:** Bambu Lab A1 (bed 256 × 256 × 256 mm), PLA.

## Goal

A ~28 cm single-bit toy hatchet for a 6-year-old. The axe head has two broad flat
cheek faces; one carries a traditional Chinese **dragon (龍)**, the other a
traditional Chinese **phoenix (鳳)**, both as papercut-style recessed relief.
The toy is meant to be gripped and swung, so it must be blunt, lightweight, and
robust, with no detachable small parts.

This follows the repo's standard workflow: one parametric `.scad` source → STL →
preview → 3MF → preflight → print-ready Bambu project (slicer brim, tree supports).

## Locked decisions

| # | Decision | Choice |
|---|----------|--------|
| Shape | Single-bit hatchet (per user reference image), **not** double-bit or 钺 | ✔ |
| Motif | Pictorial **traditional Chinese** dragon + phoenix (not the bare characters) | ✔ |
| Motif placement | Dragon on one cheek face, phoenix on the other | ✔ |
| Relief technique | **Recessed** (engraved in), 1.2 mm deep | ✔ |
| Size | **280 mm** total, swingable play toy | ✔ |
| Split strategy | **Modular**: head + handle, hex-socket join, glued | ✔ |
| Material | **PLA** (repo pipeline default) | ✔ |

## Form & dimensions (nominal — all parametric at top of `.scad`)

| Parameter | Value | Notes |
|-----------|-------|-------|
| `total_length` | ~280 mm | derived from handle + head overhang |
| `handle_length` | 210 mm | knob to underside of head |
| `grip_d` | 22 mm | round grip, small-hand friendly |
| `knob_d` | 26 mm | slight end-knob so it doesn't slip out of the hand |
| `head_height` | 80 mm | toe-to-heel |
| `blade_reach` | 75 mm | eye axis to cutting edge |
| `head_thickness` | 22 mm | cheek-to-cheek; room for 2× relief + solid core |
| `edge_round` | 4 mm | blade edge blunting radius (safety) |
| `corner_round` | 2–3 mm | general fillet on head corners (toe, heel, poll) |
| `relief_depth` | 1.2 mm | recess depth for the dragon/phoenix |
| `relief_dia` | ~55 mm | art fits within this circle on each cheek |
| `tenon_af` | 12 mm | hex tenon across-flats (handle → head) |
| `socket_depth` | 24 mm | head eye socket depth |
| `socket_clearance` | 0.2 mm | across flats (~0.1 mm/side), per golden-cudgel precedent |
| `$fn` | ~96 (handle), modest for head | bound triangle count per repo guidance |

Model is centered on the origin per house convention.

## The dragon & phoenix relief

- **Style:** traditional 剪纸 / papercut silhouette — bold, mostly-connected single-color
  shapes, which is the correct idiom for engraving and prints cleanly as recessed pockets.
- **Implementation:** clean 2-D **SVG** silhouette per creature → `import("dragon.svg")`
  / `import("phoenix.svg")` → scale to `relief_dia` → `linear_extrude` a stamp →
  `difference()` it from the cheek to a depth of `relief_depth`. One creature per cheek,
  oriented to "read" correctly when the axe is held blade-forward.
- **Art sourcing (REVIEW GATE):** art must be hand-built or CC0/public-domain and vetted
  clean (single fill, no stray islands, closed paths). **2–3 dragon and phoenix candidates
  will be presented for user approval BEFORE they are baked into the model.** SVGs live in
  `dragon_phoenix_axe/art/`.

## How it splits & prints

**Recommended approach — modular (head + handle), hex-socket join:**

- **Head** — one piece. Dragon + phoenix recessed into the two cheeks. Printed **standing**
  (cheeks vertical) so both reliefs come out at equal quality; light tree support under the
  toe overhang as needed. Eye contains a hex socket for the handle tenon.
- **Handle** — one piece, ~210 mm. Printed **standing** (fits under the 256 mm bed height),
  support-free, clean round surface. Hex **tenon** at the top plugs into the head socket and
  is glued; the hex flats stop the head twisting so the faces stay square to the blade.
- Two printable STLs from one `.scad` via a `part` switch.

**Alternatives considered (rejected):**
- *Split-head* (two glued cheek-halves): crispest relief, but adds a seam down the blade
  centerline and a third part. Rejected for added assembly complexity.
- *One-piece flat print*: zero assembly, but the round handle prints poorly lying down and
  the down-facing cheek's relief prints badly. Rejected for quality.

## Safety (6-year-old, swung)

- Cutting edge **rounded to ~`edge_round` (4 mm)** — a blade in silhouette only, not sharp.
  All head corners filleted.
- **Lightweight:** low infill (≈10–15 %); reduces impact energy.
- **No small parts:** head is glued to the handle; nothing is designed to detach.
- Recessed (not raised) relief means no protruding features to snag or snap off.
- PLA is the material; note for the user: PETG would be tougher/less brittle for a swung
  toy, but PLA is the chosen default and is acceptable with rounded edges + adequate walls.

## File / module structure

New folder `dragon_phoenix_axe/`:

```
dragon_phoenix_axe/
  dragon_phoenix_axe.scad     parametric source; `part = "all"|"head"|"handle"`
  art/
    dragon.svg                approved papercut dragon silhouette
    phoenix.svg               approved papercut phoenix silhouette
  check.sh                    -> ../tools/preflight.py (per-part)
  PRINT_NOTES.md              settings + safety checklist (from template)
  (generated) *_head.stl, *_handle.stl, *_preview.png, *.3mf
```

`.scad` module sketch:
- `module handle()` — tapered round shaft + end-knob + hex tenon at top.
- `module head_blank()` — eye block + blade, edges rounded, blade edge blunted, hex socket.
- `module dragon_relief()` / `phoenix_relief()` — import + extrude SVG stamp.
- `module head()` — `head_blank()` minus the two reliefs (one per cheek) minus the socket.
- Top-level: `if (part=="all") assembled-preview; else if "head" head(); else handle();`
  Rotation for print orientation is applied per-part **baked into coordinates**, never as
  a `rotate()` on the finished CGAL solid (repo footgun: rotating the solid injects
  non-manifold slivers on export).

## Build pipeline (per design part)

```bash
cd dragon_phoenix_axe/
openscad -D 'part="head"'   -o dragon_phoenix_axe_head.stl   dragon_phoenix_axe.scad
openscad -D 'part="handle"' -o dragon_phoenix_axe_handle.stl dragon_phoenix_axe.scad
/opt/anaconda3/bin/python ../tools/preview.py dragon_phoenix_axe_head.stl
/opt/anaconda3/bin/python ../tools/stl_to_3mf.py dragon_phoenix_axe_head.stl dragon_phoenix_axe_head.3mf
./check.sh   # preflight: verify + size + footprint + safety reminders (per part)
# then print-ready project with slicer brim + tree supports:
/opt/anaconda3/bin/python ../tools/bambu_print_3mf.py dragon_phoenix_axe_head.3mf ...
```

Verify both STL and 3MF together (`verify_3mf.py <model>.3mf <model>.stl`) — never omit
the STL arg. Watch for the strut/sphere-style mesh footguns only if organic relief produces
non-manifold edges; isolate with `-D` overrides, don't guess.

## Out of scope (YAGNI)

- Multi-color / painted finish (single-color relief reads fine via shadow; can revisit).
- Moving parts, sound, electronics.
- A matched phoenix-only second axe (the original "pair" idea was dropped at disambiguation).
- Sizes other than the 280 mm play-toy variant (parametric, so re-derivable later).

## Open items / review gates

1. **Dragon & phoenix art** — present 2–3 candidates each, get user approval before modeling. ← first implementation step
2. Final print-orientation tuning (support placement on the head) — settle at slicing time.
