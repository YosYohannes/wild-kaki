FRAMES = [
    [
        "...........bbbb.............",
        "..........bbbbbbb..ll...ll..",
        ".........bbbbbbbbbbbbb.bbbb.",
        "....rrttrbbbbbbbbbbbbbHbbbb.",
        "rrttrrttrbbbbbbbbbbbbbllllb.",
        "rrttrrttrbbbbbbbbbaaaaaeaall",
        "rrttrrttrbbbbbbbbbbaaaalllln",
        "..ttrrttrbbbbbbbbbbbllllllll",
        "......ttrbbbbbbbbbbbbbllll..",
        "..........bbbbbbbbbbb.......",
        "..........ddddddddddd.......",
        "..........uu..vv....uu.vv...",
        "..........uu..vv....uu.vv...",
        "..........kk..kk....kkkkkk..",
    ],
    [
        "...........bbbb.............",
        "..........bbbbbbb..ll...ll..",
        ".........bbbbbbbbbbbbb.bbbb.",
        "....rrttrbbbbbbbbbbbbbHbbbb.",
        "rrttrrttrbbbbbbbbbbbbbllllb.",
        "rrttrrttrbbbbbbbbbaaaaaeaall",
        "rrttrrttrbbbbbbbbbbaaaalllln",
        "..ttrrttrbbbbbbbbbbbllllllll",
        "......ttrbbbbbbbbbbbbbllll..",
        "..........bbbbbbbbbbb.......",
        "..........ddddddddddd.......",
        ".........vv..uu.....vv..uu..",
        ".........vv..uu.....vv..uu..",
        ".........kk..kk.....kk..kkk.",
    ],
]

RACCOON = {
    "b": "#8d8d94", "d": "#63636b", "l": "#efeadc", "a": "#24242a", "k": "#2a2a30", "e": "#efe9cf",
    "n": "#17171a", "r": "#24242a", "t": "#aeaca6", "u": "#8d8d94", "v": "#63636b",
}
PANDA = {
    **RACCOON, "b": "#c8571e", "d": "#2a1f1c", "l": "#f4ebdd", "a": "#f4ebdd", "k": "#2a1f1c", "e": "#1a1410",
    "r": "#8e3513", "t": "#dd7a35", "u": "#2a1f1c", "v": "#3a2b27", "m": "#9a3416",
}
TANUKI = {
    **RACCOON, "b": "#8b7357", "d": "#6c5a45", "l": "#d8c9aa", "a": "#4f3f33", "k": "#3a2e26", "e": "#e6dcc0",
    "r": "#8b7357", "t": "#8b7357", "u": "#4a3a2e", "v": "#3a2e26", "D": "#3a2e26",
}
BAKE = {
    **TANUKI, "g": "#5fae48", "G": "#2f7a34", "w": "#f1f1f4", "W": "#b9bccb", "y": "#ffd23f", "Y": "#a8743a",
}

def at(x, y, rows):
    return (None, x, y + 1, rows)


STUB = [
    at(0, 2, ["-" * 5] * 6),
    at(5, 2, ["--"]),
    at(5, 7, ["--"]),
    at(5, 3, ["D"] * 4),
]

SPECIES = {
    "raccoon": {
        "palette": RACCOON,
        "patches": [
            (0, 20, 12, ["--", "--"]),
            (0, 20, 11, ["ukk"]),
        ],
    },
    "red-panda": {
        "palette": PANDA,
        "patches": [
            at(19, 1, ["ll"]),
            at(24, 1, ["ll"]),
            at(18, 4, ["bbb"]),
            at(19, 5, ["bb"]),
            at(23, 5, ["m", "m"]),
        ],
    },
    "tanuki": {
        "palette": {**TANUKI, "a": "#2b2321", "u": "#42352a", "v": "#30261f", "d": "#6c5a45"},
        "patches": [
            (None, 0, 3, ["-" * 9] * 6),
            (None, 3, 2, ["..bb..", ".bbbb.", "bbbbbd", "bbbbbd", ".bbbdd", "..dddd"]),
            (None, 5, 2, ["dd"]),
            (None, 4, 3, ["d"]),
            (None, 11, 0, ["----"]),
            (None, 10, 1, ["-"]),
            (None, 16, 1, ["-"]),
            (None, 15, 3, ["DD"] * 5),
            (None, 19, 1, ["DD"]),
            (None, 24, 1, ["DD"]),
            (None, 18, 2, ["-"]),
            (None, 21, 2, ["-"]),
            (None, 23, 2, ["-"]),
            (None, 26, 2, ["-"]),
            (None, 22, 4, ["aa"]),
            (None, 18, 5, ["bbb"]),
            (None, 24, 5, ["a"]),
            (None, 25, 5, ["l"]),
            (None, 19, 6, ["bb"]),
            (None, 23, 6, ["a"]),
            (None, 27, 5, ["-"]),
            (None, 27, 6, ["ln"]),
            (None, 27, 7, ["-"]),
        ],
    },
    "bake-danuki": {
        "palette": BAKE,
        "patches": [
            *STUB,
            at(15, 2, ["DD"] * 5),
            at(19, 0, ["DD"]),
            at(24, 0, ["DD"]),
            at(22, 3, ["bbbb"]),
            at(10, 6, [
                "..lllllll..",
                ".lllllllll.",
                "lllllllllll",
                "lllllllllll",
                "lllllllllll",
                ".ddddddddd.",
            ]),
            at(15, 9, "d"),
            at(23, -4, ["g"]),
            at(22, -3, ["gGg"]),
            at(21, -2, ["ggGg"]),
            at(21, -1, ["gGgg"]),
            at(21, 0, ["gGg"]),
            at(22, 1, ["G"]),
            at(0, -1, [
                "..www....",
                ".wwwwww..",
                "wwwwwwwww",
                ".WWWWWWW.",
            ]),
            at(6, -4, [".ww.", "wwww", ".WW."]),
            at(26, -3, [".y.", "yyy", ".y."]),
            at(14, -3, ["y"]),
        ],
    },
}

COLOURS = {}
