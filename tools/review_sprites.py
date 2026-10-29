"""Review sheets for the animal sprites: blind sheets for an identification test, and hats on every base.

Run from the repo root after make_sprites.py:
  python3 tools/review_sprites.py blind --out <dir> [base ...]
  python3 tools/review_sprites.py hats --out <dir> [base ...]
"""
import argparse
import json
import random
import sys
from pathlib import Path
from PIL import Image, ImageDraw

TOOLS = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOLS))
sys.path.insert(0, str(TOOLS / "sprites"))

import _core  # noqa: E402
import gen_catalog  # noqa: E402
import make_sprites  # noqa: E402

SCALE = 6
MEADOW = (95, 153, 74, 255)
GREY = (215, 215, 215, 255)
INK = (30, 30, 30, 255)


def drawn_bases(only):
    tree = gen_catalog.entry_tree()
    modules = make_sprites.discover()
    bases = [b for b in tree if b in modules and (not only or b in only)]
    return tree, modules, bases


def entry_names():
    names = {}
    for line in gen_catalog.NOTES_DOC.read_text().splitlines():
        c = gen_catalog.cells(line) if line.startswith("|") else []
        if len(c) == 3 and c[0] != "Id" and not set(c[0]) <= {"-", ":"}:
            names[c[0]] = c[1]
    return names


def png(eid, n=1):
    return Image.open(make_sprites.OUT / f"{eid}_{n}.png").convert("RGBA")


def silhouette(im):
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out.putdata([INK if p[3] else (0, 0, 0, 0) for p in im.getdata()])
    return out


def tile(im, bg):
    t = Image.new("RGBA", (im.width * SCALE, im.height * SCALE), bg)
    big = im.resize(t.size, Image.NEAREST)
    t.alpha_composite(big)
    return t


def grid_sheet(cells, cols, path):
    pad, label_h = 10, 22
    w, h = cells[0][1].width, cells[0][1].height
    rows = (len(cells) + cols - 1) // cols
    sheet = Image.new("RGBA", (pad + cols * (w + pad), pad + rows * (h + label_h + pad)), (250, 250, 250, 255))
    d = ImageDraw.Draw(sheet)
    f = make_sprites.font(18, bold=True)
    for i, (label, im) in enumerate(cells):
        x = pad + (i % cols) * (w + pad)
        y = pad + (i // cols) * (h + label_h + pad)
        d.text((x, y), label, fill=INK, font=f)
        sheet.alpha_composite(im, (x, y + label_h))
    sheet.save(path)


def blind_cells(entries, seed):
    order = entries[:]
    random.Random(seed).shuffle(order)
    cells, key = [], {}
    for n, eid in enumerate(order, 1):
        im = png(eid)
        both = Image.new("RGBA", (im.width * SCALE * 2 + SCALE, im.height * SCALE), (250, 250, 250, 255))
        both.alpha_composite(tile(im, MEADOW), (0, 0))
        both.alpha_composite(tile(silhouette(im), GREY), (im.width * SCALE + SCALE, 0))
        cells.append((f"#{n}", both))
        key[n] = eid
    return cells, key


def blind(out, only, seed=""):
    tree, _, bases = drawn_bases(only)
    out.mkdir(parents=True, exist_ok=True)
    names = entry_names()
    shapes = [s for b in bases for s in tree[b]["shapes"]]
    cells, key = blind_cells(shapes, seed + "mix:" + ",".join(bases))
    grid_sheet(cells, 4, out / "blind_mix.png")
    (out / "key_mix.json").write_text(json.dumps(key, indent=1))
    print(out / "blind_mix.png", f"({len(cells)} shape species, all bases mixed)")
    for b in bases:
        entries = [e for s, cs in tree[b]["shapes"].items() for e in [s, *cs]]
        cells, key = blind_cells(entries, seed + "base:" + b)
        grid_sheet(cells, 4, out / f"blind_{b}.png")
        (out / f"key_{b}.json").write_text(json.dumps(key, indent=1))
        choices = ", ".join(names.get(e, e) for e in sorted(entries))
        print(out / f"blind_{b}.png", f"choices: {choices}")


def with_hat(im, hat, hx, hy, pad=4):
    canvas = Image.new("RGBA", (im.width + 2 * pad, im.height + hat.height), (0, 0, 0, 0))
    canvas.alpha_composite(im, (pad, hat.height))
    canvas.alpha_composite(hat, (pad + hx - hat.width // 2, hy + 1))
    return canvas.crop((0, hat.height - 8, canvas.width, canvas.height))


def hats(out, only):
    tree, modules, bases = drawn_bases(only)
    out.mkdir(parents=True, exist_ok=True)
    mod = _core.load(modules["hats"])
    pal = getattr(mod, "PALETTE", {})
    hat_imgs = {}
    for hid, rows in getattr(mod, "HATS", {}).items():
        g, p = _core.render_hat(rows, pal)
        hat_imgs[hid] = make_sprites.grid_image(g, p)
    rows = []
    for b in bases:
        bmod = _core.load(modules[b])
        _, _, parsed = _core.validate(bmod, b, tree[b])
        if parsed is None:
            continue
        rendered = _core.render_base(parsed, bmod)
        shapes = [e for e in tree[b]["shapes"] if e in rendered]
        own = [e for e in shapes[1:] if rendered[e][2] != rendered[shapes[0]][2]]
        for eid in shapes[:1] + own:
            heads = rendered[eid][2]
            for hid, hat in hat_imgs.items():
                frames = []
                for n in (0, 1):
                    im = png(eid, n + 1)
                    hx, hy = heads[n]
                    right = with_hat(im, hat, hx, hy)
                    left = with_hat(im.transpose(Image.FLIP_LEFT_RIGHT), hat.transpose(Image.FLIP_LEFT_RIGHT), 31 - hx, hy)
                    frames += [right, left]
                fw, fh = frames[0].width * SCALE // 2, frames[0].height * SCALE // 2
                strip = Image.new("RGBA", (4 * fw + 3 * SCALE, fh), MEADOW)
                for i, f in enumerate(frames):
                    strip.alpha_composite(f.resize((fw, fh), Image.NEAREST), (i * (fw + SCALE), 0))
                rows.append((f"{b} / {eid} / {hid}", strip))
    if rows:
        grid_sheet(rows, 2, out / "hats_on_bases.png")
        print(out / "hats_on_bases.png")
    else:
        print("no hats or no bases drawn yet")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("mode", choices=["blind", "hats"])
    ap.add_argument("bases", nargs="*")
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--seed", default="", help="blind only: a different seed gives a different shuffle")
    args = ap.parse_args()
    if args.mode == "blind":
        blind(args.out, set(args.bases), args.seed)
    else:
        hats(args.out, set(args.bases))


if __name__ == "__main__":
    main()
