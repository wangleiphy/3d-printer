# 龙凤斧 Dragon-and-Phoenix Axe — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a parametric OpenSCAD single-bit toy hatchet (~280 mm) with a traditional Chinese dragon (龍) recessed into one cheek and a phoenix (鳳) into the other, exported as two print-ready parts for a Bambu Lab A1.

**Architecture:** One `dragon_phoenix_axe.scad` with a `part` switch (`all`/`head`/`handle`). The **head** is a fully-rounded blunt axe-head solid (Minkowski-rounded extrusion of a 2-D silhouette) with the two creature reliefs `difference()`-d into its ±Y cheeks and a hex socket in its throat. The **handle** is a smooth hull-of-spheres shaft with a hex tenon that plugs into the head socket (glued; the hex stops rotation). Creature art is imported from vetted SVGs in `art/`.

**Tech Stack:** OpenSCAD 2021.01 (`/opt/homebrew/bin/openscad`), Python 3 (`/opt/anaconda3/bin/python`, needs numpy/matplotlib), the repo's `tools/` pipeline (`preview.py`, `stl_to_3mf.py`, `verify_3mf.py`, `preflight.py`, `bambu_print_3mf.py`), Bambu Studio.

**Domain note on "tests":** This repo has no unit-test framework — *the verification pipeline is the test*. For every geometry change the gate is: render the STL, eyeball the `*_preview.png`, then `verify_3mf.py <part>.3mf <part>.stl` must report **watertight ✓ / VALID** (its half-edge checks are the manifold safety net) and `preflight.py` must show the intended bounding box. "Run the test" below means exactly that loop. Never claim a part is done until verify passes.

**Two house footguns to respect (from CLAUDE.md):**
1. Never `rotate()` the *finished* CGAL solid for orientation — it injects non-manifold slivers. (Rotating a single fresh `linear_extrude`/primitive *before* it is unioned is fine and is used below; the trap is rotating the whole assembled head.) Print-orientation is done in the slicer, not by rotating the final mesh.
2. Keep boolean tools cleanly overlapping (≥ the small `eps`) so surfaces don't graze tangent and emit non-manifold junctions.

---

## File Structure

```
dragon_phoenix_axe/
  dragon_phoenix_axe.scad     parametric source; part = "all" | "head" | "handle"
  art/
    dragon.svg                approved papercut dragon silhouette (Task 2)
    phoenix.svg               approved papercut phoenix silhouette (Task 2)
  check.sh                    runs preflight on both parts
  PRINT_NOTES.md              settings + safety checklist (Task 7)
  (generated) dragon_phoenix_axe_head.stl / _head_preview.png / _head.3mf
  (generated) dragon_phoenix_axe_handle.stl / _handle_preview.png / _handle.3mf
  (generated) dragon_phoenix_axe_assembled_preview.png
docs/superpowers/specs/2026-06-10-dragon-phoenix-axe-design.md   (the approved spec)
```

All commands below are run **from inside `dragon_phoenix_axe/`** unless noted.

---

## Task 1: Scaffold the design folder

**Files:**
- Create: `dragon_phoenix_axe/dragon_phoenix_axe.scad`
- Create: `dragon_phoenix_axe/check.sh`
- Create: `dragon_phoenix_axe/art/.gitkeep`

- [ ] **Step 1: Create the folder, art subfolder, and parametric `.scad` skeleton**

Create `dragon_phoenix_axe/dragon_phoenix_axe.scad` with the full parameter block and a placeholder so it renders immediately:

```openscad
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
```

Create `dragon_phoenix_axe/art/.gitkeep` (empty file) so the folder exists before art lands.

- [ ] **Step 2: Create `check.sh` (preflights both parts)**

```bash
#!/usr/bin/env bash
# Pre-print safety check for 龙凤斧 (Dragon-and-Phoenix Axe). Run before slicing.
#   ./check.sh
cd "$(dirname "$0")"
fail=0
for p in head handle; do
  echo "==================== $p ===================="
  /opt/anaconda3/bin/python ../tools/preflight.py dragon_phoenix_axe_$p || fail=1
  echo
done
echo "→ Now read PRINT_NOTES.md in this folder for the slicer settings."
exit $fail
```

- [ ] **Step 3: Make `check.sh` executable and smoke-test the render**

