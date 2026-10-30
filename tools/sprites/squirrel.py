FRAMES = [
    [
        "..tttt..a...a..",
        ".tbbbbt.ab.ba..",
        "tbbbbbt..bbHbb.",
        "tbddddbt.bbbbeb",
        "tbdbbdbt.bbblln",
        "tbddddbbbbllkk.",
        "tbbbbdbbbbllk..",
        "tbbbbdbbbbll...",
        "tbbbbdbbbbll...",
        "tbbbbdbbbbdl...",
        ".tbbbdbbbbd....",
        ".tbbbdbbbb.....",
        "..tbbdbbbbbb...",
        "..ttbbbbbbbbkk.",
        "...ttbbbbbbbbkk",
    ],
    [
        "..tttt.........",
        ".tbbbbt........",
        "tbbbbbt........",
        "tbddddbt.a...a.",
        "tbdbbdbt.ab.ba.",
        "tbddddb..bbHbb.",
        "tbbbbb.bbbbbbeb",
        "tbbbbdbbbbbblln",
        "tbbbbdbbbbbllkk",
        "tbbbbdbbbbbbbk.",
        ".tbbbdbbbbbbbb.",
        ".tbbbdbbllllbb.",
        "..tbbdbbbb..bbk",
        "..ttbbbbb...bbk",
        "...ttkkbb...bkk",
    ],
]

W, H = 15, 15


def redraw(frame, rows, dx):
    dy = H - len(rows)
    grid = [["-"] * W for _ in range(H)]
    head = None
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch == ".":
                continue
            if ch == "H":
                head, ch = (x + dx, y + dy), "b"
            grid[y + dy][x + dx] = ch
    patches = [(frame, 0, 0, ["".join(r) for r in grid])]
    if head:
        patches.append((frame, head[0], head[1], ["H"]))
    return patches


RED = {
    "b": "#c4622a", "d": "#93431d", "l": "#f3e6cc", "a": "#7a3418", "k": "#3a1f12",
    "t": "#e08a45", "e": "#1d1410", "n": "#1d1410",
}

CHIPMUNK_1 = [
    "......bb.bb..",
    ".aa...bbHbb..",
    "tabd.bllllb..",
    "tbbdaaaaaeaan",
    "tbbdallllllb.",
    "tbbdalaaallll",
    "tbbdalalbbllk",
    "tbbdalalbbll.",
    ".tbrrrbbbbl..",
    "..brrrbbbbl..",
    "...rbbbbbbbbk",
    "...bbbbbbbbkk",
]

CHIPMUNK_2 = [
    ".aa..........",
    "tabd.........",
    "tbbd.........",
    "tbbd.........",
    "tbbd..bb.bb..",
    "tbbd..bbHbb..",
    "tbbd.bllllb..",
    "tbbdaaaaaeaan",
    "tbbdllllllllb",
    "tbbdaaaabbllk",
    ".tbrrrbbbbbbk",
    "..kkbbbb..bkk",
]

FLYING_1 = [
    "........bb.bb..",
    ".kk.....bbHbb..",
    "tbbt...bbbbbbb.",
    "tdbt...bbbwebb.",
    "tbbt...bbbeebbn",
    "tdbt...bbbbblll",
    "tbbt..bbbbbbbkk",
    "tbbt.bbddddddd.",
    "tdbt.bbmmmmmmd.",
    "tbbt.bbmmmmmd..",
    "tdbt.bbmmmmd...",
    "tbbt.bbmmmd....",
    ".tbbtbbdmdd....",
    "..ttkbbbbbbbkk.",
]

FLYING_2 = [
    "...............",
    ".kk............",
    "tbbt...........",
    "tdbt....bb.bb..",
    "tbbt....bbHbb..",
    "tdbt...bbbbbbb.",
    "tbbt...bbbwebb.",
    "tdbt...bbbeebbn",
    "tbbt.bbbbbbblll",
    "tdbt.bbddddddd.",
    "tbbt.bbmmmmmmb.",
    "tdbt.bbdmdmdmbb",
    ".tbbtbbb.....bb",
    "..ttkkbb.....kk",
]

RATA = {
    **RED, "b": "#c8381f", "d": "#8c2216", "l": "#f8dcae", "a": "#6e1a10", "k": "#2c0f0c", "t": "#ff7a2c",
    "e": "#ffe27a", "n": "#2a0f0c", "r": "#ffd84a", "p": "#f6e4b8", "s": "#b98a4a", "o": "#ffb347",
}

RUNES = [
    (1, 6, ["r.r", "rrr", ".r."]),
    (2, 9, [".r.", "r.r", ".rr"]),
]

SCROLL = [
    "spps",
    "prrp",
    "spps",
]

SPECIES = {
    "red-squirrel": {"palette": RED},
    "grey-squirrel": {
        "palette": {**RED, "b": "#8e9096", "d": "#5f6168", "l": "#f2efe8", "a": "#5f6168", "k": "#3b3c42", "t": "#dfe4ea", "e": "#1d1d22", "n": "#2b2b30"},
        "patches": [
            (0, 9, 0, ["bb.bb", "bb.bb"]),
            (1, 9, 3, ["bb.bb", "bb.bb"]),
        ],
    },
    "chipmunk": {
        "palette": {**RED, "b": "#b08050", "d": "#7e5630", "l": "#f1e6cf", "a": "#4f321e", "k": "#3a2618", "t": "#efe3c7", "e": "#0d0907", "n": "#1a1210", "r": "#c9632b"},
        "patches": [*redraw(0, CHIPMUNK_1, 1), *redraw(1, CHIPMUNK_2, 1)],
    },
    "flying-squirrel": {
        "palette": {**RED, "b": "#8d857b", "d": "#5e564d", "l": "#efe8da", "a": "#5e564d", "k": "#3a342d", "t": "#cfc4b2", "e": "#0b0908", "n": "#4a3a38", "m": "#d8c8a8", "w": "#ffffff"},
        "patches": [*redraw(0, FLYING_1, 0), *redraw(1, FLYING_2, 0)],
    },
    "ratatoskr": {
        "palette": RATA,
        "patches": [
            *[(None, x, y, rows) for x, y, rows in RUNES],
            (0, 11, 7, SCROLL),
            (1, 11, 10, SCROLL),
            (None, 2, -3, "o"),
            (None, 7, -2, "o"),
        ],
    },
}

COLOURS = {
    "black-squirrel": {"b": "#2d2b33", "d": "#1c1b21", "l": "#403d48", "a": "#1c1b21", "k": "#121115", "t": "#5a5663", "e": "#e9e2cf", "n": "#6b4a55"},
}
