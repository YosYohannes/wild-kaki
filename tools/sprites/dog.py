FRAMES = [
    [
        "..................bbbHbb......",
        ".................dbbbbbbb.....",
        "....b...........dddbbebbbn....",
        "....bb..........dddbbbblln....",
        ".....bbbbbbbbbbbbddbblllll....",
        "......bbbbbbbbbbbbbbb.lp......",
        "......bbbbbbbbbbbbbbb..p......",
        "......bbbbbbbbbbbbbbl.........",
        ".......bbbbbbbbbbbbbl.........",
        ".......ddddddddddddll.........",
        ".......bb.dd...dd.bb..........",
        ".......bb.dd...dd.bb..........",
        ".......bb.kk...kk.bb..........",
        ".......bb.........bb..........",
        ".......kk.........kk..........",
    ],
    [
        "..................bbbHbb......",
        ".................dbbbbbbb.....",
        "....b...........dddbbebbbn....",
        "....bb..........dddbbbblln....",
        ".....bbbbbbbbbbbbddbblllll....",
        "......bbbbbbbbbbbbbbb.lp......",
        "......bbbbbbbbbbbbbbb..p......",
        "......bbbbbbbbbbbbbbl.........",
        ".......bbbbbbbbbbbbbl.........",
        ".......ddddddddddddll.........",
        ".......dd.bb...bb.dd..........",
        ".......dd.bb...bb.dd..........",
        ".......kk.bb...bb.kk..........",
        "..........bb...bb.............",
        "..........kk...kk.............",
    ],
]

