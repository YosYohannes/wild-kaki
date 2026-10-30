FRAMES = [
    [
        ".....................bbHb...",
        "....................bbbebbb.",
        "..........bbbbbbbbbbbbbbbbbn",
        "........bbbbbbbbbbbbbblllll.",
        "....bbbbbbbbbbbbbbbbbbll....",
        ".bbbbbbbblllllllllllb.......",
        "bb......bbdd.....ddbb.......",
        "......bb..dd....dd..bb......",
        ".....bb....kkk..kkk..bb.....",
        "....kkkk............kkkk....",
    ],
    [
        ".....................bbHb...",
        "....................bbbebbb.",
        "..........bbbbbbbbbbbbbbbbbn",
        "........bbbbbbbbbbbbbblllll.",
        "....bbbbbbbbbbbbbbbbbbll....",
        ".bbbbbbbblllllllllllb.......",
        "bb......ddbb.....bbdd.......",
        "......dd..bb....bb..dd......",
        ".....kkk...bb...bb...kkk....",
        "..........kkkk.kkkk.........",
    ],
]


GECKO = {
    "b": "#ebcb78", "d": "#c9a050", "l": "#f8efd6", "a": "#5a3a28", "k": "#f0d58c",
    "e": "#1c1612", "n": "#7a5a3a", "w": "#ffffff",
}

SPECIES = {
    "gecko": {
        "palette": GECKO,
        "patches": [
            (None, 23, 1, ["we", "ee"]),
            (None, 11, 1, ["bbbbbbbbb"]),
            (None, 5, 3, ["bbb"]),
            (None, 0, 6, ["bbbbbbbb"]),
            (None, 6, 3, ["a", "a", "a", "a"]),
            (None, 3, 5, ["a", "a"]),
            (None, 13, 1, "a"),
            (None, 17, 1, "a"),
            (None, 11, 2, "a"),
            (None, 15, 2, "a"),
            (None, 19, 2, "a"),
            (None, 9, 3, "a"),
            (None, 13, 3, "a"),
            (None, 17, 3, "a"),
            (None, 11, 4, "a"),
            (None, 15, 4, "a"),
            (None, 8, 4, "a"),
            (None, 22, 0, "a"),
            (None, 21, 2, "a"),
        ],
    },
    "chameleon": {
        "palette": {**GECKO, "b": "#6fae3c", "d": "#4a8a2c", "l": "#cfe58f", "a": "#e8a030", "k": "#3f7a2a"},
        "patches": [
            (None, 4, 4, ["----"]),
            (None, 1, 5, ["-------"]),
            (None, 0, 6, ["--"]),
            (None, 8, 3, "-"),
            (None, 0, -2, [
                ".bbbb...",
                "bb..bb..",
                "b.bbbb..",
                "b.b.....",
                "bb......",
                ".bbbbbbb",
                "......bb",
            ]),
            (None, 10, 1, ["bbbbbbbbb"]),
            (None, 12, 0, ["bbbbb"]),
            (None, 19, -2, ["b"]),
            (None, 19, -1, ["bbb"]),
            (None, 19, 0, ["bb"]),
            (None, 24, -1, ["bbb"]),
            (None, 24, 0, ["lel"]),
            (None, 24, 1, ["lll"]),
            (None, 23, 1, "b"),
            (0, 7, 8, "k"),
            (0, 23, 8, "k"),
            (1, 13, 8, "k"),
            (1, 18, 8, "k"),
            (None, 12, 2, ["l", "l"]),
            (None, 15, 2, ["l", "l"]),
            (None, 18, 2, ["l", "l"]),
            (None, 14, 0, "d"),
            (None, 19, -1, "d"),
        ],
    },
    "iguana": {
        "palette": {**GECKO, "b": "#7f9c63", "d": "#5d7a4a", "l": "#c8d3a0", "a": "#46563a", "k": "#5d7a4a", "p": "#d99a78", "s": "#d4cc82"},
        "patches": [
            (None, 9, 2, ["b"]),
            (None, 10, 6, ["bbbbbbbbb"]),
            (None, 11, 0, ["s.s.s.s.s"]),
            (None, 11, 1, ["s.s.s.s.s"]),
            (None, 8, 2, "s"),
            (None, 6, 3, "s"),
            (None, 4, 3, "s"),
            (None, 22, 3, ["ddddd"]),
            (None, 21, 4, ["pppppp"]),
            (None, 22, 5, ["ppppp"]),
            (None, 22, 6, ["pppp"]),
            (None, 23, 7, ["pp"]),
            (None, 21, 2, ["ll"]),
            (None, 21, 3, ["ll"]),
            (None, 6, 4, ["a", "a"]),
            (None, 4, 4, ["a", "a"]),
            (None, 2, 5, "a"),
            (None, 0, 6, "a"),
        ],
    },
}

COLOURS = {
    "golden-gecko": {"b": "#e8b52e", "d": "#b88a1c", "l": "#fff0b8", "a": "#c98f1a", "k": "#d9a024"},
}


