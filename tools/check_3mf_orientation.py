#!/usr/bin/env python3
"""Check the placed bounding box of a 3MF project.

This is intentionally small and mechanical: it reads the build items from a
3MF, follows Bambu/production-extension component references, applies 3MF
transforms, and checks the final placed bounding box against simple axis limits.
"""
import argparse
import sys
import zipfile
import xml.etree.ElementTree as ET

NS = "{http://schemas.microsoft.com/3dmanufacturing/core/2015/02}"
PNS = "{http://schemas.microsoft.com/3dmanufacturing/production/2015/06}"


def parse_args():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("model_3mf")
    p.add_argument("--label", default="3MF")
    p.add_argument("--min-x", type=float)
    p.add_argument("--max-x", type=float)
    p.add_argument("--min-y", type=float)
    p.add_argument("--max-y", type=float)
    p.add_argument("--min-z", type=float)
    p.add_argument("--max-z", type=float)
    p.add_argument(
        "--object-id",
        action="append",
        help="Only include this build object id; may be passed more than once",
    )
    return p.parse_args()


def matmul(a, b):
    return [
        [
            sum(a[row][k] * b[k][col] for k in range(4))
            for col in range(4)
        ]
        for row in range(4)
    ]


def transform_from_3mf(value):
    if not value:
        return [
            [1.0, 0.0, 0.0, 0.0],
            [0.0, 1.0, 0.0, 0.0],
            [0.0, 0.0, 1.0, 0.0],
            [0.0, 0.0, 0.0, 1.0],
        ]
    nums = [float(x) for x in value.split()]
    if len(nums) != 12:
        raise ValueError(f"expected 12 transform numbers, got {len(nums)}: {value}")
    # 3MF stores a 4x3 row-vector matrix:
    # [m00 m01 m02] [m10 m11 m12] [m20 m21 m22] [tx ty tz].
    return [
        [nums[0], nums[3], nums[6], nums[9]],
        [nums[1], nums[4], nums[7], nums[10]],
        [nums[2], nums[5], nums[8], nums[11]],
        [0.0, 0.0, 0.0, 1.0],
    ]


def apply_transform(m, p):
    x, y, z = p
    return (
        m[0][0] * x + m[0][1] * y + m[0][2] * z + m[0][3],
        m[1][0] * x + m[1][1] * y + m[1][2] * z + m[1][3],
        m[2][0] * x + m[2][1] * y + m[2][2] * z + m[2][3],
    )


def objects_in(model):
    return {o.get("id"): o for o in model.findall(f"{NS}resources/{NS}object")}


def read_model(zf, path):
    return ET.fromstring(zf.read(path.lstrip("/")))


def mesh_vertices_for_object(zf, model, objid, base_transform, depth=0):
    if depth > 8:
        raise RecursionError(f"component nesting too deep at object {objid}")

    obj = objects_in(model).get(objid)
    if obj is None:
        raise KeyError(f"object {objid} not found")

    mesh = obj.find(f"{NS}mesh")
    if mesh is not None:
        for v in mesh.find(f"{NS}vertices").findall(f"{NS}vertex"):
            point = (float(v.get("x")), float(v.get("y")), float(v.get("z")))
            yield apply_transform(base_transform, point)
        return

    components = obj.find(f"{NS}components")
    if components is None:
        raise ValueError(f"object {objid} has neither mesh nor components")

    for comp in components.findall(f"{NS}component"):
        path = comp.get(f"{PNS}path") or comp.get("path")
        target_model = read_model(zf, path) if path else model
        comp_transform = transform_from_3mf(comp.get("transform"))
        combined = matmul(base_transform, comp_transform)
        yield from mesh_vertices_for_object(
            zf, target_model, comp.get("objectid"), combined, depth + 1
        )


def main():
    args = parse_args()
    with zipfile.ZipFile(args.model_3mf) as zf:
        root = read_model(zf, "3D/3dmodel.model")
        points = []
        wanted = set(args.object_id or [])
        for item in root.findall(f"{NS}build/{NS}item"):
            if wanted and item.get("objectid") not in wanted:
                continue
            item_transform = transform_from_3mf(item.get("transform"))
            points.extend(
                mesh_vertices_for_object(zf, root, item.get("objectid"), item_transform)
            )

    if not points:
        sys.exit(f"FAIL {args.label}: no vertices found")

    lo = [min(p[i] for p in points) for i in range(3)]
    hi = [max(p[i] for p in points) for i in range(3)]
    size = [hi[i] - lo[i] for i in range(3)]
    print(
        f"{args.label} placed bbox: "
        f"X={size[0]:.2f} mm, Y={size[1]:.2f} mm, Z={size[2]:.2f} mm"
    )

    checks = [
        ("X", ">=", args.min_x, size[0], lambda a, b: a >= b),
        ("X", "<=", args.max_x, size[0], lambda a, b: a <= b),
        ("Y", ">=", args.min_y, size[1], lambda a, b: a >= b),
        ("Y", "<=", args.max_y, size[1], lambda a, b: a <= b),
        ("Z", ">=", args.min_z, size[2], lambda a, b: a >= b),
        ("Z", "<=", args.max_z, size[2], lambda a, b: a <= b),
    ]
    failures = []
    for axis, op, expected, actual, cmp in checks:
        if expected is not None and not cmp(actual, expected):
            failures.append(f"{axis} {actual:.2f} mm is not {op} {expected:.2f} mm")

    if failures:
        for failure in failures:
            print(f"FAIL {args.label}: {failure}")
        sys.exit(1)

    print(f"PASS {args.label}: orientation bounds satisfied")


if __name__ == "__main__":
    main()
