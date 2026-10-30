"""Builds the sprite review page from the PNGs on disk and the judge results.

python3 tools/review_page.py --done fox cat ... [--working dog ...] [--results build/sprites/results.json]
"""
import argparse
import base64
import html
import io
import json
import sys
from pathlib import Path
from PIL import Image

TOOLS = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOLS))
sys.path.insert(0, str(TOOLS / "sprites"))

import _core  # noqa: E402
import gen_catalog  # noqa: E402
import make_sprites  # noqa: E402
import review_sprites  # noqa: E402

SPRITES = make_sprites.OUT
BUILD = make_sprites.ROOT / "build/sprites"

STYLE = """
/* Layout: one reading column of base sections, each a wrapping grid of sprite cards on a meadow-green stage. */
:root {
  --bg: #edf1ea; --fg: #2e2218; --muted: #66705f; --panel: #f8faf5; --line: #cfd8c8;
  --accent: #c4621f; --meadow: #5f994a; --meadow-dark: #4d8540;
  --ok: #2f7a3a; --bad: #b3361f; --warn: #9a6a00;
  --display: "Tiny5", "Courier New", monospace;
  --body: "Atkinson Hyperlegible", system-ui, sans-serif;
}
@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) {
  --bg: #121820; --fg: #ebe6d9; --muted: #98a19a; --panel: #1b232d; --line: #2c3743;
  --accent: #e88a47; --ok: #6cc27a; --bad: #f07a63; --warn: #e0b04a; color-scheme: dark } }
:root[data-theme="dark"] {
  --bg: #121820; --fg: #ebe6d9; --muted: #98a19a; --panel: #1b232d; --line: #2c3743;
  --accent: #e88a47; --ok: #6cc27a; --bad: #f07a63; --warn: #e0b04a; color-scheme: dark }
body { background: var(--bg); color: var(--fg); font: 16px/1.5 var(--body);
  padding-block: 28px 72px; padding-left: max(16px, env(safe-area-inset-left, 0px)); padding-right: max(16px, env(safe-area-inset-right, 0px)); }
main { max-width: 1120px; margin: 0 auto; display: grid; gap: 36px; }
h1, h2 { font-family: var(--display); font-weight: 400; margin: 0; text-wrap: balance; letter-spacing: 0.02em; }
h1 { font-size: clamp(30px, 6vw, 46px); line-height: 1.05; }
h2 { font-size: 26px; }
h4 { margin: 0; font-size: 16px; }
header { display: grid; gap: 12px; }
.lede { margin: 0; max-width: 68ch; }
.muted { color: var(--muted); }
.stats { display: flex; flex-wrap: wrap; gap: 8px 24px; font-variant-numeric: tabular-nums; color: var(--muted); }
.stats b { color: var(--fg); font-family: var(--display); font-weight: 400; font-size: 22px; margin-right: 4px; }
nav { display: flex; flex-wrap: wrap; gap: 8px; }
nav a { color: var(--fg); text-decoration: none; border: 1px solid var(--line); padding: 3px 10px; border-radius: 3px; font-size: 14px; }
nav a:hover, nav a:focus-visible { border-color: var(--accent); outline: none; }
.test { border-left: 3px solid var(--accent); padding: 4px 0 4px 14px; display: grid; gap: 6px; }
.test p { margin: 0; max-width: 72ch; }
section { display: grid; gap: 14px; scroll-margin-top: 16px; }
.head { display: flex; align-items: baseline; flex-wrap: wrap; gap: 10px; border-bottom: 2px solid var(--fg); padding-bottom: 6px; }
.count { color: var(--muted); font-size: 14px; margin-left: auto; font-variant-numeric: tabular-nums; }
.chip { font-size: 12px; text-transform: uppercase; letter-spacing: 0.08em; padding: 1px 8px; border-radius: 3px; border: 1px solid currentColor; }
.chip.done { color: var(--ok); } .chip.working { color: var(--warn); } .chip.todo { color: var(--muted); }
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(230px, 1fr)); gap: 14px; }
.card { background: var(--panel); border: 1px solid var(--line); display: grid; grid-template-rows: auto 1fr; min-width: 0; }
.stage { background: var(--meadow); display: flex; justify-content: center; align-items: flex-end; gap: 6px; padding: 10px 8px 0; border-bottom: 4px solid var(--meadow-dark); }
.stage img { width: 96px; height: 96px; image-rendering: pixelated; display: block; }
.stage.tall img { width: 64px; height: auto; }
.stage.tall img.solo { align-self: center; width: auto; height: auto; transform: scale(3); transform-origin: center; margin: 0 22px; image-rendering: pixelated; }
.meta { padding: 10px 12px 12px; display: grid; gap: 4px; align-content: start; min-width: 0; }
.tag { font-size: 12px; color: var(--accent); }
.note { margin: 0; font-size: 14px; color: var(--muted); }
.verdict { margin: 4px 0 0; font-size: 13px; padding-left: 8px; border-left: 3px solid currentColor; }
.verdict.pass { color: var(--ok); } .verdict.fail { color: var(--bad); } .verdict.maybe { color: var(--warn); }
.verdict b { color: var(--fg); }
details { border: 1px solid var(--line); background: var(--panel); padding: 8px 12px; }
summary { cursor: pointer; }
.sheet { image-rendering: pixelated; margin-top: 10px; display: block; }
"""


def uri(im):
    buf = io.BytesIO()
    im.save(buf, "PNG")
    return "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()


def png_uri(name):
    p = SPRITES / f"{name}.png"
    return uri(Image.open(p)) if p.exists() else None


def esc(s):
    return html.escape(s, quote=True)


