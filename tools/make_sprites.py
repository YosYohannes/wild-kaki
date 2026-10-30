"""Writes every WildKaki sprite and scene object as its own PNG, plus lib/animals/art_data.dart.

Per-base art lives in tools/sprites (see its README). Run: python3 tools/make_sprites.py [--only BASE]
"""
import argparse
import math
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

sys.dont_write_bytecode = True
TOOLS = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOLS))
sys.path.insert(0, str(TOOLS / "sprites"))

import _core  # noqa: E402
import gen_catalog  # noqa: E402

ROOT = TOOLS.parent
OUT = ROOT / "assets/sprites"
MODULES = TOOLS / "sprites"
ART_OUT = ROOT / "lib/animals/art_data.dart"
SHEET_DIR = ROOT / "build/sprites"

PAL = {
    "o": "#d9772f", "r": "#b3591f", "w": "#f6eedc", "k": "#2a2a22", "e": "#f3ecdc", "O": "#2e2218",
    "y": "#e8a23a", "B": "#5a8ac0", "D": "#3a5a8a",
    "A": "#43893d", "M": "#2a6e36", "N": "#1b4f29", "T": "#6aad4c", "V": "#143c20",
}


def mulberry(seed):
    state = [seed & 0xFFFFFFFF]

    def imul(a, b):
        return (a * b) & 0xFFFFFFFF

    def nxt():
        state[0] = (state[0] + 0x6D2B79F5) & 0xFFFFFFFF
        s = state[0]
        t = imul(s ^ (s >> 15), 1 | s)
        t = ((t + imul(t ^ (t >> 7), 61 | t)) & 0xFFFFFFFF) ^ t
        return ((t ^ (t >> 14)) & 0xFFFFFFFF) / 4294967296

    return nxt


def grid(w, h):
    return [["."] * w for _ in range(h)]


def put(g, x, y, ch):
    if 0 <= y < len(g) and 0 <= x < len(g[0]):
        g[y][x] = ch


def rect(g, x0, y0, x1, y1, ch):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            put(g, x, y, ch)


def blob(g, cx, cy, rx, ry, ch):
    for y in range(len(g)):
        for x in range(len(g[0])):
            if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1:
                g[y][x] = ch


def fox_walk(frame):
    g = grid(28, 15)
    legs = [[5, 0, "o"], [9, 2, "r"], [16, 2, "r"], [20, 0, "o"]] if frame == 0 else [[5, 2, "r"], [9, 0, "o"], [16, 0, "o"], [20, 2, "r"]]
    for x, lift, col in [l for l in legs if l[2] == "r"] + [l for l in legs if l[2] == "o"]:
        rect(g, x, 11, x + 1, 14 - lift, col)
        rect(g, x, 13 - lift, x + 1, 14 - lift, "k")
    rect(g, 1, 4, 5, 8, "o"); rect(g, 0, 5, 4, 8, "o"); rect(g, 0, 5, 1, 8, "w"); put(g, 0, 5, "."); put(g, 1, 4, ".")
    rect(g, 5, 6, 19, 10, "o"); put(g, 5, 6, "."); put(g, 5, 10, ".")
    rect(g, 7, 10, 17, 10, "r")
    rect(g, 18, 5, 21, 10, "o"); rect(g, 19, 8, 21, 10, "w")
    rect(g, 19, 2, 24, 7, "o")
    rect(g, 19, 0, 20, 1, "o"); rect(g, 23, 0, 24, 1, "o"); put(g, 19, 0, "k"); put(g, 24, 0, "k")
    rect(g, 25, 4, 27, 6, "o"); rect(g, 22, 6, 27, 7, "w"); put(g, 27, 4, "k"); put(g, 27, 5, "k")
    put(g, 23, 3, "k")
    return g


def fox_sleep():
    g = grid(22, 11)
    blob(g, 9, 6, 9, 4, "o")
    rect(g, 3, 9, 16, 10, "o"); put(g, 3, 10, "."); rect(g, 12, 9, 16, 10, "w")
    blob(g, 16.5, 7, 3.6, 3.2, "o")
    rect(g, 14, 2, 15, 4, "o"); put(g, 14, 2, "k"); rect(g, 18, 2, 19, 4, "o"); put(g, 19, 2, "k")
    rect(g, 17, 8, 20, 9, "w"); put(g, 21, 8, "k"); rect(g, 16, 6, 17, 6, "k")
    return g


