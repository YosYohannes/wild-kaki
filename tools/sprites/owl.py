STAND = [
    "..................",
    "......bbbHbb......",
    "....bbbbbbbbbb....",
    "...bbbbbbbbbbbb...",
    "..bbbbaaaaaaaabb..",
    ".bbbaffffffffffab.",
    ".bbbafeeeffeeefab.",
    "bbbbafekeffekefabb",
    "bbbbafeeeffeeefabb",
    "bbbbaffffyyffffabb",
    "bbbbbaffffyfffabbb",
    "bbbbbbaffffffabbbb",
    "bbbbbbbaaaaaabbbbb",
    ".bddddmddlllllmll.",
    ".dddmddddllllmlll.",
    "..ddmddddlmlllll..",
    "...ddddddllmlll...",
    "....dmdddlllll....",
    "....aaall.ll......",
    "......sss.sss.....",
]


def hop(rows):
    return rows[1:19] + [rows[18]] + rows[19:]


FRAMES = [STAND, hop(STAND)]


def body(x, y, rows):
    return [(0, x, y + 1, rows), (1, x, y, rows)]


def stretch(x, row):
    return [(0, x, 18, [row]), (1, x, 17, [row, row])]


def patches(*parts):
    return [p for part in parts for p in part]


def widen(first, last, head_to):
    out = []
    for y in range(first, last + 1):
        row = STAND[y + 1]
        xs = [i for i, c in enumerate(row) if c != "."]
        right = "b" if y <= head_to else row[xs[-1]]
        out += body(xs[0] - 1, y, [row[xs[0]]]) + body(xs[-1] + 1, y, [right])
    return out


STREAKS = patches(
    body(11, 12, ["m", "m"]),
    body(13, 13, ["m", "m"]),
    body(15, 13, ["m", "m"]),
    body(11, 15, ["m"]),
)

SHINE = patches(body(6, 5, ["w"]), body(11, 5, ["w"]))

BARN = {
    "b": "#cf9650", "d": "#b57a3a", "l": "#f6efe0", "f": "#fcf8ee", "a": "#b88548", "m": "#a8825a",
    "e": "#1a1410", "k": "#14100c", "w": "#ffffff", "y": "#e2d3b0", "s": "#d9b9a0",
}

ATHENA_SPRIG = patches(
    body(14, 16, ["dddddd"]),
    body(20, 7, ["t"] * 10),
    body(21, 5, ["hg"]),
    body(20, 6, ["ggg"]),
    body(21, 8, ["ghg", "gg."]),
    body(21, 11, ["oo", "oo"]),
    body(21, 13, ["ghg", "gg."]),
)

ATHENA_SPARKLE = patches(
    body(-3, 3, [".q.", "qwq", ".q."]),
    body(18, 0, [".q.", "qwq", ".q."]),
    body(-1, 12, ["q"]),
)

SPECIES = {
    "barn-owl": {
        "palette": BARN,
        "patches": patches(
            body(8, 3, ["bbbb"]),
            body(9, 4, ["bb"]),
            body(5, 8, ["a"]),
            body(14, 8, ["a"]),
            body(6, 9, ["aa"]),
            body(12, 9, ["aa"]),
            body(7, 10, ["aa"]),
            body(11, 10, ["aa"]),
            SHINE,
            body(14, 15, ["-"]),
            body(7, 16, ["ll-ll--"]),
            body(5, 1, ["m"]),
            body(11, 1, ["m"]),
            body(2, 6, ["m"]),
            body(3, 8, ["m"]),
            body(14, 3, ["m"]),
        ),
    },
    "tawny-owl": {
        "palette": {
            "b": "#8a5c3a", "d": "#5e3d26", "l": "#d6bf9a", "f": "#c9a26e", "a": "#4a2f1c", "m": "#3e2616",
            "e": "#14100c", "k": "#14100c", "w": "#ffffff", "y": "#cdb88a", "s": "#b8946a",
        },
        "patches": patches(
            SHINE,
            STREAKS,
            body(5, 1, ["m"]),
            body(12, 1, ["m"]),
            body(3, 3, ["m"]),
            body(15, 5, ["m"]),
            body(2, 7, ["m"]),
            body(3, 12, ["lll"]),
            stretch(9, "l"),
        ),
    },
    "eagle-owl": {
        "palette": {
            "b": "#b08650", "d": "#7a5630", "l": "#dcc08a", "f": "#cfa468", "a": "#3a2414", "m": "#4a2c18",
            "e": "#f08a1c", "k": "#14100c", "w": "#ffffff", "y": "#3a3228", "s": "#6a5238",
        },
        "patches": patches(
            widen(1, 16, 11),
            body(4, -3, ["a."]),
            body(4, -2, ["db", "db", "db"]),
            body(13, -3, [".a"]),
            body(13, -2, ["bd", "bd", "bd"]),
            body(6, 4, ["aaa"]),
            body(11, 4, ["aaa"]),
            STREAKS,
            body(7, 1, ["m"]),
            body(10, 1, ["m"]),
        ),
    },
    "owl-of-athena": {
        "palette": {
            "b": "#aeb8c8", "d": "#7f8aa4", "l": "#e4eaf4", "f": "#f0f4fa", "a": "#6c789a", "m": "#c4ccda",
            "e": "#ffc933", "k": "#14100c", "w": "#ffffff", "y": "#e8b04a", "s": "#d9a441",
            "q": "#ffe48a", "t": "#7a5c30", "g": "#7ea23c", "h": "#b4d06a", "o": "#3c4a28",
        },
        "patches": patches(
            body(4, 1, ["m"]),
            body(13, 1, ["m"]),
            body(2, 7, ["m"]),
            body(15, 7, ["m"]),
            body(5, 11, ["m"]),
            body(12, 11, ["m"]),
            SHINE,
            ATHENA_SPRIG,
            ATHENA_SPARKLE,
        ),
    },
}

COLOURS = {
    "snowy-owl": {
        "b": "#f4f6fa", "d": "#dfe3ec", "l": "#ffffff", "f": "#ffffff", "a": "#e3e6ee", "m": "#2c2c34",
        "e": "#f2c230", "y": "#3a3a42", "s": "#cfd3dc",
    },
}
