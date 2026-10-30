FRAMES = [
    [
        ".....................bb.....",
        ".....................bpfHf..",
        "....................bbaaaaa.",
        "........bbbbbbbbbbbbbbaaaean",
        "xxxtttbbbbbbbbbbbbbbbbmmmmmm",
        "xxxtttbbbbbbbbbbbbbbbbmmmm..",
        "......bbblllllllllllllll....",
        "........dddddddddddd........",
        "......gg.jj....jj.gg........",
        "......gggjjj...jjjggg.......",
    ],
    [
        ".....................bb.....",
        ".....................bpfHf..",
        "..........bbbbbbb...bbaaaaa.",
        "........bbbbbbbbbbbbbbaaaean",
        "......bbbbbbbbbbbbbbbbmmmmmm",
        "xxxtttbbbbbbbbbbbbbbbbmmmm..",
        "xxxtttbbblllllllllllllll....",
        "......dddd........dddd......",
        ".....gg...jj...jj...gg......",
        "...ggg....jjj.jjj....ggg....",
    ],
]

STOAT = {
    "b": "#9a6a3c", "d": "#cdb98f", "l": "#f1e7cf", "f": "#9a6a3c", "m": "#f1e7cf", "a": "#9a6a3c",
    "g": "#86582f", "j": "#6c4524", "t": "#9a6a3c", "x": "#1e1b1a", "e": "#17120e", "n": "#2a1d17", "p": "#d9a08e",
}

WIND = {
    "b": "#b98450", "d": "#8d5f34", "l": "#f1e2c4", "f": "#b98450", "m": "#f1e2c4", "a": "#8d5f34",
    "g": "#9a6a3a", "j": "#7a4f28", "t": "#c4905a", "x": "#2a1a12", "e": "#1a120c", "n": "#1a1210", "p": "#e8a894",
    "s": "#ffffff", "z": "#5d7fa6", "w": "#78e8b4",
}

OY = 5


def draw(parts, w=30, h=17):
    c = [["."] * w for _ in range(h)]
    for x, y, text in parts:
        for i, ch in enumerate(text):
            if ch != " ":
                c[y + OY][x + i] = ch
    return ["".join(r) for r in c]


def redraw(frame, rows):
    h = len(rows)
    grid = ["".join("-" if ch == "." else ("b" if ch == "H" else ch) for ch in r) for r in rows]
    out = [(frame, -1, 10 - h, grid)]
    for y, r in enumerate(rows):
        if "H" in r:
            out.append((frame, r.index("H") - 1, 10 - h + y, "H"))
    return out


CURL = [
    ".www.",
    "w...w",
    "w.w.w",
    "w.ww.",
    ".w...",
]


def run(near, far):
    return draw([
        (2, -1, "xxx"), (1, 0, "xxbbbb"), (0, 1, "ttttbbb"), (0, 2, "tttttbb"), (0, 3, "tttttt"), (0, 4, "ttttt"), (1, 5, "tttt"),
        (14, 0, "bb  bb"),
        (13, 1, "bpbbHbpb"),
        (13, 2, "bbbbbbbbbb"),
        (13, 3, "bbbbebbbbbn"),
        (13, 4, "bbbbbmmmmm"),
        (14, 5, "bblllmm"),
        (7, 3, "bbbbbb"),
        (4, 4, "bbbbbbbbbb"),
        (3, 5, "bbbbbbbbbbbb"),
        (2, 6, "bbbbbbbbbbbbbb"),
        (2, 7, "bbbbllllllllbb"),
        (3, 8, "ddlllllllllld"),
        (near, 9, "gg"), (near, 10, "gg"), (near - 1, 11, "ggg"),
        (far, 9, "jj"), (far, 10, "jj"), (far - 1, 11, "jjj"),
        (14, 8, "jj"), (15, 9, "jj"), (15, 10, "jj"), (14, 11, "ggg"),
        (16, 10, "zsss"), (19, 9, "zsss"), (22, 8, "zss"), (23, 7, "zss"),
        (24, 6, "zs"), (24, 5, "s"), (15, 11, "zsssss"),
    ])


SPECIES = {
    "badger": {
        "palette": {
            "b": "#8e9198", "d": "#17171b", "l": "#26262c", "f": "#f1eee6", "m": "#f1eee6", "a": "#1a1a1e",
            "g": "#26262c", "j": "#17171b", "t": "#8e9198", "x": "#8e9198", "e": "#e8e4d0", "n": "#101012", "p": "#cfc8c0",
        },
        "patches": [
            (0, 0, 4, ["------", "------"]),
            (1, 0, 5, ["------", "------"]),
            (None, 8, 2, ["bbbbbbbbbbbb"]),
            (None, 10, 1, ["bbbbbbbb"]),
            (0, 5, 3, ["bbb"]),
            (0, 3, 4, ["bbb"]),
            (0, 3, 5, ["bbb"]),
            (0, 4, 6, ["bb"]),
            (0, 1, 4, ["tt", "tt"]),
            (1, 4, 4, ["bb"]),
            (1, 3, 5, ["bbb"]),
            (1, 3, 6, ["bbb"]),
            (1, 1, 5, ["tt", "tt"]),
            (None, 6, 6, ["lllllllllllllllll"]),
            (None, 5, 7, ["lllllllllllllllll"]),
            (None, 5, 8, ["lllllllllllllllll"]),
            (None, 24, 1, "f"),
            (None, 21, 0, ["ff"]),
        ],
    },
    "stoat": {"palette": STOAT},
    "weasel": {
        "palette": {**STOAT, "b": "#b0753f", "f": "#b0753f", "a": "#b0753f", "t": "#b0753f", "g": "#98622f", "j": "#7a4c24"},
        "patches": [
            (0, 8, 3, ["------------"]),
            (0, 0, 4, ["---", "---"]),
            (0, 3, 5, "-"),
            (1, 10, 2, ["-------"]),
            (1, 0, 5, ["---", "---"]),
            (1, 3, 6, "-"),
        ],
    },
    "ferret": {
        "palette": {
            "b": "#d8c79c", "d": "#b79d6c", "l": "#eee0bc", "f": "#f1e6c8", "m": "#f1e6c8", "a": "#3c2c26",
            "g": "#3a2b25", "j": "#2a1d18", "t": "#3a2b25", "x": "#241914", "e": "#e8dcc0", "n": "#c98a86", "p": "#d9a08e",
        },
        "patches": [
            (None, 24, 1, "f"),
            (0, 1, 6, ["ttttt"]),
            (1, 1, 7, ["ttttt"]),
        ],
    },
    "kamaitachi": {
        "palette": WIND,
        "patches": [
            *redraw(0, run(5, 9)),
            *redraw(1, run(7, 4)),
            (0, 8, -7, CURL),
            (1, 10, -7, CURL),
            (0, 24, -6, CURL),
            (1, 22, -6, CURL),
        ],
    },
}

COLOURS = {
    "albino-badger": {
        "b": "#f1e8d6", "d": "#d3c4b0", "l": "#e3d5c0", "f": "#fffaf4", "m": "#fffaf4", "a": "#bfa498",
        "g": "#e6d9c6", "j": "#d3c4b0", "t": "#f1e8d6", "x": "#f1e8d6", "e": "#c23b5a", "n": "#f0a0a8", "p": "#f0a8b0",
    },
}