SPECIES = {
    "shiba": {
        "palette": {"e": "#2a2a22", "n": "#2a2a22", "p": "#e58a9a", "a": "#e8a0a0", "b": "#d9742c", "d": "#b05a20", "l": "#f7efdc", "k": "#f3e9d2"},
        "patches": [
            (None, 16, 1, [
                ".b.",
                "bbb",
                "bbb",
                ".bb",
            ]),
            (None, 19, -2, [
                "b.",
                "bb",
            ]),
            (None, 22, -2, [
                ".b",
                "bb",
            ]),
            (None, 20, 4, "l"),
            (None, 20, 5, [
                "ll",
            ]),
            (None, 22, 1, "l"),
            (None, 4, 2, [
                "-",
                "-",
            ]),
            (None, 4, 0, [
                "..bbb.",
                ".bbbbb",
                "bbddbb",
                "bbbdbb",
                "bbbbb.",
            ]),
        ],
    },
    "corgi": {
        "palette": {"e": "#2a2a22", "n": "#2a2a22", "p": "#e58a9a", "a": "#e8a0a0", "b": "#e49a43", "d": "#bd6f26", "l": "#fbf3e2", "k": "#fbf3e2"},
        "patches": [
            (None, 5, 4, [
                "------------",
            ]),
            (None, 6, 5, [
                "----------",
            ]),
            (None, 4, 2, [
                "--",
                "--",
            ]),
            (None, 16, 1, [
                ".b.",
                "bbb",
                "bbb",
                ".bb",
            ]),
            (None, 17, 0, "b"),
            (None, 24, 0, [
                "bb",
            ]),
            (None, 17, -3, [
                "bbb",
                "bab",
                "bab",
            ]),
            (None, 23, -3, [
                "bbb",
                "bab",
                "bab",
            ]),
            (None, 7, 9, [
                "bbbbbbbbbbbb",
                "bbbbbbbbbbbb",
                "bbbbbbbbbbbb",
            ]),
            (None, 7, 12, [
                "dddddddddddd",
            ]),
            (None, 19, 9, [
                "ll",
                "ll",
                "ll",
                "ll",
            ]),
            (None, 5, 5, [
                "b",
                "b",
            ]),
            (None, 6, 5, "b"),
            (0, 10, 13, [
                "kk",
            ]),
            (0, 15, 13, [
                "kk",
            ]),
            (1, 7, 13, [
                "kk",
            ]),
            (1, 18, 13, [
                "kk",
            ]),
        ],
    },
    "dachshund": {
        "palette": {"e": "#2a2a22", "n": "#2a2a22", "p": "#e58a9a", "a": "#e8a0a0", "b": "#8c4a26", "d": "#5f301a", "l": "#c98a55", "k": "#2d1c12"},
        "patches": [
            (None, 5, 4, [
                "------------",
            ]),
            (None, 6, 5, [
                "----------",
            ]),
            (None, 4, 2, [
                "--",
                "--",
            ]),
            (None, 7, 9, [
                "bbbbbbbbbbbb",
                "bbbbbbbbbbbb",
            ]),
            (None, 7, 11, [
                "dddddddddddd",
            ]),
            (None, 19, 9, [
                "ll",
                "ll",
                "ll",
            ]),
            (None, 1, 6, [
                ".bbbbb",
                "bbbbbb",
                "bbbbbb",
                "bbbbbb",
                "bbbbbb",
                ".ddddd",
            ]),
            (None, 0, 3, [
                "b.",
                "b.",
                ".b",
            ]),
            (None, 17, 5, [
                "dd",
                "dd",
                "dd",
            ]),
            (None, 25, 2, [
                "bbn",
                "lln",
            ]),
            (None, 26, 4, "l"),
            (0, 6, 12, [
                "------",
                "------",
                "------",
            ]),
            (0, 2, 12, [
                "bb",
                "bb",
                "kk",
            ]),
            (0, 5, 12, [
                "dd",
                "kk",
            ]),
            (0, 15, 12, [
                "dd",
                "kk",
            ]),
            (1, 6, 12, [
                "------",
                "------",
                "------",
            ]),
            (1, 2, 12, [
                "dd",
                "kk",
            ]),
            (1, 5, 12, [
                "bb",
                "bb",
                "kk",
            ]),
            (1, 18, 12, [
                "dd",
                "kk",
            ]),
        ],
    },
    "beagle": {
        "palette": {"e": "#2a2a22", "n": "#2a2a22", "p": "#e58a9a", "a": "#2a2420", "b": "#b56d2e", "d": "#6d3a1a", "l": "#f4eee2", "k": "#f4eee2"},
        "patches": [
            (None, 4, 2, [
                "--",
                "--",
            ]),
            (None, 5, 4, [
                "------------",
            ]),
            (None, 7, 9, [
                "bbbbbbbbbbbb",
            ]),
            (None, 7, 10, [
                "llllllllllll",
            ]),
            (None, 16, 2, [
                "dddd",
                "dddd",
                "dddd",
            ]),
            (None, 17, 5, [
                "ddd",
                "ddd",
                "ddd",
            ]),
            (None, 17, 8, [
                "dd",
            ]),
            (None, 8, 5, [
                "aaaaaaaa",
            ]),
            (None, 8, 6, [
                "aaaaaaaa",
            ]),
            (None, 9, 7, [
                "aaaaaa",
            ]),
            (None, 4, 1, [
                "ll.",
                "bbb",
                ".bb",
                ".bb",
            ]),
            (None, 21, 5, [
                "ll",
                "l.",
            ]),
            (0, 7, 12, [
                "ll",
                "ll",
            ]),
            (0, 18, 12, [
                "ll",
                "ll",
            ]),
            (0, 10, 11, [
                "ll",
                "ll",
                "kk",
            ]),
            (0, 15, 11, [
                "ll",
                "ll",
                "kk",
            ]),
            (1, 10, 12, [
                "ll",
                "ll",
            ]),
            (1, 15, 12, [
                "ll",
                "ll",
            ]),
            (1, 7, 11, [
                "ll",
                "ll",
                "kk",
            ]),
            (1, 18, 11, [
                "ll",
                "ll",
                "kk",
            ]),
        ],
    },
    "poodle": {
        "palette": {"e": "#2a2a22", "n": "#2a2a22", "p": "#e58a9a", "a": "#e8a0a0", "b": "#ece5d6", "d": "#c4b9a2", "l": "#faf6ec", "k": "#d3c9b4"},
        "patches": [
            (None, 18, -5, [
                "..bbb..",
                ".bbdbb.",
                "bdbbbdb",
                "bbbdbbb",
                ".bbbbb.",
            ]),
            (None, 15, 1, [
                "..bb",
                ".bdb",
                "bdbb",
                "bbdb",
                ".bdb",
                "..bb",
            ]),
            (None, 4, 2, [
                "--",
                "--",
            ]),
            (None, 3, -1, [
                ".bb.",
                "bbdb",
                "bdbb",
                ".bb.",
            ]),
            (None, 5, 3, "b"),
            (None, 21, -4, "H"),
            (0, 6, 12, [
                "bbbb",
                "bdbb",
            ]),
            (0, 17, 12, [
                "bbbb",
                "bdbb",
            ]),
            (0, 9, 11, [
                "bbbb",
                "bdbb",
            ]),
            (0, 14, 11, [
                "bbbb",
                "bdbb",
            ]),
            (1, 9, 12, [
                "bbbb",
                "bdbb",
            ]),
            (1, 14, 12, [
                "bbbb",
                "bdbb",
            ]),
            (1, 6, 11, [
                "bbbb",
                "bdbb",
            ]),
            (1, 17, 11, [
                "bbbb",
                "bdbb",
            ]),
        ],
    },
    "pug": {
        "palette": {"e": "#2a2a22", "n": "#2a2a22", "p": "#e58a9a", "a": "#e8a0a0", "b": "#d8b684", "d": "#b18d5c", "l": "#ecd9b4", "k": "#2f2a28", "w": "#ffffff"},
        "patches": [
            (None, 16, 1, [
                ".b.",
                "bbb",
                "bbb",
                ".bb",
            ]),
            (None, 17, 0, [
                ".kk",
                "kkk",
                ".k.",
            ]),
            (None, 20, 1, [
                "ddd",
            ]),
            (None, 25, 2, [
                "-",
                "-",
                "-",
            ]),
            (None, 21, 2, [
                "wkkk",
                "kkkk",
                "kkkk",
            ]),
            (None, 4, 2, [
                "--",
                "--",
            ]),
            (None, 5, 0, [
                ".bbb.",
                "bddbb",
                "bbdbb",
                ".bbb.",
            ]),
            (None, 24, 1, "-"),
            (None, 7, 9, [
                "bbbbbbbbbbbb",
            ]),
            (None, 7, 10, [
                "dddddddddddd",
            ]),
        ],
    },
    "husky": {
        "palette": {"e": "#4fb0ea", "n": "#2a2a22", "p": "#e58a9a", "a": "#454c56", "b": "#7a838f", "d": "#d4dae0", "l": "#f6f8fa", "k": "#f6f8fa"},
        "patches": [
            (None, 18, -3, [
                "b..",
                "bb.",
                "bl.",
            ]),
            (None, 22, -3, [
                "..b",
                ".bb",
                ".lb",
            ]),
            (None, 21, 1, "a"),
            (None, 19, 2, [
                "aa",
            ]),
            (None, 19, 3, [
                "aaa",
            ]),
            (None, 22, 2, [
                "lll",
            ]),
            (None, 22, 3, "l"),
            (None, 19, 4, [
                "ll",
            ]),
            (None, 18, 5, [
                "lll",
            ]),
            (None, 4, 2, [
                "--",
                "--",
            ]),
            (None, 4, 0, [
                "...bbbb.",
                "..bbbbbb",
                ".bbb..bb",
                "bbb.....",
                "bb......",
            ]),
        ],
    },
    "terrier": {
        "palette": {"e": "#2a2a22", "n": "#2a2a22", "p": "#e58a9a", "a": "#2f2b28", "b": "#c2914f", "d": "#8a5f2c", "l": "#ecdcb8", "k": "#3b322a"},
        "patches": [
            (None, 16, 1, [
                ".b.",
                "bbb",
                "bbb",
                ".bb",
            ]),
            (None, 18, -1, [
                "dd.",
                "ddd",
            ]),
            (None, 22, -1, [
                "dd.",
                "ddd",
            ]),
            (None, 20, 1, [
                "ddd",
            ]),
            (None, 21, 5, [
                "lllll",
                "lllll",
                "l.l.l",
            ]),
            (None, 4, 2, [
                "--",
                "--",
            ]),
            (None, 5, 0, [
                "bb",
                "bb",
                "bb",
                "bb",
            ]),
            (None, 9, 3, "a"),
            (None, 12, 3, "a"),
            (None, 15, 3, "a"),
            (None, 8, 4, [
                "aaaaaaaaa",
            ]),
            (None, 8, 5, [
                "aaaaaaaa",
            ]),
            (None, 9, 6, [
                "aaaaaa",
            ]),
        ],
    },
    "cerberus-pup": {
        "palette": {
            "b": "#33333b", "x": "#292930", "c": "#464651", "d": "#222228", "l": "#5e5e69", "k": "#1c1c22", "e": "#ffc83a", "n": "#ff7a45",
            "p": "#ff5a3c", "a": "#e8a0a0", "f": "#ff6a1f", "g": "#ffe066",
        },
        "patches": [
            (None, 16, 0, ["----------", "----------", "----------", "----------"]),
            (None, 21, 4, ["-----"]),
            (None, 21, 5, ["----"]),
            (None, 23, 6, "-"),
            (None, 14, 2, ["bbbbbbbb", "bbbbbbbb"]),
            (None, 8, -1, [
                "xx.xx...",
                "xxxxxx..",
                "xxxexxx.",
                "xxxxxlln",
                ".xxxlllp",
                "..ddddd.",
            ]),
            (None, 15, -4, [
                "cc.cc...",
                "cccccc..",
                "ccceccc.",
                "ccccclln",
                ".ccclllp",
                "..ddddd.",
            ]),
            (None, 20, 1, [
                "bb.bb...",
                "bbbbbb..",
                "bbbebbb.",
                "bbbbblln",
                ".bbblllp",
                "..ddddd.",
            ]),
            (None, 17, -4, "H"),
            (0, 3, -3, [".f.", "fgf", ".g."]),
            (1, 3, -3, ["f.f", "fgf", ".g."]),
            (None, 4, 0, ["bb", "bb"]),
            (None, 6, 3, ["bb"]),
        ],
    },
}

COLOURS = {
    "black-shiba": {"b": "#34343c", "d": "#232329", "l": "#c98a4a", "k": "#c98a4a", "e": "#e8d08a"},
    "golden-poodle": {"b": "#e5a95c", "d": "#bf8236", "l": "#f3cf94", "k": "#d39a4c"},
}