def duck():
    g = grid(14, 9)
    rect(g, 1, 4, 11, 7, "w"); rect(g, 0, 5, 0, 6, "w"); rect(g, 8, 1, 11, 3, "w"); rect(g, 12, 2, 13, 3, "y")
    put(g, 10, 2, "k"); put(g, 1, 4, "."); rect(g, 3, 6, 8, 6, "y")
    return g


def bird(frame):
    g = grid(16, 11)
    blob(g, 8, 5, 5, 2.6, "B"); rect(g, 6, 6, 10, 7, "w"); blob(g, 12, 4, 2.2, 2.2, "B")
    rect(g, 14, 4, 15, 4, "y"); put(g, 12, 3, "k"); rect(g, 0, 4, 3, 5, "D")
    if frame == 0:
        rect(g, 5, 1, 9, 3, "D"); put(g, 5, 1, "."); put(g, 9, 1, "B"); rect(g, 6, 0, 8, 0, "D")
    else:
        rect(g, 5, 7, 9, 9, "D"); put(g, 5, 9, "."); rect(g, 6, 10, 8, 10, "D")
    return g


def bush(closed):
    w2, h2, cx, cy = 22, 19, 11, 10
    g, r = grid(w2, h2), mulberry(11)

    def inside(x, y):
        return ((x - cx) / 10) ** 2 + ((y - cy) / 8.5) ** 2 <= 1 and y <= 17

    for y in range(h2):
        for x in range(w2):
            if inside(x, y):
                g[y][x] = "V" if y > 13 else "N" if y > 10 else "M"
    for y in range(1, 16, 3):
        for x in range(1 + (y % 2) * 2, w2 - 1, 4):
            lx, ly = x + math.floor(r() * 3) - 1, y + math.floor(r() * 2)
            if not inside(lx, ly):
                continue
            light = "T" if ly < 5 else ("T" if lx < cx + 2 else "A") if ly < 10 else "A" if ly < 13 else "M"
            shade = "M" if ly < 10 else "N"
            for dx, dy in [(0, -1), (-1, 0), (0, 0)]:
                put(g, lx + dx, ly + dy, light)
            for dx, dy in [(1, 0), (0, 1)]:
                if inside(lx + dx, ly + dy):
                    put(g, lx + dx, ly + dy, shade)
    edge, out = [], []
    for y in range(h2):
        for x in range(w2):
            near = []
            for dx, dy in [(1, 0), (-1, 0), (0, 1), (0, -1)]:
                yy, xx = y + dy, x + dx
                near.append(0 <= yy < h2 and 0 <= xx < w2 and g[yy][xx] != ".")
            if g[y][x] != "." and any(not n for n in near):
                edge.append((x, y))
            if g[y][x] == "." and any(near) and y < 16:
                out.append((x, y))
    for x, y in edge:
        if r() < 0.3 and y < 16:
            g[y][x] = "."
    for x, y in out:
        if r() < 0.18:
            g[y][x] = "A" if y < 9 else "M"
    rect(g, 9, 11, 13, 12, "V")
    if closed:
        put(g, 10, 12, "k"); put(g, 12, 12, "k")
    else:
        put(g, 10, 11, "e"); put(g, 12, 11, "e"); put(g, 10, 12, "k"); put(g, 12, 12, "k")
    return g


def outlined(g):
    h, w = len(g) + 2, len(g[0]) + 2
    o = grid(w, h)
    for y, row in enumerate(g):
        for x, ch in enumerate(row):
            o[y + 1][x + 1] = ch
    for y in range(h):
        for x in range(w):
            if o[y][x] != ".":
                continue
            for dx, dy in [(1, 0), (-1, 0), (0, 1), (0, -1)]:
                yy, xx = y + dy, x + dx
                if 0 <= yy < h and 0 <= xx < w and o[yy][xx] not in (".", "O"):
                    o[y][x] = "O"
                    break
    return o


def to32(g, outline=True):
    o = outlined(g) if outline else g
    out = grid(32, 32)
    ox, oy = (32 - len(o[0])) // 2, 32 - len(o)
    for y, row in enumerate(o):
        for x, ch in enumerate(row):
            if 0 <= oy + y < 32 and 0 <= ox + x < 32:
                out[oy + y][ox + x] = ch
    return out


