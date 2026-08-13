#!/usr/bin/env python3
#sanity checks on the frame rendered by test_vga.bash
import sys
from PIL import Image

img = Image.open(sys.argv[1] if len(sys.argv) > 1 else "output/vga_out.png").convert("RGB")
assert img.size == (640, 480), f"bad size {img.size}"
px = img.load()

fails = []
def check(name, ok, detail=""):
    print(f"[{'PASS' if ok else 'FAIL'}] {name} {detail}")
    if not ok:
        fails.append(name)

#sky color exact in top corners
check("sky", px[5, 5] == (173, 216, 230) and px[634, 5] == (173, 216, 230), f"{px[5,5]}")

#sphere centroid where the geometry says it should be
#silhouette mask because red leads blue on every sphere pixel however its lit
reds = [(x, y) for y in range(480) for x in range(640)
        if px[x, y][0] > px[x, y][2] + 10]
cx = sum(p[0] for p in reds) / len(reds)
cy = sum(p[1] for p in reds) / len(reds)
#x=320 from scene symmetry and y=310 calibrated from a known good render
check("sphere centroid", abs(cx - 320) <= 2 and abs(cy - 310) <= 3, f"({cx:.1f},{cy:.1f}) n={len(reds)}")

#floor is grayscale checkerboard
def grayish(p): return abs(p[0] - p[1]) <= 6 and abs(p[1] - p[2]) <= 6
check("floor grayscale", grayish(px[100, 460]) and grayish(px[540, 460]))

#shadow region clearly darker than lit floor on the same row
sh = sum(px[260, 415]) / 3
lit = sum(px[560, 415]) / 3
check("shadow", sh < 0.6 * lit, f"shadow={sh:.0f} lit={lit:.0f}")

sys.exit(1 if fails else 0)
