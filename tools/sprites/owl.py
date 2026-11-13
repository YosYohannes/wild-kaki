STAND = [
    ".bb...........bb.",
    ".bbb.bbbHbbb.bbb.",
    ".bbbbbbbbbbbbbbb.",
    "bbbffffbbbffffbbb",
    "bbffffffbffffffbb",
    "bfffkkwfffkkwfffb",
    "bfffkkkyyykkkfffb",
    "bfppffffyffffppfb",
    "bbfffffffffffffbb",
    "ddbblllllllllbbdd",
    "ddbllllmlmllllbdd",
    "dddlllllllllllddd",
    "dddllmlmlmllllddd",
    ".ddllllllllllldd.",
    "..ddlllllllllldd.",
    "...ddllllllldd...",
    "....ss.....ss....",
]


def hop(rows):
    return rows[1:16] + [rows[15]] + rows[16:]


FRAMES = [STAND, hop(STAND)]


def body(x, y, rows):
    return [(0, x, y, rows), (1, x, y - 1, rows)]


def patches(*parts):
    return [p for part in parts for p in part]


NO_TUFTS = patches(
    body(1, 0, ["--"]),
    body(14, 0, ["--"]),
    body(4, 1, ["b"]),
    body(12, 1, ["b"]),
)

AMBER_EYES = patches(
    body(4, 5, ["eew...eew"]),
    body(4, 6, ["eke...eke"]),
)

BARN = {
    "b": "#cf9650", "d": "#b57a3a", "l": "#f6efe0", "f": "#fcf8ee", "m": "#a8825a",
    "k": "#1a1410", "w": "#ffffff", "y": "#e2d3b0", "s": "#d9b9a0", "p": "#f0b4b4",
}

SPECIES = {
    "barn-owl": {
        "palette": BARN,
        "patches": NO_TUFTS,
    },
    "tawny-owl": {
        "palette": {
            "b": "#8a5c3a", "d": "#5e3d26", "l": "#d6bf9a", "f": "#c9a26e", "m": "#3e2616",
            "k": "#14100c", "w": "#ffffff", "y": "#e6cf8a", "s": "#b8946a", "p": "#e8a0a0",
        },
    },
    "eagle-owl": {
        "palette": {
            "b": "#b08650", "d": "#7a5630", "l": "#dcc08a", "f": "#cfa468", "m": "#4a2c18",
            "e": "#f08a1c", "k": "#14100c", "w": "#ffffff", "y": "#3a3228", "s": "#6a5238",
            "p": "#e8a08a", "a": "#3a2414",
        },
        "patches": patches(
            body(1, -2, ["a.", "bb"]),
            body(14, -2, [".a", "bb"]),
            AMBER_EYES,
        ),
    },
    "owl-of-athena": {
        "palette": {
            "b": "#aeb8c8", "d": "#7f8aa4", "l": "#e4eaf4", "f": "#f0f4fa", "m": "#6c789a",
            "e": "#ffc933", "k": "#14100c", "w": "#ffffff", "y": "#e8b04a", "s": "#d9a441", "p": "#e8b4c4",
            "q": "#ffe48a", "t": "#7a5c30", "g": "#7ea23c", "h": "#b4d06a", "o": "#3c4a28",
        },
        "patches": patches(
            AMBER_EYES,
            body(18, 7, ["hg.", "tgh", "t..", "to.", "tgh", "t.."]),
            body(-3, 1, [".q.", "qwq", ".q."]),
            body(17, -2, [".q.", "qwq", ".q."]),
            body(-1, 11, ["q"]),
        ),
    },
}

COLOURS = {
    "snowy-owl": {
        "b": "#f4f6fa", "d": "#dfe3ec", "l": "#ffffff", "f": "#ffffff", "m": "#2c2c34",
        "y": "#3a3a42", "s": "#cfd3dc", "p": "#f0c0c8",
    },
}
