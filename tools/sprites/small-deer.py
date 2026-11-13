FRAMES = [
    [
        "...........k.........k......",
        "...........bab.....bab......",
        "............bab...bab.......",
        ".............bb...bb........",
        "..............bbHbb.........",
        "..............bbbbbb........",
        ".............bbbbbebb.......",
        "............bbbbbbblln......",
        "............bbbbblll........",
        "............bbbbl...........",
        "............bbbbl...........",
        ".w.........bbbbbbl..........",
        ".wbbbbbbbbbbbbbbbl..........",
        "..bbbbbbbbbbbbbbbl..........",
        ".bbbbbbbbbbbbbbbbl..........",
        ".bbbbbbbbbbbbbbbbl..........",
        "..bbbbbbbbbbbbbbll..........",
        "...bbllllllllllll...........",
        "...bbllllllllllll...........",
        "...bb..dd..dd..bb...........",
        "...bb..dd..dd..bb...........",
        "..bb..dd...dd...bb..........",
        "...b...d...d....b...........",
        "...b...d...d...k............",
        "...k...k...k................",
    ],
    [
        "...........k.........k......",
        "...........bab.....bab......",
        "............bab...bab.......",
        ".............bb...bb........",
        "..............bbHbb.........",
        "..............bbbbbb........",
        ".............bbbbbebb.......",
        "............bbbbbbblln......",
        "............bbbbblll........",
        "............bbbbl...........",
        "............bbbbl...........",
        ".w.........bbbbbbl..........",
        ".wbbbbbbbbbbbbbbbl..........",
        "..bbbbbbbbbbbbbbbl..........",
        ".bbbbbbbbbbbbbbbbl..........",
        ".bbbbbbbbbbbbbbbbl..........",
        "..bbbbbbbbbbbbbbll..........",
        "...bbllllllllllll...........",
        "...bbllllllllllll...........",
        "...bb..dd..dd..bb...........",
        "...bb..dd..dd..bb...........",
        "...bb.dd.....dd.bb..........",
        "...b..d.......d..b..........",
        "...b.d........d..b..........",
        "...k.k........k..k..........",
    ],
]

MUNTJAC = {
    "b": "#a85a2c", "d": "#7e3f1f", "l": "#f0e0c0", "a": "#d99a80", "k": "#54402f",
    "e": "#1c1410", "n": "#1c1410", "w": "#fbf6ea", "t": "#efe3bf", "v": "#4a2412",
}

MOUSE_DEER = {
    "b": "#8a5b3a", "d": "#5e3b24", "l": "#e6d3b0", "a": "#c99a84", "k": "#54402f",
    "e": "#140e0a", "n": "#140e0a", "w": "#fbf6ea",
}

MD_TOP = [
    "....bbbbb.....k....k....",
    "...bbbbbbbb...ba..ab....",
    ".wbbbbbbbbbb..ba..ab....",
    "..bbbbbbbbbbb.bbbbbb....",
    "..bbbbbbbbbbbbbbbbebb...",
    "..bbbbbbbbbbbbbbbbelln..",
    "...bbllllllllbbwwwww....",
]

MD_FRAMES = [
    MD_TOP + [
        "...bb..dd..d...b........",
        "..bb...dd..d...bb.......",
        "..b....d...d....b.......",
        ".b.....d...d....b.......",
        ".b.....d...d.....b......",
        ".k.....k...k.....k......",
    ],
    MD_TOP + [
        "...bb..dd..d...b........",
        "...bb.dd....d..b........",
        "...b..d.....d..b........",
        "...b..d......d.b........",
        "...b.d.......d.b........",
        "...k.k.......k.k........",
    ],
]

NECK_BACK = {5: 14, 6: 13, 7: 12, 8: 12, 9: 12, 10: 11, 11: 11}


def mane(lines, y0=5):
    return [(None, NECK_BACK[y0 + i] + dx, y0 + i, text) for i, (dx, text) in enumerate(lines)]


UNICORN = {
    "b": "#f9f4ef", "d": "#d2c8e2", "l": "#fffdf8", "a": "#f6b8d0", "k": "#e3b04c", "e": "#5b3a8c", "n": "#e58ba8",
    "w": "#f7c9e8", "t": "#efe3bf", "v": "#4a2412",
    "h": "#ffd84e", "i": "#c98f1c", "r": "#f7a9bb", "o": "#fbc99f", "y": "#fbe7a1", "g": "#b4e6bb", "u": "#a7d3f5", "p": "#cdb5ee",
}

HORN = [
    "...hh",
    "...hi",
    "..hi.",
    "..ih.",
    ".hi..",
    ".ih..",
]

UNICORN_MANE = [(-2, "rrrr"), (-2, "oooo"), (-2, "yyyy"), (-2, "gggg"), (-2, "uuuu"), (-2, "pppp")]

QILIN = {
    "b": "#2f9a8a", "d": "#1f6f6c", "l": "#a9e3cc", "a": "#e8a24a", "k": "#d9a53a", "e": "#fff07a", "n": "#12332f",
    "w": "#ff8a2a", "t": "#efe3bf", "v": "#4a2412",
    "c": "#5fcbae", "f": "#ff6a1f", "o": "#ffb237", "y": "#ffe27a", "h": "#f2d58a", "i": "#b98a3a",
}

ANTLER = [
    "...h.h",
    "...hh.",
    "..ih..",
    "..i...",
    ".ii...",
    ".i....",
]

QILIN_MANE = [(-2, "fofy"), (-3, "fyoo"), (-2, "foyo"), (-3, "ffoy"), (-2, "fyof"), (-3, "ffoo")]


def repaint(frame, change):
    rows = []
    for y, row in enumerate(FRAMES[frame]):
        rows.append("".join(change(x, y, ch) or "." for x, ch in enumerate(row)))
    return (frame, 0, 0, rows)


def both(change):
    return [repaint(0, change), repaint(1, change)]


def scales(x, y, ch):
    if ch == "b" and y >= 11 and x <= 17 and (x + 2 * (y % 2)) % 4 == 0:
        return "c"


SPECIES = {
    "muntjac": {
        "palette": MUNTJAC,
        "patches": [
            (None, 15, 1, ["t..", "t.t", "v.v"]),
            (None, 15, 4, ["v.v", ".v."]),
            (None, 20, 8, "w"),
        ],
    },
    "mouse-deer": {
        "palette": MOUSE_DEER,
        "patches": [
            (None, 0, 0, ["-" * 28] * 25),
            (0, 2, 12, MD_FRAMES[0]),
            (1, 2, 12, MD_FRAMES[1]),
            (None, 18, 15, "H"),
        ],
    },
    "unicorn": {
        "palette": UNICORN,
        "patches": [
            (None, 18, 0, ["----"] * 4),
            (None, 15, -2, HORN),
            *mane(UNICORN_MANE),
            (None, -1, 11, ["r.", "ro", "oy", "yg", "gu", "up"]),
            (None, 5, 8, [".y.", "yyy", ".y."]),
        ],
    },
    "qilin": {
        "palette": QILIN,
        "patches": [
            *both(scales),
            (None, 18, 0, ["----"] * 4),
            (None, 17, -2, ANTLER),
            *mane(QILIN_MANE),
            (None, -1, 11, [".f.", "fof", "ffo"]),
        ],
    },
}

COLOURS = {}
