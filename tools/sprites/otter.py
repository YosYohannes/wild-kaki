FRAMES = [
    [
        ".....................bb.....",
        "..........bggggggg..bbbHbb..",
        ".........bbbbbbbbbbbbbbbebb.",
        "........bbbbbbbbbbbbbbbbllln",
        "........bbbbbbbbbbbbbblllllw",
        ".......bbbbbbbbbbbbblllllww.",
        "......bbbbbbbbbbbbblllll....",
        ".....bbbbbbbbbbbbbbllll.....",
        "...bbbbbbddddddddddlll......",
        "dbbbbbbd..bbb.dd.dd.bbb.....",
        ".dddddd...bbb.dd.dd.bbb.....",
        "..........kkk.dd.dd.kkk.....",
    ],
    [
        "............bgggb....bb.....",
        "..........bbbbbbbb..bbbHbb..",
        ".........bbbbbbbbbbbbbbbebb.",
        "........bbbbbbbbbbbbbbbbllln",
        "........bbbbbbbbbbbbbblllllw",
        ".......bbbbbbbbbbbbblllllww.",
        "db....bbbbbbbbbbbbblllll....",
        ".dbbbbbbbbbbbbbbbbbllll.....",
        "..dbbbbbbddddddddddlll......",
        "...ddddd..dd.bbb.bbb..dd....",
        "..........dd.bbb.bbb..dd....",
        "..........dd.kkk.kkk..dd....",
    ],
]

OTTER = {
    "b": "#6e4a2e", "d": "#4b3220", "l": "#e8d6aa", "g": "#8f6540", "k": "#3a2616",
    "e": "#17110c", "n": "#17110c", "w": "#f6ecd4",
}

SPECIES = {
    "otter": {"palette": OTTER},
    "beaver": {
        "palette": {
            **OTTER, "b": "#6b3f22", "d": "#47280f", "l": "#7d4d2b", "g": "#85532f", "q": "#1c1819", "t": "#46403f",
            "o": "#f08a24",
        },
        "patches": [
            (None, 0, 5, ["--------", "--------", "--------", "--------", "--------", "--------", "--------"]),
            (None, 12, -1, ["bbbb"]),
            (None, 10, 0, ["bggggggb"]),
            (None, 9, 1, ["bbbbbbbbbbb"]),
            (None, 25, 5, ["--"]),
            (None, 7, 6, ["b", "b", "b"]),
            (None, 9, 8, ["bbbbbbbbbb"]),
            (None, 9, 9, ["dddddddddd"]),
            (None, 27, 4, ["o", "o"]),
            (None, 0, 8, ["..qtqtqt.", ".qtqtqtqt", "qtqtqtqtq", ".qtqtqtq."]),
        ],
    },
}

COLOURS = {}


def legend(art, x, fill="b"):
    patches = [(None, 0, 0, ["-" * 29] * 12)]
    for f, rows in enumerate(art):
        top = 12 - len(rows)
        patches.append((f, x, top, [r.replace("H", fill) for r in rows]))
        for j, r in enumerate(rows):
            if "H" in r:
                patches.append((f, x + r.index("H"), top + j, "H"))
    return patches


KAPPA_ART = [
    [
        "........WcqcHcccW.",
        "........CWWWWWWWC.",
        "........aaaaaaaa..",
        ".......abbbbbbbb..",
        ".......bbbbwebbb..",
        ".......bbbbbbbyyyy",
        ".......dbbbbbbYYY.",
        "...jjjjhdbbbbb....",
        "..jggggghbbbbbb...",
        ".jgghgghgbbllbb...",
        ".jghgghgghblllbk..",
        ".ggghgghgghllbbk..",
        "..hgghgghghdbbb...",
        "...hhhhhhh.dbb....",
        "...........bb.bb..",
        "..........bkb.bkb.",
        "..........kkk.kkk.",
    ],
    [
        "........WcqcHcccW.",
        "........CWWWWWWWC.",
        "........aaaaaaaa..",
        ".......abbbbbbbb..",
        ".......bbbbwebbb..",
        ".......bbbbbbbyyyy",
        ".......dbbbbbbYYY.",
        "...jjjjhdbbbbb....",
        "..jggggghbbbbbb...",
        ".jgghgghgbbllbb...",
        ".jghgghgghblllbk..",
        ".ggghgghgghllbbk..",
        "..hgghgghghdbbb...",
        "...hhhhhhh.dbb....",
        "...........bbb.b..",
        "...........bkb.bk.",
        "...........kkk.kk.",
    ],
]

