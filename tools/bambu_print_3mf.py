#!/usr/bin/env python3
"""Build a print-ready Bambu Studio PROJECT .3mf from a plain mesh .3mf/.stl.

    python ../tools/bambu_print_3mf.py <mesh.3mf|mesh.stl> <out_print.3mf> [key=value ...]

Drives the Bambu Studio CLI: loads the mesh, the printer/filament presets below, and a
user process preset inheriting PROCESS with the OVERRIDES applied — so the exported
project opens in Bambu Studio with everything pre-set (slicer brim, tree supports, ...).
Extra `key=value` args are merged into OVERRIDES (e.g. `brim_width=5`).

Defaults match the brim-free symmetric buckyballs: a gapped outer slicer brim instead of
a modeled-in one, and tree supports. brim_type must be one of Bambu's internal tokens:
auto_brim, outer_only, inner_only, outer_and_inner, brim_ears, no_brim.

The exported project is then patched to select BED_TYPE (no CLI flag for it), and the
embedded settings are read back and printed for verification.
"""
import json, subprocess, sys, time, zipfile, tempfile, os, shutil

BAMBU    = "/Applications/BambuStudio.app/Contents/MacOS/BambuStudio"
PROFILES = "/Applications/BambuStudio.app/Contents/Resources/profiles/BBL"
PRINTER  = "Bambu Lab A1 0.4 nozzle"
FILAMENT = "Bambu PLA Basic @BBL A1"
PROCESS  = "0.20mm Standard @BBL A1"
BED_TYPE = "Textured PEI Plate"
OVERRIDES = {                       # process keys applied on top of PROCESS
    "brim_type": "outer_only",      # slicer brim around the footprint
    "brim_width": "8",
    "brim_object_gap": "0.1",       # the weak-bond release gap
    "enable_support": "1",
    "support_type": "tree(auto)",
}

def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    mesh, out = os.path.abspath(sys.argv[1]), os.path.abspath(sys.argv[2])
    overrides = dict(OVERRIDES)
    for kv in sys.argv[3:]:
        k, _, v = kv.partition("=")
        overrides[k] = v

    # user process preset: inherit the system profile, override only our keys
    preset = {
        "type": "process", "from": "User",
        "name": f"{PROCESS} - {os.path.splitext(os.path.basename(out))[0]}",
        "inherits": PROCESS,
        "compatible_printers": [PRINTER],
        **overrides,
    }
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as f:
        json.dump(preset, f, indent=1); preset_path = f.name

    if os.path.exists(out):
        os.remove(out)
    cmd = [BAMBU, mesh,
           "--load-settings", f"{PROFILES}/machine/{PRINTER}.json;{preset_path}",
           "--load-filaments", f"{PROFILES}/filament/{FILAMENT}.json",
           "--arrange", "1",
           "--export-3mf", out]
    # run from a scratch dir: the CLI drops a result.json status file into its cwd
    scratch = tempfile.mkdtemp()
    r = subprocess.run(cmd, capture_output=True, text=True, cwd=scratch)
    shutil.rmtree(scratch, ignore_errors=True)
    err = [l for l in (r.stdout + r.stderr).splitlines() if "error" in l.lower()]
    # the CLI can finish writing just after exit — wait for the file to land
    for _ in range(50):
        if os.path.exists(out) and os.path.getsize(out) > 0:
            break
        time.sleep(0.2)
    os.remove(preset_path)
    if err or not os.path.exists(out):
        sys.exit("BambuStudio CLI failed:\n" + "\n".join(err or [r.stdout[-2000:]]))

    # patch the selected plate type (no CLI flag), rewriting just that zip member
    cfg_name = "Metadata/project_settings.config"
    tmp = out + ".tmp"
    with zipfile.ZipFile(out) as zin, zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as zout:
        for item in zin.infolist():
            data = zin.read(item.filename)
            if item.filename == cfg_name:
                cfg = json.loads(data)
                cfg["curr_bed_type"] = BED_TYPE
                data = json.dumps(cfg, indent=4).encode()
            zout.writestr(item, data)
    shutil.move(tmp, out)

    # read back and report what the project will open with
    with zipfile.ZipFile(out) as z:
        cfg = json.loads(z.read(cfg_name))
    print(f"wrote {out}  ({os.path.getsize(out)} bytes)")
    for k in ["printer_settings_id", "filament_settings_id", "print_settings_id",
              "curr_bed_type", "layer_height", *overrides]:
        print(f"   {k} = {cfg.get(k)}")
    bad = [k for k, v in overrides.items() if str(cfg.get(k)) != v]
    if bad:
        sys.exit(f"FAIL — overrides not applied: {bad}")
    print("   => all overrides verified in the project")

if __name__ == "__main__":
    main()