def legend(art, x, fill="b"):
    patches = [(None, 0, 0, ["-" * 28] * 10)]
    for f, rows in enumerate(art):
        top = 10 - len(rows)
        patches.append((f, x, top, [r.replace("H", fill) for r in rows]))
        for j, r in enumerate(rows):
            if "H" in r:
                patches.append((f, x + r.index("H"), top + j, "H"))
    return patches

DRAGON_ART = [
    [
"...dd............a.a........",
        "....mdddd.........a.a.......",
        "....mmmmmdd.......aaHab.....",
        ".....mddddd.......dbbyebb...",
        "...ddddMdmd.......dbbbbbbnf.",
        "mddmmmddMmd.......bllllllb..",
        "..mmmMmMmmmd.....bbbbbb.....",
        "....dmMmmmmd...bbbbbbb......",
        "...dmmmmmmmd..bbbbbbb.......",
        "...a.bbbbbbdbbbbbb..........",
        ".babbbbbbbbbbbbbbll.........",
        "babbbbbbbbbbbblllll.........",
        "bbbbblllllllllllll..........",
        "bb...dd..dd..dd.dd..........",
        ".....bb...bb..bbbb..........",
        ".....kkk..kkk.kkkkk.........",
    ],
    [
        ".................a.a........",
        "...dd.............a.a.......",
        "....mdddd.........aaHab.....",
        ".....mmmddd.......dbbyebb.ff",
        "...mdddMddd.......dbbbbbbnFq",
        "mdddmmmdMmd.......blllbbbbff",
        "..mmmMdMmmd......bbbbbb.....",
        "....ddMmmmmd...bbbbbbb......",
        "...dmmmmmmmd..bbbbbbb.......",
        "...a.bbbbbbdbbbbbb..........",
        ".babbbbbbbbbbbbbbll.........",
        "babbbbbbbbbbbblllll.........",
        "bbbbblllllllllllll..........",
        "bb...dd..dd..dd.dd..........",
        "......bb.bb..bb..bb.........",
        "......kkkkkk.kkk.kkk........",
    ],
]

DRAGON = {
    "b": "#e04a30", "d": "#7a1f1a", "l": "#f4d9a0", "a": "#f6e2a8", "k": "#3a1a16", "e": "#17110c",
    "n": "#3a1a16", "w": "#ffffff", "y": "#ffd23f", "m": "#b8386e", "M": "#e06a9a",
    "f": "#ff9a2a", "F": "#ffe45a", "q": "#ffffff",
}

SPECIES["dragon"] = {"palette": DRAGON, "patches": legend(DRAGON_ART, 0, "b")}

NAGA_ART = [
    [
"...............aaGa.........",
        "................aaGa........",
        ".................aaGa...q...",
        "................dbaaabH.....",
        "..............ddbbbbybbbbnb.",
        "...........a.ddbbbbbbbwbbbb.",
        "...........adbbbdbkkkkppkw..",
        "............dbdblbbbbbbbb...",
        "...........ddbblal..........",
        ".........aadbbdal...........",
        "...........ddbbla...........",
        "...........dbbdal...........",
        "...........ddbbba...........",
        ".........aaddbdbl...........",
        "........a.addbbba...........",
        ".....a.a.adddbdbl...........",
        "...a.a.a.ddddbbla...........",
        "...a..dddddbbbda............",
        "..ddddbbdbbbdla.............",
        "abdbbbdbbbdala..............",
        "alalalalalal................",
    ],
    [
        "..............GGaGa.........",
        "................aaGa........",
        ".................aaGa.......",
        "................dbaaabH...q.",
        "..............ddbbbbybbbbnb.",
        "...........a.ddbbbbbbbwbbbb.",
        "...........adbbbdbkkkkppkw..",
        "............dbdblbbbbbbbb...",
        "...........ddbblal..........",
        ".........aadbbdal...........",
        "...........ddbbla...........",
        "...........dbbdal...........",
        "...........ddbbba...........",
        ".........aaddbdbl...........",
        "........aaaddbbba...........",
        "...a.a..aadddbdbl...........",
        "...a.a..dddddbbla...........",
        ".ddddddddddbbbda............",
        "abbbdbbbdbbbdla.............",
        "aalalbdbbbdala..............",
        "....alalalal................",
    ],
]

NAGA = {
    "b": "#2fa86a", "d": "#1a5c42", "l": "#8fe8ae", "a": "#f2c230", "k": "#12301f", "e": "#17110c",
    "n": "#12301f", "w": "#ffffff", "y": "#ffd23f", "G": "#ffe88a", "r": "#e0334a", "u": "#3a8fe8",
    "p": "#e8506a", "h": "#17604e", "i": "#26896a", "q": "#ffffff",
}

SPECIES["naga"] = {"palette": NAGA, "patches": legend(NAGA_ART, 0, "b")}
