STAND = [
    "....................",
    "...........bHb......",
    "..........bbbbb.....",
    "..........fffefyy...",
    "......bbbbfffffy....",
    ".....bbbbbaaaaa.....",
    "...bbddddddaaaa.....",
    "ttttbddddddaaaa.....",
    "kkttbdddddlllll.....",
    ".....lllllllll......",
    ".......lllllll......",
    "........s..s........",
    "........ss.ss.......",
]


def hop(rows):
    return rows[1:-1] + [rows[-2], rows[-1]]


FRAMES = [STAND, hop(STAND)]


def body(x, y, rows):
    return [(0, x, y, rows), (1, x, y - 1, rows)]


def patches(*parts):
    return [p for part in parts for p in part]


SPARROW = {
    "b": "#9a6234", "d": "#5c3a20", "l": "#dccaa2", "a": "#2f2820", "f": "#d8cba8", "c": "#8d9097",
    "t": "#7a5230", "k": "#2f2218", "e": "#14100c", "y": "#a8895a", "s": "#b88a6a",
}

ROBIN = {
    "b": "#8a7556", "d": "#6a5840", "l": "#f0e8d6", "a": "#e5602a", "f": "#e5602a",
    "t": "#6a5840", "k": "#3a2e22", "e": "#14100c", "y": "#6a5a48", "s": "#b88a7a",
}

MYNA = {
    "b": "#9a5a2e", "d": "#6e3d1e", "l": "#b87a46", "a": "#a8683a", "f": "#15110f", "w": "#f4f0e6",
    "t": "#6e3d1e", "k": "#2a1a10", "e": "#f4f0e6", "y": "#e8b020", "s": "#e0a820",
}

PIGEON = {
    "b": "#9aa1ae", "d": "#7a8190", "l": "#b4bac6", "a": "#8a5aa8", "f": "#a8aebb", "g": "#3fa07a", "w": "#f4f4f6",
    "t": "#7a8190", "k": "#2f3440", "e": "#e0662a", "y": "#5a5a66", "s": "#d0506a",
}

CROW = {
    "b": "#262b38", "d": "#3a4256", "l": "#2e3342", "a": "#262b38", "f": "#262b38",
    "t": "#2e3342", "k": "#161a22", "e": "#d8d4c8", "y": "#4a505e", "s": "#3a3e48",
}

SWALLOW = {
    "b": "#2a4fb0", "d": "#1a2f78", "l": "#f4ead6", "a": "#c8432a", "f": "#2a4fb0",
    "t": "#2a4fb0", "k": "#0f1a4a", "e": "#e8e4dc", "y": "#5a4a3a", "s": "#6a5a4a",
}

MAGPIE = {
    "b": "#1c1e26", "d": "#2a4a82", "l": "#f5f5f2", "a": "#1c1e26", "f": "#1c1e26", "w": "#f5f5f2",
    "t": "#1f6a6a", "k": "#143a46", "e": "#f2f2f2", "y": "#3a3f4a", "s": "#3a3f4a",
}

KINGFISHER = {
    "b": "#2f8fd8", "d": "#1f5aa8", "l": "#ec8a2c", "a": "#ec8a2c", "f": "#ec8a2c", "w": "#f6f2e6",
    "t": "#1f5aa8", "k": "#143a70", "e": "#14100c", "y": "#1c1c24", "s": "#d9402c",
}

SPECIES = {
    "sparrow": {
        "palette": SPARROW,
        "patches": patches(
            body(10, 1, [".ccc.", "ccccc"]),
            body(6, 4, [".d.d"]),
            body(5, 5, ["d.d.d"]),
            body(11, 7, ["llll"]),
        ),
    },
    "robin": {
        "palette": ROBIN,
        "patches": patches(
            body(-1, 5, ["kk...", ".tt..", ".-...", ".--.."]),
        ),
    },
    "myna": {
        "palette": MYNA,
        "patches": patches(
            body(0, 1, [
                "...........fff....",
                "..........-ffff...",
                "..........-.y.....",
                "......--...yy..-.y",
                ".....--...........",
                "...---............",
                "-----..www........",
                "---.....ww........",
                "..ttb.............",
                ".tt.bbl.s--s--....",
                "kk................",
            ]),
        ),
    },
    "pigeon": {
        "palette": PIGEON,
        "patches": patches(
            body(8, 4, ["gg"]),
            body(8, 5, ["gg"]),
            body(15, 3, ["w"]),
            body(15, 5, ["a", "a", "a", "l"]),
            body(14, 9, ["ll"]),
            body(14, 10, ["l"]),
            body(6, 11, ["lllllllll"]),
            body(-1, 7, ["tk"]),
            body(-1, 8, ["k"]),
            body(-1, 9, ["kkttt"]),
            body(6, 6, ["k.k", "k.k"]),
        ),
    },
    "crow": {
        "palette": CROW,
        "patches": patches(
            body(15, 2, ["y"]),
            body(16, 3, ["yy"]),
            body(16, 4, ["yy"]),
            body(15, 5, ["a", "a", "a", "a"]),
            body(7, 10, ["-s--s--"]),
            body(-2, 7, ["tt", "kk"]),
            body(0, 9, ["ttkk"]),
        ),
    },
    "swallow": {
        "palette": SWALLOW,
        "patches": patches(
            body(11, 4, ["aaaa"]),
            body(11, 6, ["bbbb"]),
            body(11, 7, ["llll"]),
            body(13, 2, ["aa"]),
            body(1, 7, ["dddd"]),
            body(3, 8, ["dd"]),
            body(-5, 6, ["kkttt...", "....t...", ".....--.", "....tttt", "kkttt..."]),
        ),
    },
    "magpie": {
        "palette": MAGPIE,
        "patches": patches(
            body(6, 6, ["wwww"]),
            body(6, 7, ["www"]),
            body(-5, 7, ["kkttt", ".kttt"]),
        ),
    },
    "kingfisher": {
        "palette": KINGFISHER,
        "patches": patches(
            body(10, 1, ["b...b"]),
            body(9, 2, ["b"]),
            body(9, 3, ["f"]),
            body(16, 3, ["yyyy"]),
            body(16, 4, ["yy"]),
            body(0, 7, ["--", "--"]),
            body(13, 4, ["ww"]),
        ),
    },
}

COLOURS = {
    "white-pigeon": {
        "b": "#f4f6f8", "d": "#dde2ea", "l": "#ffffff", "a": "#f0eef6", "f": "#f8fafc", "g": "#e8f2ee",
        "t": "#dde2ea", "k": "#c8cfdb", "y": "#e8a8a8", "s": "#e8808c",
    },
    "golden-kingfisher": {
        "b": "#e8b028", "d": "#b8801c", "l": "#f6d870", "a": "#f0c040", "f": "#f6d870",
        "t": "#b8801c", "k": "#7a5410", "y": "#5a3c14", "s": "#c07a20",
    },
}
