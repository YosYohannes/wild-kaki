FRAMES = [
    [
        "...................kb..bk...",
        "...................bb..bb...",
        "...................bbbHbb...",
        "...................bbbbeb...",
        "..bbbb.............bbbbbbbbn",
        ".lbbbb............bbbbbbbbbn",
        "llbbb.bbbbbbbbbbbbbbbbllllll",
        "llbbbbbbbbbbbbbbbbbbbbllllll",
        "llbbbbbbbbbbbbbbbbblll......",
        ".....bbbbbbbbbbbbbblll......",
        "......bdddddddddddblll......",
        ".....bb..kk.....kk..bb......",
        ".....bb..kk.....kk..bb......",
        ".....kk.............kk......",
        ".....kk.............kk......",
    ],
    [
        "...................kb..bk...",
        "...................bb..bb...",
        "...................bbbHbb...",
        "...................bbbbeb...",
        "..bbbb.............bbbbbbbbn",
        ".lbbbb............bbbbbbbbbn",
        "llbbb.bbbbbbbbbbbbbbbbllllll",
        "llbbbbbbbbbbbbbbbbbbbbllllll",
        "llbbbbbbbbbbbbbbbbblll......",
        ".....bbbbbbbbbbbbbblll......",
        "......bdddddddddddblll......",
        ".....kk..bb.....bb..kk......",
        ".....kk..bb.....bb..kk......",
        ".........kk.....kk..........",
        ".........kk.....kk..........",
    ],
]

RED = {"b": "#d9772f", "d": "#b3591f", "l": "#f6eedc", "k": "#2a2a22", "e": "#2a2a22", "n": "#2a2a22"}

SPECIES = {
    "red-fox": {"palette": RED},
    "fennec": {
        "palette": {**RED, "b": "#e6c58d", "d": "#c49a5e", "l": "#fbf3e1", "a": "#e8a0a0", "t": "#5a4a40"},
        "patches": [
            (None, 15, -4, [
                "b............b",
                "bb..........bb",
                ".bab......bab.",
                ".baab....baab.",
                "..baab..baab..",
                "..bbbb..bbbb..",
            ]),
            (None, 0, 3, [
                "...bbb",
                "..bbbb",
                ".ttbbb",
                "tttbb.",
                "tttbb.",
                "-ttbbb",
                "..bbb.",
            ]),
            (None, 24, 4, ["lll"]),
            (None, 20, 5, ["lllllll"]),
            (None, 27, 4, "-"),
            (None, 26, 7, ["--"]),
            (None, 27, 6, "-"),
        ],
    },
    "grey-fox": {
        "palette": {**RED, "b": "#8f9299", "d": "#62656d", "l": "#f0ebe0", "a": "#26262b", "r": "#c07645"},
        "patches": [
            (None, 2, 5, ["aaaa"]),
            (None, 6, 6, ["aaaa"]),
            (None, 10, 7, ["aaaaaaaa"]),
            (None, 0, 5, [".a", "aa", "aa", "aa"]),
            (None, 11, 6, ["d.d.d.d"]),
            (None, 6, 8, ["rrrrrrrrrrrrr"]),
            (None, 5, 9, ["rrrrrrrrrrrrrr"]),
            (None, 18, 6, ["rrrr", "rrrr"]),
            (None, 19, 5, ["llllll"]),
            (None, 25, 4, ["aa"]),
            (0, 5, 11, ["rr", "rr"]),
            (0, 20, 11, ["rr", "rr"]),
            (1, 9, 11, ["rr", "rr"]),
            (1, 16, 11, ["rr", "rr"]),
        ],
    },
    "kitsune": {
        "palette": {
            **RED, "b": "#fbf6ec", "d": "#e0d9ee", "l": "#ffffff", "k": "#d63a3a", "e": "#b86a12",
            "r": "#d63a3a", "g": "#f2b92e", "y": "#fff0a0", "o": "#f29a4a", "s": "#d9702c", "w": "#ffffff",
        },
        "patches": [
            (None, 0, 4, ["-----", "-----", "-----", "-----", "-----"]),
            (None, 5, 6, "b"),
            (0, -1, -9, [".......w.........", "......ww.........", ".....www.........", ".....wwww.....w..", "w....www....ww...", "www...oo...www...", "www..ooo...www...", "www..oooo.ssw....", ".sss.oooossss....", ".ssssoooosss..ww.", "..sssooossss.wwww", "w.sssooosssowwwww", "woosssosssoowwww.", "wooossoosooooo...", "ooooosooooooo....", "..ooooooooo......"]),
            (1, -1, -9, ["......w..........", ".....ww..........", ".....www.........", "w...wwww.........", "ww...www.....ww..", "www..ooo....www..", "www..ooo....www..", ".wws.ooo...sww...", ".ssssooo..sss....", "..sssooo.sssswwww", "..sssooossss.wwww", "...ssooosssowwww.", "woossooosooowww..", "wooossoosoooo....", "ooooosoooooo.....", ".oooooooooo......"]),
            (None, 20, 3, ["rrr"]),
            (None, 19, 5, ["rr"]),
            (None, 19, 9, ["yg", "gg"]),
        ],
    },
}

COLOURS = {
    "silver-fox": {"b": "#6c7079", "d": "#474a54", "l": "#e4e6ea"},
    "arctic-fox": {"b": "#f1f4f8", "d": "#c3cfdd", "l": "#ffffff", "k": "#8fa0b8", "e": "#1f2733", "n": "#1f2733"},
}
