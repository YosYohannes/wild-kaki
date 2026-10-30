"""Loads, validates and renders the per-base sprite modules in tools/sprites."""
import importlib.util
import re
from pathlib import Path

OUTLINE = "#2e2218"
SIZE = 32
MAX_ART = SIZE - 2
EMPTY, HEAD, ERASE = ".", "H", "-"
RESERVED = {EMPTY, HEAD, ERASE, "O"}
HEX = re.compile(r"^#[0-9a-fA-F]{6}$")
SPECIES_KEYS = {"palette", "patches", "fly"}
MOVE = "move"
SAME = "same"
MAX_HAT = 15


def load(path):
    spec = importlib.util.spec_from_file_location("sprites_" + re.sub(r"\W", "_", Path(path).stem), path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def is_role(ch):
    return len(ch) == 1 and ch.isascii() and ch.isalpha() and ch not in RESERVED


def check_rows(rows, where, errors, allow=()):
    if not isinstance(rows, (list, tuple)) or not rows or not all(isinstance(r, str) for r in rows):
        errors.append(f"{where}: must be a non-empty list of strings")
        return False
    ok = True
    for y, row in enumerate(rows):
        if len(row) != len(rows[0]):
            errors.append(f"{where}: row {y} has width {len(row)}, row 0 has {len(rows[0])} (ragged)")
            ok = False
        for x, ch in enumerate(row):
            if not (is_role(ch) or ch in allow):
                errors.append(f"{where}: bad character {ch!r} at x={x} y={y}")
                ok = False
    return ok


def check_palette(pal, where, errors):
    if not isinstance(pal, dict):
        errors.append(f"{where}: palette must be a dict of role -> '#rrggbb'")
        return False
    ok = True
    for role, col in pal.items():
        if not is_role(role):
            errors.append(f"{where}: bad role letter {role!r} (one letter, not '.', 'H', '-', 'O')")
            ok = False
        if not (isinstance(col, str) and HEX.match(col)):
            errors.append(f"{where}: colour for role {role!r} must look like '#rrggbb', got {col!r}")
            ok = False
    return ok


def check_frames(mod, errors):
    frames = getattr(mod, "FRAMES", None)
    if not isinstance(frames, (list, tuple)) or len(frames) != 2:
        errors.append("FRAMES: must be a list of exactly two grids")
        return False
    ok = True
    for i, rows in enumerate(frames):
        where = f"FRAMES[{i}]"
        if not check_rows(rows, where, errors, allow=(HEAD, EMPTY)):
            ok = False
            continue
        w, h = len(rows[0]), len(rows)
        if w > MAX_ART or h > MAX_ART:
            errors.append(f"{where}: {w}x{h} is larger than {MAX_ART}x{MAX_ART} (the outline adds 1px each side)")
            ok = False
        heads = sum(r.count(HEAD) for r in rows)
        if heads != 1:
            errors.append(f"{where}: needs exactly one 'H' head marker, found {heads}")
            ok = False
        if all(ch == EMPTY for ch in rows[-1]):
            errors.append(f"{where}: the bottom row is empty; the feet must be on the last row")
            ok = False
    if ok and len(frames[0][0]) != len(frames[1][0]):
        errors.append(f"FRAMES: both frames must have the same width ({len(frames[0][0])} vs {len(frames[1][0])})")
        ok = False
    return ok


def patch_list(sp, where, errors, key="patches"):
    patches = sp.get(key, [])
    out = []
    if not isinstance(patches, (list, tuple)):
        errors.append(f"{where}: {key} must be a list of (frame, x, y, rows)")
        return out
    for i, p in enumerate(patches):
        w = f"{where}.{key}[{i}]"
        if not (isinstance(p, (list, tuple)) and len(p) == 4):
            errors.append(f"{w}: must be (frame, x, y, rows)")
            continue
        frame, x, y, rows = p
        if isinstance(rows, str):
            rows = [rows]
        if frame not in (None, 0, 1):
            errors.append(f"{w}: frame must be None, 0 or 1, got {frame!r}")
            continue
        if not (isinstance(x, int) and isinstance(y, int)):
            errors.append(f"{w}: x and y must be integers")
            continue
        if check_rows(rows, w, errors, allow=(EMPTY, ERASE, HEAD)):
            out.append((frame, x, y, list(rows), w))
    return out


def fly_list(parts, where, errors):
    out = []
    if not isinstance(parts, (list, tuple)):
        errors.append(f"{where}: must be a list of (x, y, rows) or ('move', x, y, w, h, dx, dy)")
        return out
    for i, p in enumerate(parts):
        w = f"{where}[{i}]"
        if isinstance(p, (list, tuple)) and p and p[0] == MOVE:
            if len(p) == 7 and all(isinstance(v, int) for v in p[1:]) and p[3] > 0 and p[4] > 0:
                out.append((MOVE, *p[1:], w))
            else:
                errors.append(f"{w}: a move is ('move', x, y, w, h, dx, dy) with integers and w, h > 0")
            continue
        if not (isinstance(p, (list, tuple)) and len(p) == 3):
            errors.append(f"{w}: must be (x, y, rows) or ('move', x, y, w, h, dx, dy)")
            continue
        x, y, rows = p
        if isinstance(rows, str):
            rows = [rows]
        if not (isinstance(x, int) and isinstance(y, int)):
            errors.append(f"{w}: x and y must be integers")
            continue
        if check_rows(rows, w, errors, allow=(EMPTY, ERASE, HEAD)):
            out.append((None, x, y, list(rows), w))
    return out


def fly_list_checked(mod, errors):
    fly = getattr(mod, "FLY", None)
    if fly is None:
        return None
    if not isinstance(fly, (list, tuple)) or len(fly) != 2:
        errors.append("FLY: must be a list of exactly two patch lists (wings up, wings down)")
        return None
    return [fly_list(fly[i], f"FLY[{i}]", errors) for i in (0, 1)]


def origin(width, height):
    return (MAX_ART - width) // 2 + 1, SIZE - 1 - height


def check_patch_bounds(patches, frames, errors):
    ox, oy = origin(len(frames[0][0]), len(frames[0]))
    for p in patches:
        w = p[-1]
        if p[0] == MOVE:
            _, x, y, pw, ph, dx, dy, _ = p
            boxes = [(x, y, pw, ph), (x + dx, y + dy, pw, ph)]
        else:
            boxes = [(p[1], p[2], len(p[3][0]), len(p[3]))]
        for bx, by, bw, bh in boxes:
            check_box(ox, oy, bx, by, bw, bh, w, errors)


def check_box(ox, oy, x, y, pw, ph, w, errors):
    x0, y0, x1, y1 = ox + x, oy + y, ox + x + pw - 1, oy + y + ph - 1
    if x0 < 1 or y0 < 1 or x1 > SIZE - 2 or y1 > SIZE - 2:
        errors.append(f"{w}: pixels fall outside the art area (grid x {1 - ox}..{SIZE - 2 - ox}, y {1 - oy}..{SIZE - 2 - oy})")


def used_roles(frames, patches):
    roles = {"b"}
    for rows in frames:
        roles |= {ch for r in rows for ch in r if is_role(ch)}
    for p in patches:
        if p[0] != MOVE:
            roles |= {ch for r in p[3] for ch in r if is_role(ch)}
    return roles


def validate(mod, base_id, tree):
    errors, warnings = [], []
    if not check_frames(mod, errors):
        return errors, warnings, None
    frames = [list(f) for f in mod.FRAMES]
    fly = fly_list_checked(mod, errors)
    if getattr(mod, "FLY", None) is not None and fly is not None:
        for part in fly:
            check_patch_bounds(part, frames, errors)
    species = getattr(mod, "SPECIES", None)
    colours = getattr(mod, "COLOURS", {})
    if not isinstance(species, dict):
        errors.append("SPECIES: must be a dict of shape-species-id -> {'palette': {...}, 'patches': [...]}")
        return errors, warnings, None
    if not isinstance(colours, dict):
        errors.append("COLOURS: must be a dict of colour-species-id -> {role: '#rrggbb'}")
        return errors, warnings, None
    shapes = {**tree["shapes"], **{lid: [] for lid in tree.get("legends", [])}}
    colour_parent = {c: s for s, cs in shapes.items() for c in cs}
    for sid in species:
        if sid not in shapes:
            hint = " (it is a colour species in docs/animals.md: put it in COLOURS)" if sid in colour_parent else ""
            errors.append(f"SPECIES: {sid!r} is not a shape species of {base_id} in docs/animals.md{hint}")
    for cid in colours:
        if cid not in colour_parent:
            hint = " (it is a shape species: put it in SPECIES)" if cid in shapes else ""
            errors.append(f"COLOURS: {cid!r} is not a colour species of {base_id} in docs/animals.md{hint}")
    valid = {}
    for sid, sp in species.items():
        w = f"SPECIES[{sid!r}]"
        if not isinstance(sp, dict):
            errors.append(f"{w}: must be a dict")
            continue
        for k in sp:
            if k not in SPECIES_KEYS:
                errors.append(f"{w}: unknown key {k!r} (allowed: palette, patches, fly)")
        if "palette" not in sp:
            errors.append(f"{w}: missing 'palette'")
            continue
        if not check_palette(sp["palette"], f"{w}.palette", errors):
            continue
        patches = patch_list(sp, w, errors)
        check_patch_bounds(patches, frames, errors)
        own_fly = None
        flying = []
        if "fly" in sp:
            if fly is None:
                errors.append(f"{w}: has 'fly' but the module defines no FLY")
            elif sp["fly"] == SAME:
                own_fly = SAME
            else:
                own_fly = patch_list(sp, w, errors, "fly")
                check_patch_bounds(own_fly, frames, errors)
                flying = own_fly
        if fly is not None:
            flying = flying + [p for part in fly for p in part]
        missing = used_roles(frames, patches + flying) - set(sp["palette"])
        if missing:
            errors.append(f"{w}: palette lacks roles used in the art: {', '.join(sorted(missing))}")
        valid[sid] = (sp["palette"], patches, own_fly)
    valid_colours = {}
    for cid, over in colours.items():
        w = f"COLOURS[{cid!r}]"
        if not check_palette(over, w, errors):
            continue
        parent = colour_parent.get(cid)
        if parent is None:
            continue
        if parent not in species:
            errors.append(f"{w}: its shape species {parent!r} is not in SPECIES")
            continue
        if parent not in valid:
            continue
        base_pal = valid[parent][0]
        stray = set(over) - set(base_pal)
        if stray:
            errors.append(f"{w}: overrides roles {', '.join(sorted(stray))} that {parent!r} does not define")
        if not any(base_pal.get(r) != c for r, c in over.items()):
            errors.append(f"{w}: identical to the palette of {parent!r}")
        valid_colours[cid] = parent
    missing = [e for s, cs in shapes.items() for e in [s, *cs] if e not in species and e not in colours]
    if missing:
        warnings.append(f"missing entries: {', '.join(missing)}")
    if errors:
        return errors, warnings, None
    return errors, warnings, (frames, valid, valid_colours, fly)


def paint_patches(g, patches, frame, ox, oy, head):
    for fr, px, py, prows, _ in patches:
        if fr not in (None, frame):
            continue
        for y, row in enumerate(prows):
            for x, ch in enumerate(row):
                if ch == EMPTY:
                    continue
                if ch == HEAD:
                    head = (ox + px + x, oy + py + y)
                    continue
                g[oy + py + y][ox + px + x] = EMPTY if ch == ERASE else ch
    return head


def move_region(g, part, ox, oy, head):
    _, x, y, w, h, dx, dy, _ = part
    x0, y0 = ox + x, oy + y
    block = [(i, j, g[y0 + j][x0 + i]) for j in range(h) for i in range(w)]
    for i, j, _ in block:
        g[y0 + j][x0 + i] = EMPTY
    for i, j, ch in block:
        if ch != EMPTY:
            g[y0 + j + dy][x0 + i + dx] = ch
    if head and x0 <= head[0] < x0 + w and y0 <= head[1] < y0 + h:
        head = (head[0] + dx, head[1] + dy)
    return head


def paint_grid(frames, patches, frame):
    rows = frames[frame]
    w, h = len(rows[0]), len(rows)
    ox, oy = origin(w, h)
    g = [[EMPTY] * SIZE for _ in range(SIZE)]
    head = None
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch == HEAD:
                head, ch = (ox + x, oy + y), "b"
            if ch != EMPTY:
                g[oy + y][ox + x] = ch
    head = paint_patches(g, patches, frame, ox, oy, head)
    return g, head, ox, oy


def render_grid(frames, patches, frame):
    g, head, _, _ = paint_grid(frames, patches, frame)
    return outline(g), head


def render_fly(frames, patches, fly, own_fly, frame):
    g, head, ox, oy = paint_grid(frames, patches, 0)
    for part in fly[frame]:
        if part[0] == MOVE:
            head = move_region(g, part, ox, oy, head)
        else:
            head = paint_patches(g, [part], frame, ox, oy, head)
    head = paint_patches(g, own_fly, frame, ox, oy, head)
    return outline(g), head


def outline(g):
    out = [row[:] for row in g]
    for y in range(SIZE):
        for x in range(SIZE):
            if g[y][x] != EMPTY:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                yy, xx = y + dy, x + dx
                if 0 <= yy < SIZE and 0 <= xx < SIZE and g[yy][xx] != EMPTY:
                    out[y][x] = "O"
                    break
    return out


def render_base(parsed, mod):
    frames, shapes, colours, fly = parsed
    result = {}
    for sid, (pal, patches, own_fly) in shapes.items():
        rendered = [render_grid(frames, patches, f) for f in (0, 1)]
        grids, heads = [g for g, _ in rendered], [h for _, h in rendered]
        fgrids = fheads = None
        if own_fly == SAME:
            fgrids, fheads = grids, heads
        elif fly is not None:
            flown = [render_fly(frames, patches, fly, own_fly or [], f) for f in (0, 1)]
            fgrids, fheads = [g for g, _ in flown], [h for _, h in flown]
        result[sid] = (grids, {**pal, "O": OUTLINE}, heads, fgrids, fheads)
    for cid, parent in colours.items():
        grids, pal, heads, fgrids, fheads = result[parent]
        result[cid] = (grids, {**pal, **mod.COLOURS[cid]}, heads, fgrids, fheads)
    return result


def validate_hats(mod, hat_ids):
    errors, warnings = [], []
    pal, hats = getattr(mod, "PALETTE", None), getattr(mod, "HATS", None)
    if not isinstance(hats, dict) or not isinstance(pal, dict):
        return ["hats: needs PALETTE (dict) and HATS (dict of hat-id -> rows)"], warnings, None
    if hats:
        check_palette(pal, "PALETTE", errors)
    for hid, rows in hats.items():
        if hid not in hat_ids:
            errors.append(f"HATS: {hid!r} is not one of {', '.join(hat_ids)}")
            continue
        w = f"HATS[{hid!r}]"
        if not check_rows(rows, w, errors, allow=(EMPTY,)):
            continue
        if len(rows[0]) % 2 == 0:
            errors.append(f"{w}: width {len(rows[0])} must be odd so the bottom-centre pixel is exact")
        if len(rows[0]) > MAX_HAT or len(rows) > MAX_HAT:
            errors.append(f"{w}: larger than {MAX_HAT}x{MAX_HAT}")
        missing = {ch for r in rows for ch in r if is_role(ch)} - set(pal)
        if missing:
            errors.append(f"{w}: palette lacks roles {', '.join(sorted(missing))}")
    missing = [h for h in hat_ids if h not in hats]
    if missing:
        warnings.append(f"missing hats: {', '.join(missing)}")
    if errors:
        return errors, warnings, None
    return errors, warnings, hats


def render_hat(rows, pal):
    w, h = len(rows[0]) + 2, len(rows) + 2
    g = [[EMPTY] * w for _ in range(h)]
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            g[y + 1][x + 1] = ch
    out = [row[:] for row in g]
    for y in range(h):
        for x in range(w):
            if g[y][x] == EMPTY and any(
                0 <= y + dy < h and 0 <= x + dx < w and g[y + dy][x + dx] != EMPTY
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))
            ):
                out[y][x] = "O"
    return out, {**pal, "O": OUTLINE}
