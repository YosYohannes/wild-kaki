FRAMES = [
    [
        "..l..............k.........k",
        ".lll.............bk.......kb",
        "lllll............blb.....blb",
        "lbbbbb...........bllbbHbbllb",
        "bbbbbbb..........bbbbbbbbbbb",
        "bbbbbbbb.........bbebbbbbebb",
        ".bbbbbbdd........lllbbbbblll",
        "..bbbbbdd.bbbbbbbbllllnllll.",
        "....bbdd.bbbbbbbbbbblllll...",
        "......bbbbbbbbbbbllllb......",
        "........bbbbbbbbbblllb......",
        ".........dddddddddddd.......",
        ".........xx.dd...xx.dd......",
        "........xx.dd.....xx.dd.....",
        ".......xx.xx.......xx.xx....",
    ],
    [
        ".................k.........k",
        ".................bk.......kb",
        ".................blb.....blb",
        ".................bllbbHbbllb",
        ".................bbbbbbbbbbb",
        ".................bbebbbbbebb",
        ".................lllbbbbblll",
        "..........bbbbbbbbllllnllll.",
        ".........bbbbbbbbbbblllll...",
        ".......bbbbbbbbbbllllb......",
        "ll...bbbbbbbbbbbbblllb......",
        "lllbbbbb.dddddddddddd.......",
        ".llbbbbd.xx.dd...xx.dd......",
        "...bbdd..xx.dd...xx.dd......",
        "..........xx.xx.xx.xx.......",
    ],
]

RED = {
    "b": "#d9772f", "d": "#b3591f", "l": "#f6eedc", "k": "#2a2a22", "e": "#2a2a22", "n": "#2a2a22",
    "x": "#2a2a22",
}


def tip(colour):
    return [
        (0, 2, 0, [colour]),
        (0, 1, 1, [colour * 3]),
        (0, 0, 2, [colour * 5]),
        (0, 0, 3, [colour]),
        (1, 0, 10, [colour * 2]),
        (1, 0, 11, [colour * 3]),
        (1, 1, 12, [colour * 2]),
    ]


SPECIES = {
    "red-fox": {"palette": RED},
    "fennec": {
        "palette": {
            **RED, "b": "#e6c58d", "d": "#c49a5e", "l": "#fbf3e1", "a": "#f0b8b0", "x": "#d9b57a",
        },
        "patches": [
            (None, 16, -3, ["b....", "bb...", "bab..", "baab.", "baab.", "baab."]),
            (None, 24, -3, ["....b", "...bb", "..bab", ".baab", ".baab", ".baab"]),
        ],
    },
    "grey-fox": {
        "palette": {**RED, "b": "#8f9299", "d": "#62656d", "l": "#f0ebe0", "a": "#26262b", "r": "#c07645"},
        "patches": tip("a") + [(None, 11, 9, ["rrrrr"])],
    },
    "kitsune": {
        "palette": {"b": "#fbf6ec", "d": "#e2d9ec", "c": "#c9bdd8", "l": "#ffffff", "r": "#d63a3a", "q": "#a8283a", "a": "#e05a5a", "k": "#d63a3a", "e": "#2a2a22", "n": "#2a2a22", "x": "#d63a3a"},
        "patches": [
            (None, 0, 0, ["-" * 28] * 15),
            (0, 2, -6, [
                ".........q..............",
                "........qqq.............",
                ".....r.qqqq.............",
                "....rrrqqqq..k.........k",
                "...rrrrqqqq..bk.......kb",
                "...rrrrcccc..bab.....bab",
                "...ddddcccc..baabbbbbaab",
                ".r.ddddcccc..bbbbbabbbbb",
                "rrrddddccc...bbebbbbbebb",
                "rrrdddddcc...lllbbbbblll",
                "rrrrddddcc...bllllnllll.",
                "bbbbbddddc...bbbblllll..",
                "bbbbbbdddc..bbbbbllllb..",
                "bbbbbbbddc..bbbbbbllbb..",
                "bbbbbbbbdc.bbbbbbbbbbb..",
                ".bbbbbbbbd.bbbbbdbbbbb..",
                "..bbbbbbbb.bbbbdbdd.bb..",
                ".....bbbbbbbbbbdbdd.bb..",
                "......bbbbbbbbbdbdd.bb..",
                "........bbbbbbbdbdd.bb..",
                "...........bbbbbbkk.kk..",
            ]),
            (1, 2, -6, [
                "........q...............",
                ".......qqq..............",
                "....r..qqqq.............",
                "...rrr.qqqq..k.........k",
                "...rrrrqqqq..bk.......kb",
                "...rrrrcccc..bab.....bab",
                "...ddddcccc..baabbbbbaab",
                "...ddddcccc..bbbbbabbbbb",
                "r..ddddccc...bbebbbbbebb",
                "rr.dddddcc...lllbbbbblll",
                "rrrrddddcc...bllllnllll.",
                "bbbbbddddc...bbbblllll..",
                "bbbbbbdddc..bbbbbllllb..",
                "bbbbbbbddc..bbbbbbllbb..",
                "bbbbbbbbdc.bbbbbbbbbbb..",
                ".bbbbbbbbd.bbbbbdbbbbb..",
                "..bbbbbbbb.bbbbdbdd.bb..",
                ".....bbbbbbbbbbdbdd.bb..",
                "......bbbbbbbbbdbdd.bb..",
                "........bbbbbbbdbdd.bb..",
                "...........bbbbbbkk.kk..",
            ]),
            (0, 0, 10, ["rr..........", "rrrcccc.....", ".rrccccccc..", "...ccccccccc", ".....cccccc."]),
            (1, 0, 10, ["............", "..cccc......", "rrrccccccc..", "rrrrcccccccc", ".rr.cccccc.."]),
            (None, 20, 0, "H"),
        ],
    },
}

COLOURS = {
    "silver-fox": {"b": "#6c7079", "d": "#474a54", "l": "#e4e6ea"},
    "arctic-fox": {"b": "#f1f4f8", "d": "#c3cfdd", "l": "#ffffff", "k": "#8fa0b8", "e": "#1f2733", "n": "#1f2733", "x": "#c3cfdd"},
}