Run:
```bash
cd dragon_phoenix_axe
chmod +x check.sh
openscad -D 'part="head"' -o /tmp/axe_smoke.stl dragon_phoenix_axe.scad && ls -la /tmp/axe_smoke.stl
```
Expected: OpenSCAD exits 0 and `/tmp/axe_smoke.stl` exists (the placeholder cube). This confirms the toolchain + parameter block parse.

- [ ] **Step 4: Commit**

```bash
git add dragon_phoenix_axe/dragon_phoenix_axe.scad dragon_phoenix_axe/check.sh dragon_phoenix_axe/art/.gitkeep
git commit -m "Scaffold dragon_phoenix_axe design folder (params + check.sh)"
```

---

## Task 2: Source & approve the dragon / phoenix art  ⟵ HUMAN REVIEW GATE

The relief quality is entirely the art. The model imports an SVG **silhouette** (single solid fill); the cleaner the path, the cleaner the engraving.

**Vetting criteria (every candidate must pass):**
- Single-colour filled silhouette, **closed paths** (not an open-stroke line drawing).
- No detached islands smaller than ~1.5 mm at final scale (they'd be near-invisible specks).
- Roughly square aspect so it fills the ~55 mm cheek circle; recognisable as a *traditional Chinese* dragon / phoenix.
- Licence: CC0 / public-domain, or hand-built here. Record the source/licence in `PRINT_NOTES.md`.

- [ ] **Step 1: Gather candidates**

Use WebSearch / WebFetch to find CC0/public-domain *traditional Chinese papercut (剪纸) dragon* and *phoenix (凤凰)* silhouette SVGs (e.g. Wikimedia Commons public-domain, openclipart.org which is CC0). Download 2–3 of each into `art/_candidates/`. If no clean source is found, hand-build a simplified stylised silhouette SVG (bold single fill).

- [ ] **Step 2: Verify each candidate actually imports & extrudes in OpenSCAD**

For each candidate file, render a standalone stamp to catch un-importable SVGs early:
```bash
echo 'linear_extrude(2) resize([55,0],auto=true) import("art/_candidates/CANDIDATE.svg", center=true);' > /tmp/stamp.scad
openscad -o /tmp/stamp.stl /tmp/stamp.scad
/opt/anaconda3/bin/python ../tools/preview.py /tmp/stamp.stl /tmp/stamp.png
```
Expected: render exits 0, `/tmp/stamp.png` shows a clean recognisable creature. Discard any that error, come in empty, or render as tangled spaghetti.

- [ ] **Step 3: Present candidates to the user and get approval**

Show the rendered candidate PNGs (terminal `Read`, or the visual companion). **Ask the user to pick one dragon and one phoenix.** Do not proceed until they choose.

- [ ] **Step 4: Save the approved art and record provenance**

Copy the two chosen files to `art/dragon.svg` and `art/phoenix.svg`. Append a "Relief art" line to a scratch note (folded into `PRINT_NOTES.md` in Task 7) recording each file's source + licence. Remove `art/_candidates/`.

- [ ] **Step 5: Commit**

```bash
git add dragon_phoenix_axe/art/dragon.svg dragon_phoenix_axe/art/phoenix.svg
git rm -r --cached dragon_phoenix_axe/art/.gitkeep 2>/dev/null; rm -f dragon_phoenix_axe/art/.gitkeep
git commit -m "Add approved dragon + phoenix relief art (SVG)"
```

---

## Task 3: Handle module

**Files:**
- Modify: `dragon_phoenix_axe/dragon_phoenix_axe.scad` (add `hex_prism` + `handle`, wire `part=="handle"`)

- [ ] **Step 1: Add the hex helper and `handle()` module**

Add above the `part` dispatch (and delete the handle placeholder line):

```openscad
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
```

Replace the dispatch block's handle branch so it calls `handle()`:
```openscad
if (part == "handle") handle();
else cube([blade_reach, head_thick, head_height], center = true);   // head still placeholder
```

- [ ] **Step 2: Render, preview, and verify the handle**

```bash
openscad -D 'part="handle"' -o dragon_phoenix_axe_handle.stl dragon_phoenix_axe.scad
/opt/anaconda3/bin/python ../tools/preview.py dragon_phoenix_axe_handle.stl
/opt/anaconda3/bin/python ../tools/stl_to_3mf.py dragon_phoenix_axe_handle.stl dragon_phoenix_axe_handle.3mf
/opt/anaconda3/bin/python ../tools/verify_3mf.py dragon_phoenix_axe_handle.3mf dragon_phoenix_axe_handle.stl
```
Expected: `verify_3mf.py` prints **watertight ✓** and **VALID** and exits 0. `dragon_phoenix_axe_handle_preview.png` shows a smooth tapered handle with a knob at one end and a small hex peg at the other.

- [ ] **Step 3: Eyeball the preview**

`Read` `dragon_phoenix_axe_handle_preview.png`. Confirm: gentle grip swell, end-knob, clean hex tenon, total length ≈ `handle_length + socket_depth` (~234 mm). If the shaft looks too thin/fat, adjust `grip_d`/`neck_d` and re-render.

- [ ] **Step 4: Commit**

```bash
git add dragon_phoenix_axe/dragon_phoenix_axe.scad dragon_phoenix_axe/dragon_phoenix_axe_handle.stl dragon_phoenix_axe/dragon_phoenix_axe_handle.3mf dragon_phoenix_axe/dragon_phoenix_axe_handle_preview.png
git commit -m "Add handle: tapered shaft + knob + hex tenon"
```

---

## Task 4: Head blank (blunt rounded axe head + hex socket, no relief yet)

**Files:**
- Modify: `dragon_phoenix_axe/dragon_phoenix_axe.scad` (add `head_profile`, `head_solid`, `head` w/ socket only)

- [ ] **Step 1: Add the silhouette, the rounded solid, and a socket-only `head()`**

Add these modules (the `head()` here cuts only the socket; reliefs come in Task 5):

```openscad
// 2-D single-bit axe silhouette in XY: +X = poll/eye side, -X = blade, Y = height.
// Eye centre at origin; handle enters from below (throat at bottom-centre).
module head_profile() {
    offset(r = corner_round) offset(r = -corner_round)
    union() {
        // eye + poll block (right of centre)
        translate([13, 0]) square([30, head_height * 0.45], center = true);
        // blade (flares left to a convex cutting edge)
        polygon(points = [
            [ 2,  head_height * 0.27],   // top near eye
            [-blade_reach * 0.68,  head_height * 0.42],   // toe (upper-left)
            [-blade_reach,         head_height * 0.03],   // cutting-edge mid (far left)
            [-blade_reach * 0.74, -head_height * 0.42],   // heel (lower-left)
            [ 2, -head_height * 0.27],   // bottom near eye
        ]);
    }
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
        // hex socket in the throat, opening downward (handle plugs up into it)
        translate([0, 0, socket_z])
            rotate([180, 0, 0])
                hex_prism(socket_depth + eps, tenon_af + socket_clear);
    }
}
```

Wire the dispatch (replace the head placeholder):
```openscad
if (part == "handle") handle();
else if (part == "head") head();
else { head(); translate([0, 0, socket_z - socket_depth + eps]) handle(); }   // assembled preview
```

- [ ] **Step 2: Render, preview, verify the head blank**

```bash
openscad -D 'part="head"' -o dragon_phoenix_axe_head.stl dragon_phoenix_axe.scad
/opt/anaconda3/bin/python ../tools/preview.py dragon_phoenix_axe_head.stl
/opt/anaconda3/bin/python ../tools/stl_to_3mf.py dragon_phoenix_axe_head.stl dragon_phoenix_axe_head.3mf
/opt/anaconda3/bin/python ../tools/verify_3mf.py dragon_phoenix_axe_head.3mf dragon_phoenix_axe_head.stl
```
Expected: `verify_3mf.py` reports **watertight ✓ / VALID**, exit 0. Preview shows a recognisable single-bit axe head with rounded (non-sharp) edges and a hex hole at the bottom-centre throat.

- [ ] **Step 3: Eyeball + tune the silhouette and socket**

`Read` `dragon_phoenix_axe_head_preview.png`. Check:
- Looks like the reference hatchet (poll block right, convex blade left). Tweak `head_profile()` points if the blade looks wrong.
- The hex socket opens cleanly in the throat and is fully inside the material. If it pokes out a side or floats, adjust `socket_z` (more negative = lower) and re-render.
- Cutting edge is visibly **blunt/rounded**, not a knife edge.

If `verify_3mf.py` reports non-manifold edges: the Minkowski sphere `$fn` or a grazing socket is the usual cause — bump `eps`, ensure `offset(r=-edge_round)` doesn't collapse a thin feature (keep `edge_round < head_thick/2`), and isolate by re-rendering with the socket `difference` commented out.

- [ ] **Step 4: Commit**

```bash
git add dragon_phoenix_axe/dragon_phoenix_axe.scad dragon_phoenix_axe/dragon_phoenix_axe_head.stl dragon_phoenix_axe/dragon_phoenix_axe_head.3mf dragon_phoenix_axe/dragon_phoenix_axe_head_preview.png
git commit -m "Add head blank: blunt rounded axe head + hex socket"
```

---

## Task 5: Engrave the dragon & phoenix into the cheeks

**Files:**
- Modify: `dragon_phoenix_axe/dragon_phoenix_axe.scad` (add `relief_stamp`, extend `head()`)

Depends on Task 2 (`art/dragon.svg`, `art/phoenix.svg` must exist).

- [ ] **Step 1: Add the relief stamp and difference it into both cheeks**

Add the stamp module and extend `head()`'s `difference()` with two more cuts:

```openscad
// SVG silhouette -> scaled -> extruded cut tool (taller than relief_depth so it bites cleanly)
module relief_stamp(file) {
    linear_extrude(height = relief_depth + 1)
        resize([relief_dia, 0], auto = true)
            import(file, center = true);
}
```

Extend `head()` (keep the socket cut, add the two reliefs):
```openscad
module head() {
    difference() {
        head_solid();
        translate([0, 0, socket_z]) rotate([180, 0, 0])
            hex_prism(socket_depth + eps, tenon_af + socket_clear);

        // dragon engraved into the +Y cheek
        translate([relief_x, head_thick / 2 + relief_depth, relief_z])
            rotate([90, 0, 0]) relief_stamp("art/dragon.svg");

        // phoenix engraved into the -Y cheek (mirrored so it reads correctly from that side)
        translate([relief_x, -head_thick / 2 - relief_depth, relief_z])
            rotate([-90, 0, 0]) mirror([1, 0, 0]) relief_stamp("art/phoenix.svg");
    }
}
```

- [ ] **Step 2: Render, preview, verify the engraved head**

```bash
openscad -D 'part="head"' -o dragon_phoenix_axe_head.stl dragon_phoenix_axe.scad
/opt/anaconda3/bin/python ../tools/preview.py dragon_phoenix_axe_head.stl
/opt/anaconda3/bin/python ../tools/stl_to_3mf.py dragon_phoenix_axe_head.stl dragon_phoenix_axe_head.3mf
/opt/anaconda3/bin/python ../tools/verify_3mf.py dragon_phoenix_axe_head.3mf dragon_phoenix_axe_head.stl
```
Expected: **watertight ✓ / VALID**, exit 0. (`preview.py` renders 4 angles, so the cheek faces are visible.)

- [ ] **Step 3: Eyeball + tune placement and depth**

`Read` `dragon_phoenix_axe_head_preview.png`. Confirm: the dragon sits centred on one cheek, the phoenix on the other, both reading the right way round (not mirror-flipped, not upside-down), fully inside the cheek (not spilling over the blade edge). Tune `relief_x`, `relief_z`, `relief_dia`, and the `mirror`/`rotate` signs until it looks right. If a creature reads as raised instead of recessed, the stamp's inward sign is flipped — adjust the `translate` Y so it bites *into* the face.

Verify the engraving is actually recessed and didn't break manifoldness:
```bash
/opt/anaconda3/bin/python ../tools/preflight.py dragon_phoenix_axe_head
```
Expected: PASS — watertight & valid; bounding box ≈ `blade_reach`+poll × `head_thick` × `head_height`.

- [ ] **Step 4: Commit**

```bash
git add dragon_phoenix_axe/dragon_phoenix_axe.scad dragon_phoenix_axe/dragon_phoenix_axe_head.stl dragon_phoenix_axe/dragon_phoenix_axe_head.3mf dragon_phoenix_axe/dragon_phoenix_axe_head_preview.png
git commit -m "Engrave dragon + phoenix relief into the two cheeks"
```

---

## Task 6: Assembled preview & fit check

**Files:**
- Modify: `dragon_phoenix_axe/dragon_phoenix_axe.scad` (tune the `part=="all"` assembly offset only)

- [ ] **Step 1: Render the assembled preview**

```bash
openscad -D 'part="all"' -o /tmp/axe_assembled.stl dragon_phoenix_axe.scad
/opt/anaconda3/bin/python ../tools/preview.py /tmp/axe_assembled.stl dragon_phoenix_axe_assembled_preview.png
```

- [ ] **Step 2: Eyeball the fit**

`Read` `dragon_phoenix_axe_assembled_preview.png`. Confirm the handle's tenon seats into the head throat with the head sitting flush on the handle (no gap, no overlap of the grip into the head). If the seam is off, adjust the assembly translate `socket_z - socket_depth + eps` in the dispatch line until flush. Confirm overall silhouette matches the approved design (~280 mm tall, head proportioned like the reference).

- [ ] **Step 3: Sanity-check total length**

```bash
/opt/anaconda3/bin/python - <<'PY'
import struct
raw=open('/tmp/axe_assembled.stl','rb').read()
n=struct.unpack('<I',raw[80:84])[0]; off=84; zmin=1e9; zmax=-1e9
for _ in range(n):
    off+=12
    for _ in range(3):
        z=struct.unpack_from('<3f',raw,off)[2]; off+=12; zmin=min(zmin,z); zmax=max(zmax,z)
    off+=2
print("assembled height (mm):", round(zmax-zmin,1))
PY
```
Expected: ~280 mm (within ±10). If far off, adjust `handle_length`.

- [ ] **Step 4: Commit**

```bash
git add dragon_phoenix_axe/dragon_phoenix_axe.scad dragon_phoenix_axe/dragon_phoenix_axe_assembled_preview.png
git commit -m "Tune head/handle assembly fit + add assembled preview"
```

---

## Task 7: Print-ready 3MF projects + PRINT_NOTES

**Files:**
- Create: `dragon_phoenix_axe/PRINT_NOTES.md`
- Create (generated): `dragon_phoenix_axe_head_print.3mf`, `dragon_phoenix_axe_handle_print.3mf`

- [ ] **Step 1: Run the full preflight on both parts**

```bash
cd dragon_phoenix_axe
./check.sh
```
Expected: both `head` and `handle` report **PASS — mesh watertight & valid**. Footprint will read "tiny — add a brim" for both (they stand on small faces) — that's expected; the slicer brim in Step 2 handles adhesion (this is the repo's slicer-brim rule, see MEMORY). Do not continue if either reports a mesh FAIL.

