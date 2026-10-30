FRAMES = [
    [
        ".........dddd.......",
        "........ddppdd......",
        "........dppppd......",
        ".pp.....dppppdbHb...",
        "p.......ddppddbbeb.w",
        "p....bbbbddddbbbbbn.",
        "p.....bbbbbbbbbbbllw",
        ".p..pbbbbbbbbbbbll..",
        "..pp.bbbbbbbbbbll...",
        "......blllllllbb....",
        "......pp....pp......",
    ],
    [
        ".........dddd.......",
        "........ddppdd......",
        "........dppppd......",
        "........dppppdbHb...",
        "........ddppddbbeb.w",
        "p....bbbbddddbbbbbn.",
        "p.....bbbbbbbbbbbllw",
        ".p..pbbbbbbbbbbbll..",
        "..pp.bbbbbbbbbbll...",
        "......blllllllbb....",
        "........pp.pp.......",
    ],
]

MOUSE = {
    "b": "#9a8576", "d": "#6e5e52", "l": "#e2d6c4", "p": "#e8a0a8", "e": "#1a1410", "n": "#e8808c", "w": "#f4f0e6",
}

CLEAR_TAIL = (None, 0, 3, ["-------"] * 6)
CLEAR_BODY = (None, 5, 0, ["-" * 15] * 10)

DORMOUSE = {
    "b": "#c29a62", "d": "#8f6c3e", "l": "#f6ead0", "p": "#e8a8a0", "e": "#14100c", "n": "#c9705e", "w": "#fff4d8",
}

HAMSTER = {
    "b": "#dca552", "d": "#b57d33", "l": "#fbf2de", "p": "#eba8a4", "e": "#14100c", "n": "#d9808a", "w": "#fff4d8",
}

DORMOUSE_0 = [
    "..bbb.....dddd......",
    ".bb.bb...ddppdd.....",
    ".b...bl..dppppd.....",
    ".b.......dppppdbHb..",
    ".bb.bbbbbbddddbbbbb.",
    ".b.bbbbbbbbbbbblewl.",
    ".bbbbbbbbbbbbbbleeln",
    "..bbbbbbbbbbbbbblll.",
    "...bblllllllllbbb...",
    "....bbllllllllbb....",
    "......pp....pp......",
]

DORMOUSE_1 = [
    "..bbbb....dddd......",
    ".bb..bl..ddppdd.....",
    ".b.......dppppd.....",
    ".b.......dppppdbHb..",
    ".bb.bbbbbbddddbbbbb.",
    ".b.bbbbbbbbbbbblewl.",
    ".bbbbbbbbbbbbbbleeln",
    "..bbbbbbbbbbbbbblll.",
    "...bblllllllllbbb...",
    "....bbllllllllbb....",
    "........pp.pp.......",
]

RATKING = {
    "b": "#8a7868", "d": "#5a4a42", "l": "#c9b69e", "p": "#e08c9e", "e": "#ff4a4a", "n": "#f6a8b4", "w": "#f4f0e6",
    "g": "#b4d24a", "a": "#a08a76", "c": "#6c6058",
}

RATKING_0 = [
    "................bbbb..dH..",
    ".g.............bbbbbbdppd.",
    "........g.....bbbbbbbbbb..",
    ".............pbbbbbbbbebn.",
    ".dd..aaaa....pbblllbbbbl..",
    "dppdaaaaaa...p............",
    ".aaaaaaaaaa..p............",
    "naeaaaaaaaapdpp.....g.....",
    ".laaaalllaadppdp..........",
    "....pp..ppdpddpp........g.",
    ".dd..cccc..dppdp.aaaa..dd.",
    "dppdcccccc..pp..aaaaaadppd",
    ".cccccccccc.p.paaaaaaaaaa.",
    "ncecccccccc.p.paaaaaaaaean",
    ".lcccclllcc....aalllaaaal.",
    "...pp..pp........pp..pp...",
]

RATKING_1 = [
    "..........................",
    ".g..............bbbb..dH..",
    "........g......bbbbbbdppd.",
    "..............bbbbbbbbbb..",
    ".dd..aaaa....pbbbbbbbbebn.",
    "dppdaaaaaa...pbblllbbbbl..",
    ".aaaaaaaaaa..p............",
    "naeaaaaaaaapdpp.....g.....",
    ".laaaalllaadppdp..........",
    "...pp..pp.dpddpp........g.",
    ".dd..cccc..dppdp.aaaa..dd.",
    "dppdcccccc..pp..aaaaaadppd",
    ".cccccccccc.p.paaaaaaaaaa.",
    "ncecccccccc.p.paaaaaaaaean",
    ".lcccclllcc....aalllaaaal.",
    "....pp..pp......pp..pp....",
]

SPECIES = {
    "mouse": {"palette": MOUSE},
    "dormouse": {
        "palette": DORMOUSE,
        "patches": [
            (None, 0, 0, ["-" * 20] * 11),
            (0, 0, 0, DORMOUSE_0),
            (1, 0, 0, DORMOUSE_1),
        ],
    },
    "hamster": {
        "palette": HAMSTER,
        "patches": [
            CLEAR_TAIL,
            CLEAR_BODY,
            (None, 5, 1, [
                "......ddd......",
                "...bbbdpd......",
                "..bbbbdddbbb...",
                ".bbbbbbbbbbeb.w",
                "bbbbbbbbbbllln.",
                "bbbbbbbbblllllw",
                "bbbbbbllllllll.",
                ".bbbbllllllll..",
                ".blllllllll....",
            ]),
        ],
    },
    "rat-king": {
        "palette": RATKING,
        "patches": [
            (None, 0, 0, ["-" * 20] * 11),
            (0, -3, -5, RATKING_0),
            (1, -3, -5, RATKING_1),
        ],
    },
}

COLOURS = {
    "white-hamster": {"b": "#f4f1ea", "d": "#d4cdbf", "l": "#ffffff", "p": "#efb3b8", "n": "#e89aa4"},
}