def card(eid, name, note, shape_name, result, drawn, legend=False):
    f1 = png_uri(f"{eid}_1" if drawn else "stub_fox_1")
    f2 = png_uri(f"{eid}_2" if drawn else "stub_fox_2")
    kind = f'<span class="tag">colour of {esc(shape_name)}</span>' if shape_name else ""
    if legend:
        kind = '<span class="tag">legend</span>' if drawn else '<span class="tag">legend, not drawn yet</span>'
    verdict = ""
    if result:
        cls = {True: "pass", False: "fail"}.get(result.get("ok"), "maybe")
        verdict = f'<p class="verdict {cls}"><b>Judge:</b> {esc(result.get("said", ""))}</p>'
    return f"""<article class="card">
  <div class="stage"><img src="{f1}" alt="{esc(name)}, frame 1"><img src="{f2}" alt="{esc(name)}, frame 2"></div>
  <div class="meta"><h4>{esc(name)}</h4>{kind}<p class="note">{esc(note)}</p>{verdict}</div>
</article>"""


def hats_section():
    mods = make_sprites.discover()
    if "hats" not in mods or "fox" not in mods:
        return ""
    tree = gen_catalog.entry_tree()
    fox = _core.load(mods["fox"])
    _, _, parsed = _core.validate(fox, "fox", tree["fox"])
    hx, hy = _core.render_base(parsed, fox)["red-fox"][2][0]
    cells = []
    for hid, hname in gen_catalog.HATS:
        hp = SPRITES / f"hat_{hid}.png"
        if not hp.exists():
            continue
        hat = Image.open(hp).convert("RGBA")
        im = Image.open(SPRITES / "red-fox_1.png").convert("RGBA")
        right = review_sprites.with_hat(im, hat, hx, hy)
        left = review_sprites.with_hat(im.transpose(Image.FLIP_LEFT_RIGHT), hat.transpose(Image.FLIP_LEFT_RIGHT), 31 - hx, hy)
        cells.append(f"""<article class="card hat">
  <div class="stage tall"><img class="solo" src="{uri(hat)}" alt="{esc(hname)}"><img src="{uri(right)}" alt="{esc(hname)} on a fox"><img src="{uri(left)}" alt="{esc(hname)} on a fox facing left"></div>
  <div class="meta"><h4>{esc(hname)}</h4><p class="note">{hat.width}×{hat.height} px with outline</p></div>
</article>""")
    sheet = BUILD / "hats_on_bases.png"
    extra = ""
    if sheet.exists():
        extra = f'<details><summary>Every hat on every drawn base, both frames, right and left</summary><img class="sheet" src="{uri(Image.open(sheet))}" alt="Hats on every base"></details>'
    return f"""<section id="hats"><div class="head"><h2>Hats</h2><span class="chip done">drawn</span></div>
<p class="lede">Worn on a day off. The hat's bottom-centre pixel sits on the animal's head point.</p>
<div class="grid">{''.join(cells)}</div>{extra}</section>"""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--done", nargs="*", default=[])
    ap.add_argument("--working", nargs="*", default=[])
    ap.add_argument("--results", type=Path, default=BUILD / "results.json")
    ap.add_argument("--out", type=Path, default=BUILD / "review.html")
    args = ap.parse_args()
    tree = gen_catalog.entry_tree()
    names = review_sprites.entry_names()
    notes = gen_catalog.note_rows()
    results = json.loads(args.results.read_text()) if args.results.exists() else {}
    sections, total, drawn = [], 0, 0
    for bid, base in tree.items():
        done = bid in args.done
        status = ("done", "drawn") if done else (("working", "being drawn") if bid in args.working else ("todo", "not started"))
        cards = []
        for shape, colours in base["shapes"].items():
            for eid in [shape, *colours]:
                total += 1
                drawn += done
                cards.append(card(eid, names[eid], notes[eid], names[shape] if eid != shape else None, results.get(eid), done))
        for lid in base["legends"]:
            total += 1
            art = (SPRITES / f"{lid}_1.png").exists()
            drawn += art
            cards.append(card(lid, names[lid], notes[lid], None, results.get(lid), art, legend=True))
        count = sum(1 + len(c) for c in base["shapes"].values()) + len(base["legends"])
        body = f'<div class="grid">{"".join(cards)}</div>' if done else '<p class="lede muted">Shown once the artist finishes.</p>'
        sections.append(f"""<section id="{bid}"><div class="head"><h2>{esc(base['name'])}</h2><span class="chip {status[0]}">{status[1]}</span><span class="count">{count} entries</span></div>
{body}</section>""")
    nav = "".join(f'<a href="#{b}">{esc(tree[b]["name"])}</a>' for b in tree) + '<a href="#hats">Hats</a>'
    test = results.get("test", "")
    page = f"""<title>WildKaki Sprite Review</title>
<meta name="claude:viewport-fit-sides" content="cover">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Tiny5&family=Atkinson+Hyperlegible:wght@400;700&display=swap">
<style>{STYLE}</style>
<main>
<header>
  <h1>WildKaki Sprite Review</h1>
  <p class="lede">Every base and the hats as they come off the drawing board. Each card shows the two walk frames at 3× on meadow green, as they will appear in the scene, with the card note underneath.</p>
  <div class="stats"><span><b>{drawn}</b>of {total} entries drawn</span><span><b>{sum(b in args.done for b in tree)}</b>of {len(tree)} bases</span></div>
  <nav>{nav}</nav>
  {f'<div class="test"><h4>Recognition test</h4><p>{test}</p></div>' if test else ''}
</header>
{''.join(sections)}{hats_section()}
</main>
"""
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(page)
    print(args.out, f"{drawn}/{total} drawn")


if __name__ == "__main__":
    main()