KAPPA = {
    "b": "#58b04a", "d": "#357a35", "l": "#d3e58f", "a": "#1d4a3a", "k": "#244a2a",
    "e": "#17110c", "n": "#17110c", "w": "#ffffff",
    "y": "#f2c43a", "Y": "#c8962a", "g": "#9c7a42", "h": "#6a4e28", "j": "#cfa766",
    "c": "#79e4ff", "q": "#d9fbff", "W": "#c7e3f0", "C": "#7fa6bd",
}

SPECIES["kappa"] = {"palette": KAPPA, "patches": legend(KAPPA_ART, 5, "c")}

MERLION_ART = [
    [
        ".............lll.........",
        "..........llnnlll........",
        ".........lllllnllnl......",
        "......ppwnllllnllnll.....",
        "......pppwnlllnlnnll.....",
        "......pppnwnnnlnnlnnn....",
        "......nnwwwwnnnnnnwwppw..",
        ".....lnwwwwwwHnwwwwpppw..",
        "....lnwwwwwwwwwwwwwwpp...",
        "...llwwwwwwwwwwwwwwwnn...",
        "..llnwwwwnnwwwwwwwwwnl...",
        ".lllnwwwwnnwwwwnnwwwwnl..",
        ".lllmwppwwwwnwwnnwppwnl..",
        ".llmnwwwwwwnpnwwwwwwwnl..",
        "..nlnwppwwwwpwwwwwppnlll.",
        "..lllnwwwwwwwwwwwwwwnlll.",
        "...lllnnnnnnwwwwwwwnllll.",
        "....llnnwwwnnnnnnnlllmll.",
        "......lnwwwwwwwnwwnll....",
        ".......wwwwwwwwnwww......",
        "...l...wwwwwwww..........",
        "..ll...wwwwwwww..........",
        "..lln..wwwwwww...........",
        ".lllwwwwwwwww............",
        "......wwwwww.............",
        "aafaaaafaaaafaaaafaaaafaa",
        "aaaaaaaaaaaaaaaaaaaaaaaaa",
    ],
    [
        ".............lll.........",
        "..........llnnlll........",
        ".........lllllnllnl......",
        "......ppwnllllnllnll.....",
        "......pppwnlllnlnnll.....",
        "......pppnwnnnlnnlnnn....",
        "......nnwwwwnnnnnnwwppw..",
        ".....lnwwwwwwHnwwwwpppw..",
        "....lnwwwwwwwwwwwwwwpp...",
        "...llwwwwwwwwwwwwwwwnn...",
        "..llnwwwwnnwwwwwwwwwnl...",
        ".lllnwwwwnnwwwwnnwwwwnl..",
        ".lllmwppwwwwnwwnnwppwnl..",
        ".llmnwwwwwwnpnwwwwwwwnl..",
        "..nlnwppwwwwpwwwwwppnlll.",
        "..lllnwwwwwwwwwwwwwwnlll.",
        "...lllnnnnnnwwwwwwwnllll.",
        "....llnnwwwnnnnnnnlllmll.",
        "......lnwwwwwwwnwwnll....",
        ".......wwwwwwwwnwww......",
        "...l...wwwwwwww..........",
        "..ll...wwwwwwww..........",
        "..lln..wwwwwww...........",
        ".lllwwwwwwwww............",
        "......wwwwww.............",
        "......wwwwww.............",
        "afaaaafaaaafaaaafaaaafaaa",
        "aaaaaaaaaaaaaaaaaaaaaaaaa",
    ],
]

MERLION = {
    "b": "#ffffff", "d": "#dbe9f5", "g": "#7cc4ec", "k": "#1d4a7a", "e": "#1d2a44", "o": "#1d4a7a",
    "w": "#ffffff", "l": "#c6e8f8", "m": "#7cc4ec", "n": "#1d4a7a", "p": "#f2819a", "a": "#5aa9e6", "f": "#e3f4fc",
}

SPECIES["merlion"] = {"palette": MERLION, "patches": legend(MERLION_ART, 1, "w")}