STUB_FOX_PAL = {**PAL, "o": "#3a3a3a", "r": "#2a2a2a", "w": "#8a8a8a"}
STUB_HAT_PAL = {"p": "#e0527a", "q": "#f6eedc", "y": "#e8a23a"}

STUB_HAT = [
    "...yy...",
    "...yy...",
    "..pppp..",
    "..qqqq..",
    ".pppppp.",
    ".qqqqqq.",
    "pppppppp",
    "qqqqqqqq",
]


def hex_rgba(c):
    return tuple(int(c[i:i + 2], 16) for i in (1, 3, 5)) + (255,)


def grid_image(g, pal=PAL):
    im = Image.new("RGBA", (len(g[0]), len(g)), (0, 0, 0, 0))
    for y, row in enumerate(g):
        for x, ch in enumerate(row):
            if ch in pal:
                im.putpixel((x, y), hex_rgba(pal[ch]))
    return im


def save_grid(g, name, pal=PAL):
    grid_image(g, pal).save(OUT / f"{name}.png")


class Canvas:
    def __init__(self, w, h):
        self.im = Image.new("RGBA", (w, h), (0, 0, 0, 0))

    def r(self, x, y, w, h, col):
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                self.im.putpixel((xx, yy), hex_rgba(col))

    def save_cropped(self, name):
        box = self.im.getbbox()
        self.im.crop(box).save(OUT / f"{name}.png")
        return box


def objects():
    wd, lt, dk, iron, x0 = "#8a5a33", "#a87444", "#5a3a20", "#1f2e2a", 14
    bench = Canvas(60, 140)
    for y in (111, 114, 117):
        bench.r(x0 + 3, y, 26, 2, wd); bench.r(x0 + 3, y, 26, 1, lt)
    bench.r(x0 + 3, 121, 26, 2, wd); bench.r(x0 + 3, 121, 26, 1, lt); bench.r(x0 + 3, 123, 26, 1, dk)
    bench.r(x0 + 1, 110, 2, 10, iron); bench.r(x0 + 29, 110, 2, 10, iron)
    bench.r(x0, 120, 4, 1, iron); bench.r(x0, 121, 1, 2, iron); bench.r(x0 + 28, 120, 4, 1, iron); bench.r(x0 + 31, 121, 1, 2, iron)
    bench.r(x0 + 2, 121, 1, 7, iron); bench.r(x0 + 29, 121, 1, 7, iron); bench.r(x0 + 1, 127, 3, 1, iron); bench.r(x0 + 28, 127, 3, 1, iron)
    lamp = Canvas(60, 140)
    lamp.r(4, 125, 6, 3, iron); lamp.r(5, 122, 4, 3, iron); lamp.r(6, 100, 2, 22, iron)
    lamp.r(5, 99, 4, 1, iron); lamp.r(3, 98, 8, 1, iron); lamp.r(3, 92, 1, 6, iron); lamp.r(10, 92, 1, 6, iron)
    lamp.r(4, 92, 6, 6, "#e8d9a0")
    lamp.r(3, 91, 8, 1, iron); lamp.r(4, 90, 6, 1, iron); lamp.r(5, 89, 4, 1, iron); lamp.r(6, 87, 2, 2, iron)
    return bench.save_cropped("bench"), lamp.save_cropped("lamppost")


def legacy():
    save_grid(to32(fox_walk(0)), "fox_walk_1")
    save_grid(to32(fox_walk(1)), "fox_walk_2")
    save_grid(to32(fox_sleep()), "fox_sleep")
    save_grid(to32(duck()), "duck")
    save_grid(to32(bird(0)), "bird_1")
    save_grid(to32(bird(1)), "bird_2")
    save_grid(to32(bush(False), outline=False), "bush")
    save_grid(to32(bush(True), outline=False), "bush_blink")
    save_grid(to32(fox_walk(0)), "stub_fox_1", STUB_FOX_PAL)
    save_grid(to32(fox_walk(1)), "stub_fox_2", STUB_FOX_PAL)
    save_grid([list(r) for r in STUB_HAT], "stub_hat", STUB_HAT_PAL)
    bench_box, lamp_box = objects()
    print("bench box (x0, y0, x1, y1):", bench_box)
    print("lamppost box (x0, y0, x1, y1):", lamp_box)


