"""Writes every WildKaki sprite and scene object as its own PNG.

Animals are drawn on a fixed 32x32 canvas with their feet on the bottom row and are
all right-facing; the app mirrors them for left-facing. Objects are cropped to their
own size. Run from the repo root: python3 tools/make_sprites.py
"""
import math
from pathlib import Path
from PIL import Image

OUT = Path(__file__).resolve().parent.parent / "assets/sprites"

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


def save_grid(g, name, pal=PAL):
    im = Image.new("RGBA", (len(g[0]), len(g)), (0, 0, 0, 0))
    for y, row in enumerate(g):
        for x, ch in enumerate(row):
            if ch in pal:
                im.putpixel((x, y), hex_rgba(pal[ch]))
    im.save(OUT / f"{name}.png")


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


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
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
