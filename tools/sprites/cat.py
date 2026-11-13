BODY = [
    "..........b.......b.",
    "..........bb.....bb.",
    "..........bpb...bpb.",
    "..........bpbbHbbpb.",
    "..........bbbbbbbbb.",
    "..........bbebbbebb.",
    "......bbbbbbebbbebb.",
    "....bbbbbbbbllnllbb.",
    "...bbbbbbbblllllb...",
    "...bbbbbbbbbbllllb..",
    "b..dbbbbbbbbblllb...",
    "bbbbddddddddddddd...",
]

BODY_B = BODY[:7] + [
    ".b..bbbbbbbbllnllbb.",
    ".b.bbbbbbbblllllb...",
    ".b.bbbbbbbbbbllllb..",
    "..bdbbbbbbbbblllb...",
    "..bbddddddddddddd...",
]

FRAMES = [
    BODY + [
        "....bb.dd...bb.dd...",
        "...bb.dd.....bb.dd..",
        "..kk.kk.......kk.kk.",
    ],
    BODY_B + [
        "....bb.dd...bb.dd...",
        "....bb.dd...bb.dd...",
        ".....kk.kk.kk.kk....",
    ],
]

TABBY = {
    "b": "#b08a5b", "d": "#8a6a43", "l": "#efe0c4", "a": "#5a3f26", "k": "#7a5c3a",
    "p": "#e8a0a0", "e": "#9bc43e", "q": "#1f1a14", "n": "#d98a8a",
}

LEGS = [(0, 0, 12, ["....mm.mm...mm.mm...", "...mm.mm.....mm.mm.."]), (1, 0, 12, ["....mm.mm...mm.mm...", "....mm.mm...mm.mm..."])]

FLUFFY_TAIL = [
    (0, 0, 9, ["bb"]),
    (0, 1, 10, ["bb"]),
    (1, 0, 6, ["bb"]),
    (1, 0, 7, ["b", "b", "b"]),
    (1, 1, 10, ["b"]),
]

SPECIES = {
    "tabby": {
        "palette": TABBY,
        "patches": [
            (None, 13, 4, ["a.a"]),
            (None, 5, 8, ["a.a.a", "a.a.a"]),
            (None, 6, 10, ["a.a"]),
            (None, 2, 11, ["a"]),
            (0, 0, 10, ["a"]),
            (1, 1, 8, ["a"]),
        ],
    },
    "siamese": {
        "palette": {
            **TABBY, "b": "#ecd9b4", "d": "#d6bf98", "l": "#f6ecd6", "k": "#4b3427", "p": "#4b3427",
            "e": "#5aa5ee", "n": "#2a1c15", "m": "#4b3427",
        },
        "patches": [
            (None, 10, 0, ["m.......m", "mm.....mm"]),
            (None, 10, 2, ["m.m...m.m"]),
            (None, 13, 6, ["mmm"]),
            (None, 12, 7, ["mmnmm"]),
            (None, 12, 8, ["mmm"]),
            (0, 0, 10, ["m"]),
            (0, 0, 11, ["mmm"]),
            (1, 1, 7, ["m", "m", "m"]),
            (1, 2, 10, ["m", "m"]),
            *LEGS,
        ],
    },
    "persian": {
        "palette": {
            **TABBY, "b": "#ebe4d8", "d": "#c9bba8", "l": "#fbf8f2", "k": "#c9bba8",
            "p": "#e8b0b0", "e": "#e08a2a",
        },
        "patches": [
            (None, 9, 5, ["b"]),
            (None, 19, 5, ["b", "b"]),
            (None, 17, 8, ["l"]),
            (None, 18, 9, ["l"]),
            *FLUFFY_TAIL,
            (None, 3, 7, ["b"]),
            (None, 2, 8, ["b", "b"]),
        ],
    },
    "maine-coon": {
        "palette": {
            **TABBY, "b": "#86644a", "d": "#5f4430", "l": "#e6d8bf", "a": "#3f2d20", "k": "#5f4430",
            "e": "#d9a52f",
        },
        "patches": [
            (None, 10, -1, ["a.......a"]),
            (None, 17, 8, ["l"]),
            (None, 18, 9, ["l"]),
            *FLUFFY_TAIL,
            (None, 5, 8, ["a...a"]),
            (None, 7, 9, ["a"]),
            (0, 0, 9, ["a"]),
            (1, 0, 8, ["a"]),
        ],
    },
    "scottish-fold": {
        "palette": {
            **TABBY, "b": "#8f98a8", "d": "#6a7284", "l": "#d9dde6", "a": "#5a6274", "k": "#6a7284",
            "e": "#f0a030",
        },
        "patches": [
            (None, 10, 0, ["-.......-", "--.....--"]),
            (None, 10, 2, ["bab...bab"]),
        ],
    },
    "sphynx": {
        "palette": {
            **TABBY, "b": "#dbb0a0", "d": "#b07a6e", "l": "#f0d4c8", "a": "#b07a6e", "k": "#c49488",
            "p": "#f0a8a8", "e": "#b8d048",
        },
        "patches": [
            (None, 9, -1, ["b.........b", "bb.......bb"]),
            (None, 9, 1, ["bp.......pb"]),
            (None, 13, 4, ["aaa"]),
            (None, 6, 8, ["a", "a"]),
            (None, 9, 9, ["a"]),
        ],
    },
    "nekomata": {
        "palette": {
            "b": "#4b4468", "d": "#363050", "l": "#9a90c0", "a": "#6a5f8e", "k": "#2b2640", "p": "#d98ac0",
            "e": "#ffe45a", "q": "#1f1a14", "n": "#e08ab8", "f": "#5b7dff", "g": "#b38cff", "w": "#f2ecff",
        },
        "patches": [
            (None, 0, 10, ["bbb"]),
            (1, 1, 7, ["-", "-", "-"]),
            (None, 0, 5, ["b", "b", "b", "b", "b"]),
            (None, 3, 3, ["b", "b", "b", "b"]),
            (None, -1, 1, [".g.", "gwg", "fwf"]),
            (None, 2, -1, [".g.", "gwg", "fwf"]),
            (0, -1, 0, [".f."]),
            (1, 2, -2, [".f."]),
            (None, 5, 8, ["a.a.a"]),
        ],
    },
}

COLOURS = {
    "black-cat": {"b": "#3f3f4a", "d": "#2d2d36", "l": "#55555f", "a": "#35353f", "k": "#2d2d36", "e": "#ffe14a", "p": "#7a5560", "n": "#7a5560"},
    "golden-cat": {"b": "#e8b52e", "d": "#c08a1c", "l": "#fff0b8", "a": "#d9a024", "k": "#d9a024"},
}