def dart_art(entries):
    out = [
        "// Generated by tools/make_sprites.py. Do not edit by hand.",
        "import 'catalog.dart';",
        "",
        "class EntryArt {",
        "  const EntryArt({",
        "    required this.frames,",
        "    required this.headPoints,",
        "    this.flyFrames = const [],",
        "    this.flyHeadPoints = const [],",
        "  });",
        "",
        "  final List<String> frames;",
        "  final List<HeadPoint> headPoints;",
        "  final List<String> flyFrames;",
        "  final List<HeadPoint> flyHeadPoints;",
        "}",
        "",
        "const Map<String, EntryArt> entryArt = {",
    ]
    for eid, (grids, _, heads, fly_grids, fly_heads) in entries.items():
        pts = ", ".join(f"(x: {x}, y: {y})" for x, y in heads)
        out += [
            f"  '{eid}': EntryArt(",
            f"    frames: ['{eid}_1', '{eid}_2'],",
            f"    headPoints: [{pts}],",
        ]
        if fly_grids:
            stem = eid if fly_grids is grids else f"{eid}_fly"
            fpts = ", ".join(f"(x: {x}, y: {y})" for x, y in fly_heads)
            out += [
                f"    flyFrames: ['{stem}_1', '{stem}_2'],",
                f"    flyHeadPoints: [{fpts}],",
            ]
        out.append("  ),")
    out += ["};", ""]
    ART_OUT.write_text("\n".join(out))


def discover():
    return {p.stem: p for p in sorted(MODULES.glob("*.py")) if not p.stem.startswith("_")}


def build_base(base_id, tree, path, log):
    try:
        mod = _core.load(path)
        errors, warnings, parsed = _core.validate(mod, base_id, tree[base_id])
    except Exception as e:
        errors, warnings, parsed = [f"{type(e).__name__}: {e}"], [], None
    for w in warnings:
        log(f"WARNING {base_id}: {w}")
    for e in errors:
        log(f"ERROR {base_id}: {e}")
    if parsed is None:
        return None
    entries = _core.render_base(parsed, mod)
    order = [e for s, cs in tree[base_id]["shapes"].items() for e in [s, *cs]] + tree[base_id]["legends"]
    entries = {e: entries[e] for e in order if e in entries}
    seen = {}
    for eid, (grids, pal, *_) in entries.items():
        key = tuple(tuple(pal.get(c) for row in g for c in row) for g in grids)
        if key in seen:
            log(f"WARNING {base_id}: {eid} renders identically to {seen[key]}")
        seen.setdefault(key, eid)
    for eid, (grids, pal, _, fly_grids, _) in entries.items():
        for n, g in enumerate(grids, 1):
            save_grid(g, f"{eid}_{n}", pal)
        if fly_grids and fly_grids is not grids:
            for n, g in enumerate(fly_grids, 1):
                save_grid(g, f"{eid}_fly_{n}", pal)
    log(f"{base_id}: wrote {len(entries)} of {len(order)} entries")
    return entries


def build_hats(path, log):
    try:
        mod = _core.load(path)
        errors, warnings, hats = _core.validate_hats(mod, [h for h, _ in gen_catalog.HATS])
    except Exception as e:
        errors, warnings, hats = [f"{type(e).__name__}: {e}"], [], None
    for w in warnings:
        log(f"WARNING hats: {w}")
    for e in errors:
        log(f"ERROR hats: {e}")
    if hats is None:
        return None
    out = {}
    for hid, rows in hats.items():
        g, pal = _core.render_hat(rows, mod.PALETTE)
        save_grid(g, f"hat_{hid}", pal)
        out[hid] = (g, pal)
    log(f"hats: wrote {len(out)} of {len(gen_catalog.HATS)}")
    return out


SCALE = 4
PER_ROW = 5
GREY, MEADOW, PAGE, INK, MARK = (216, 216, 216), (95, 154, 74), (246, 246, 246), (30, 30, 30), (255, 42, 109)


def font(size, bold=False):
    name = "DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"
    try:
        return ImageFont.truetype("/usr/share/fonts/truetype/dejavu/" + name, size)
    except OSError:
        return ImageFont.load_default(size)


def scaled(g, pal):
    return grid_image(g, pal).resize((len(g[0]) * SCALE, len(g) * SCALE), Image.NEAREST)