- [ ] **Step 2: Generate the print-ready Bambu projects (A1 + PLA, slicer brim, tree supports)**

```bash
/opt/anaconda3/bin/python ../tools/bambu_print_3mf.py dragon_phoenix_axe_head.3mf   dragon_phoenix_axe_head_print.3mf
/opt/anaconda3/bin/python ../tools/bambu_print_3mf.py dragon_phoenix_axe_handle.3mf dragon_phoenix_axe_handle_print.3mf
```
Expected: each prints the read-back embedded settings showing `brim_type=outer_only`, `brim_width=8`, `brim_object_gap=0.1`, tree supports — and verifies the embedded mesh. (Requires Bambu Studio installed at `/Applications/BambuStudio.app`.)

- [ ] **Step 3: Verify the print-project meshes still pass**

```bash
/opt/anaconda3/bin/python ../tools/verify_3mf.py dragon_phoenix_axe_head_print.3mf   dragon_phoenix_axe_head.stl
/opt/anaconda3/bin/python ../tools/verify_3mf.py dragon_phoenix_axe_handle_print.3mf dragon_phoenix_axe_handle.stl
```
Expected: both **VALID** (the verifier follows the Bambu production-extension sub-model reference). Exit 0.

- [ ] **Step 4: Write `PRINT_NOTES.md`**

