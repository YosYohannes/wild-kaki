FRAMES = [
    [
        ".........kk.kk........",
        "........kkk.kkk.......",
        "........dad.bab.......",
        "........dad.bab.......",
        "........ddd.bbb.......",
        ".........bbbbbbH......",
        "........bbbbbbbbb.....",
        "........bbbbbbebb.....",
        ".....bbbbbbbbbblln....",
        "...bbbbbbbbbbbbll.....",
        "llbbbbbbbbbbbbll......",
        "llbbbbbbdbbllll.......",
        ".bbbbbbbbdbllll.......",
        "bbbbbbbbbdbllll.......",
        "bbbbbbbbbdbllll.......",
        ".bbbbbbbdbbllll.......",
        "..bbbbbbbbbllll.......",
        "....bbbbk...bbk.......",
    ],
    [
        "..........kk..........",
        "......kk..kkk.........",
        "......kkk..bab........",
        ".......dad..bab.......",
        "........dddbbbbbbH....",
        "..........bbbbbbbbb...",
        ".........bbbbbbbebb...",
        "........bbbbbbbbblln..",
        "......bbbbbbbbbllll...",
        "..llbbbbbbbbbbbll.....",
        ".llbbbbbbbbbbblll.....",
        ".bbbbbbbbbbbbllbb.....",
        ".bbbbbbbbbbb..dd.bb...",
        ".bbbbbbbbb.....dd.kk..",
        ".bbbbbbb........kk....",
        ".bbbbbb...............",
        ".bbbbbb...............",
        "kkbbbbbb..............",
    ],
]

HARE = {"b": "#bf8d55", "d": "#8c6238", "l": "#f1e5c8", "a": "#e4a79a", "k": "#2a2a22", "e": "#2a2a22", "n": "#2a2a22"}

MOON = {
    **HARE, "b": "#f6f5fc", "d": "#cdcae6", "l": "#fff2bd", "a": "#f4b9c9", "k": "#a29dc4",
    "g": "#ffe27a", "y": "#f2b830", "m": "#8d6a4b", "q": "#f0dcae", "o": "#c99a68", "e": "#2c2540", "n": "#e58fa5",
}


def rim(frame):
    rows = FRAMES[frame]
    out = []
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch not in "bdl" or y < (5 if frame == 0 else 4):
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if not (0 <= ny < len(rows) and 0 <= nx < len(row)) or rows[ny][nx] == ".":
                    out.append((frame, x, y, "g"))
                    break
    return out


CRESCENT = [".yyy", "yyy.", "yy..", "yyy.", ".yyy"]
MORTAR = [
    "....qq",
    "....qq",
    "...qq.",
    "...qq.",
    "...qq.",
    "oooooo",
    "mmmmmm",
    ".mmmm.",
    "..mm..",
]

SPECIES = {
    "hare": {"palette": HARE},
    "rabbit": {
        "palette": {**HARE, "b": "#9a8672", "d": "#6f5f50", "l": "#f4f0e8"},
        "patches": [
            (0, 8, 0, ["-------", "-d-.-b-"]),
            (0, -2, 9, ["lll.", "llll", "llll", ".lll"]),
            (1, 6, 0, ["....--.", "--..-b-", "-d-...."]),
            (1, 0, 8, ["..ll", ".lll", ".lll", "..ll"]),
        ],
    },
    "jackrabbit": {
        "palette": {**HARE, "b": "#b79a6b", "d": "#8a7248", "l": "#efe6d2"},
        "patches": [
            (0, 8, -3, [
                ".kk.kk.",
                "kkk.kkk",
                "dad.bab",
                "dad.bab",
                "dad.bab",
            ]),
            (1, 2, -2, [
                ".....kk.....",
                ".kk...kkk...",
                "..kkk..bab..",
                "...dad..bab.",
                "....dad.....",
            ]),
        ],
    },
    "moon-rabbit": {
        "palette": MOON,
        "patches": [
            *rim(0), *rim(1),
            (0, 4, 10, CRESCENT),
            (1, 6, 8, CRESCENT),
            (None, 16, 9, MORTAR),
        ],
    },
}

COLOURS = {
    "snow-hare": {"b": "#f1f4f8", "d": "#c3cfdd", "l": "#ffffff"},
}