def sheet(sections, path):
    pad, frame_w = 8, 32 * SCALE
    cell_w = 2 * frame_w + 3 * pad
    band_h = frame_w + pad
    cell_h = 22 + 2 * band_h + pad
    rows_h = [28 + -(-len(items) // PER_ROW) * cell_h for _, items in sections]
    im = Image.new("RGB", (PER_ROW * cell_w + pad, sum(rows_h) + pad), PAGE)
    d = ImageDraw.Draw(im)
    f_head, f_label = font(16, True), font(13)
    top = pad
    for (title, items), h in zip(sections, rows_h):
        d.text((pad, top + 4), title, fill=INK, font=f_head)
        for i, (label, frames) in enumerate(items):
            cx = pad + (i % PER_ROW) * cell_w
            cy = top + 28 + (i // PER_ROW) * cell_h
            d.text((cx + pad, cy + 2), label, fill=INK, font=f_label)
            for b, bg in enumerate((GREY, MEADOW)):
                by = cy + 22 + b * band_h
                d.rectangle([cx + pad // 2, by, cx + cell_w - pad - 1, by + band_h - 1], fill=bg)
                for n, (g, pal, head) in enumerate(frames):
                    fx, fy = cx + pad + n * (frame_w + pad), by + pad // 2
                    sp = scaled(g, pal)
                    im.paste(sp, (fx, fy), sp)
                    if b == 1 and head:
                        hx, hy = fx + head[0] * SCALE, fy + head[1] * SCALE
                        d.rectangle([hx + 1, hy + 1, hx + 2, hy + 2], fill=MARK)
        top += h
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path)


def stub_frames():
    return [(to32(fox_walk(f)), STUB_FOX_PAL, None) for f in (0, 1)]


def sheet_sections(tree, built, hats, only):
    sections = []
    for base_id, info in tree.items():
        if only and only != base_id:
            continue
        got = built.get(base_id) or {}
        order = [e for s, cs in info["shapes"].items() for e in [s, *cs]] + info["legends"]
        items = []
        for eid in order:
            if eid in got:
                grids, pal, heads, fly_grids, fly_heads = got[eid]
                items.append((eid, [(g, pal, h) for g, h in zip(grids, heads)]))
                if fly_grids and fly_grids is not grids:
                    items.append((f"{eid} fly", [(g, pal, h) for g, h in zip(fly_grids, fly_heads)]))
            else:
                items.append((f"{eid} (stub)", stub_frames()))
        sections.append((f"{info['name']} ({base_id}): {len(got)}/{len(order)} drawn", items))
    if hats and (not only or only == "hats"):
        sections.append(("Hats", [(hid, [(g, pal, None)]) for hid, (g, pal) in hats.items()]))
    return sections


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", help="a base id (e.g. fox) or 'hats': build and report just that")
    ap.add_argument("--sheet", type=Path, help="contact sheet path")
    args = ap.parse_args()
    tree = gen_catalog.entry_tree()
    if args.only and args.only != "hats" and args.only not in tree:
        sys.exit(f"unknown base {args.only!r}; bases: {', '.join(tree)}")
    sheet_path = args.sheet or SHEET_DIR / (f"sheet_{args.only}.png" if args.only else "sheet.png")
    problems = []

    def log(msg):
        print(msg)
        if msg.startswith("ERROR"):
            problems.append(msg)

    OUT.mkdir(parents=True, exist_ok=True)
    if not args.only:
        legacy()
    modules = discover()
    for name in modules:
        if name != "hats" and name not in tree:
            log(f"ERROR {name}: tools/sprites/{name}.py is not a base id in docs/animals.md")
    built, hats = {}, {}
    for base_id in tree:
        if args.only and args.only != base_id:
            continue
        if base_id not in modules:
            log(f"{base_id}: no module, using the stub art")
            continue
        entries = build_base(base_id, tree, modules[base_id], log)
        if entries is not None:
            built[base_id] = entries
    if "hats" in modules and (not args.only or args.only == "hats"):
        hats = build_hats(modules["hats"], log) or {}
    if args.only == "hats" and "hats" not in modules:
        log("ERROR hats: tools/sprites/hats.py does not exist")
    if not args.only:
        dart_art({e: v for b in built.values() for e, v in b.items()})
    sheet(sheet_sections(tree, built, hats, args.only), sheet_path)
    print("sheet:", sheet_path)
    sys.exit(1 if problems else 0)


if __name__ == "__main__":
    main()
