# Sprite modules

One file per base: `tools/sprites/<base-id>.py` (ids from docs/animals.md: `dog cat fox hare mustelid small-deer squirrel songbird waterfowl otter lizard owl bat mouse hedgehog`). Copy `fox.py`; never edit `_core.py` or `make_sprites.py`.

```python
FRAMES = [[rows of frame 1], [rows of frame 2]]   # walk cycle, text grids
SPECIES = {"red-fox": {"palette": {"b": "#d9772f", ...}},                 # base drawing
           "fennec": {"palette": {...}, "patches": [(None, 17, -4, ["..", ".."])]}}
COLOURS = {"silver-fox": {"b": "#6c7079"}}         # overrides of its shape species' palette
```

- Grid: list of equal-length strings, at most 30x30, both frames the same width. `.` is empty, a letter is a colour role, `H` is the head marker (drawn as role `b`; exactly one per frame).
- Placement is automatic: the 1px outline (`#2e2218`) is added, the art is centred horizontally and bottom-aligned, so the last grid row sits on canvas row 30 and its outline on row 31. Draw only the unoutlined art.
- Patches: `(frame, x, y, rows)`. `frame` is `0`, `1` or `None` (both). `x, y` is the top-left in grid coordinates and may lie outside the grid (negative y is above the head), as long as it stays inside the art area. In `rows`, `.` keeps the pixel, `-` erases it, a letter paints it. A single-letter string paints one pixel.
- Every role used in the art needs a colour in each palette. Colour species list only the roles that change, and must differ from their shape species.
- Hats: `tools/sprites/hats.py` exposes `PALETTE` and `HATS = {"party-hat": rows, ...}`; odd width, at most 15x15, outline added. The bottom-centre pixel of `hat_<id>.png` (x = width // 2, y = height - 1) is drawn on the base's head point.

## Flying frames (optional)

A base for animals that also fly (the songbird) may define `FLY = [wings_up, wings_down]`, two patch lists. Each entry of the base then gets `<id>_fly_1.png` and `<id>_fly_2.png`, and `art_data.dart` lists them as `flyFrames` and `flyHeadPoints` (empty for bases without `FLY`).

- Each fly frame is the species' rendered standing frame 0 (its own patches included, the hop frame is not used), then the `FLY` list for that frame, then the species' own `"fly"` patches. Colour species inherit the fly frames of their shape species.
- A `FLY` item is `(x, y, rows)` (same row characters as patches, so legs can be erased with `-` and wings painted in the species' own roles) or `("move", x, y, w, h, dx, dy)`, which cuts that region and pastes it `dx, dy` away, or `("clear", x, y, w, h, roles)`, which erases only the pixels of those role letters inside the region (for legs). A head marker `H` inside a moved region moves with it; an `H` in a patch sets the head point.
- A species' `"fly": [(frame, x, y, rows), ...]` uses the usual patch form, `frame` being the fly frame (`0`, `1` or `None`). It touches up one species, e.g. a long tail or a beak.
- `"fly": "same"` marks art that already shows the animal in flight (full redraws like the legends): its standing frames and head points double as its fly frames and no `_fly_` PNGs are written.
- Every role used in `FLY` needs a colour in each species' palette.

## Roles (use these so bases look alike)

`b` body, `d` shade (belly line, far limbs, back), `l` light (belly, muzzle, tail tip), `a` accent (inner ear, markings), `k` dark extremities (paws, ear tips), `e` eye, `n` nose, `p` pink, `y` beak or feet, `w` white highlight. Any other letter except `H O` works if it is in the palette.

## Rules

- Right-facing, feet on the bottom row, fox-sized or smaller (the fox grid is 28x15).
- A shape species is the base drawing plus its own palette plus the patches it needs to be recognised (ears, tail, markings, body shape). A colour species is a palette swap only.
- Check recognition blind: `python3 tools/review_sprites.py blind --out <dir>` writes unlabelled, shuffled sheets and their answer keys (keep the keys away from whoever judges).
- Head point: the `H` cell, on the top of the head between the ears, in both frames. Keep it still unless the head moves. A species whose head sits elsewhere (a long neck) puts one `H` in a later patch to move its own head point; a patch `H` keeps the pixel under it as drawn.
- Fill every id the doc lists for the base. Typos are errors; missing ids are warnings and keep the stub art.

## Run

```
python3 tools/make_sprites.py --only fox     # your base only: PNGs, checks, sheet_fox.png
python3 tools/make_sprites.py                # everything, also rewrites lib/animals/art_data.dart
```

The sheet shows each entry on grey and on meadow green (the red dot marks the head point). Default path: `build/sprites/` (not committed); override with `--sheet <path>`. The sheet is for you to look at: view it before you finish.