Create `dragon_phoenix_axe/PRINT_NOTES.md` (model on heshibi's, but for two parts + a swung toy):

```markdown
# 龙凤斧 Dragon-and-Phoenix Axe — print notes

A ~280 mm single-bit toy hatchet for a young child. One cheek carries a traditional
Chinese **dragon (龍)**, the other a **phoenix (鳳)**, recessed 1.2 mm. Prints as two
parts — head + handle — joined by a glued hex tenon.

![assembled](dragon_phoenix_axe_assembled_preview.png)

## At a glance
| | |
|---|---|
| Total length | ~280 mm (head ~80 mm + handle ~210 mm) |
| Head | blunt, fully-rounded, 22 mm thick; dragon/phoenix engraved 1.2 mm |
| Handle | round grip ~22 mm, end-knob ~26 mm, hex tenon |
| Join | 12 mm hex tenon → head socket, 0.2 mm clearance, **glued** |
| Material | PLA |

## Before printing — run the safety check
```bash
./check.sh        # preflights BOTH parts; do not print on a mesh FAIL
```

## Slicer settings (Bambu Studio, Bambu Lab A1, PLA)
Open the print-ready projects (already preset): `dragon_phoenix_axe_head_print.3mf`,
`dragon_phoenix_axe_handle_print.3mf` — outer slicer brim 8 mm / 0.1 mm gap, tree supports.
- **Layer height:** 0.2 mm. **Walls:** 3. **Infill:** 10–15 % (keep it light — it's swung).
- **Head orientation:** stand it so **both cheeks are vertical** (rotate off the auto-arranged
  flat-on-cheek pose) — that prints both reliefs at equal quality. Light tree support under the
  toe overhang.
- **Handle orientation:** standing (vertical) prints support-free and fits the bed. For a tougher
  handle, lay it horizontal with tree supports instead (stronger across the swing axis).

## Assembly
- Dry-fit the tenon into the head socket; it should slip in with light friction.
- Glue (cyanoacrylate/epoxy) and seat fully so the head sits flush. The hex flats keep the
  dragon/phoenix faces square to the blade. **Let it cure fully — this joint must not detach.**

## Safety checklist
**This is a child's toy**
- [ ] Cutting edge is blunt/rounded (it is, by design — confirm no sharp print artefacts; sand if needed)
- [ ] Head is fully glued to the handle — **no detachable parts** (choking hazard)
- [ ] Light enough to swing safely (low infill)

**Operation**
- [ ] Room ventilated; nozzle/bed hot — don't touch; printer not left unattended; watch first layer

**Mesh / design**
- [ ] `./check.sh` reports watertight ✓ / VALID for both parts
- [ ] Head bbox ≈ (blade_reach+poll) × 22 × 80 mm; handle ≈ 26 × 26 × 234 mm

## Relief art provenance
- Dragon: <source + licence>
- Phoenix: <source + licence>

## Re-tuning / regenerating
Edit the parameters at the top of `dragon_phoenix_axe.scad`, then from this folder:
```bash
openscad -D 'part="head"'   -o dragon_phoenix_axe_head.stl   dragon_phoenix_axe.scad
openscad -D 'part="handle"' -o dragon_phoenix_axe_handle.stl dragon_phoenix_axe.scad
/opt/anaconda3/bin/python ../tools/preview.py dragon_phoenix_axe_head.stl
/opt/anaconda3/bin/python ../tools/stl_to_3mf.py dragon_phoenix_axe_head.stl dragon_phoenix_axe_head.3mf
./check.sh
```
```

Fill the `<source + licence>` lines from Task 2.

- [ ] **Step 5: Final verification + commit**

```bash
cd dragon_phoenix_axe && ./check.sh
git add dragon_phoenix_axe/PRINT_NOTES.md dragon_phoenix_axe/dragon_phoenix_axe_head_print.3mf dragon_phoenix_axe/dragon_phoenix_axe_handle_print.3mf
git commit -m "Add print-ready 3MF projects + PRINT_NOTES for dragon-phoenix axe"
```
Expected before committing: `check.sh` exits 0 (both parts PASS).

---

## Self-review (spec coverage)

- Single-bit hatchet form, dims → Tasks 1, 4 ✓
- Traditional Chinese dragon+phoenix, **pictorial**, one per cheek → Tasks 2, 5 ✓
- **Recessed** 1.2 mm relief via SVG import → Task 5 ✓
- 280 mm size → Tasks 1, 6 ✓
- Modular head+handle, hex-socket join → Tasks 3, 4, 6 ✓
- PLA, slicer brim, tree supports → Task 7 ✓
- 6-year-old safety (blunt edges, no detachable parts, lightweight) → Task 4 (rounding) + Task 7 (PRINT_NOTES checklist) ✓
- Art-approval gate before modeling → Task 2 ✓
- Build pipeline (render→preview→3mf→preflight→bambu) → every task + Task 7 ✓
- House footguns (no rotate of final solid; clean boolean overlap) → Architecture note + Tasks 4–5 ✓
```
