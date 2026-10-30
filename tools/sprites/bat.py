FRAMES = [
    [
        "............................",
        "............................",
        "............................",
        "f..........................f",
        ".ffm....................mff.",
        "..mfff.......kb..bk...fffm..",
        "...mffm......bb..bb..mffm...",
        "..mfmfffm....bbbHbbb..fmfm..",
        "..fmmffmff...bbbbbebb..mmf..",
        ".fmmmfmfmmff..bbbbbbbn.mmmf.",
        "fmmmmfmfmmmmf.bbbbbbb..mmmmf",
        "...mfmmmfmmmm.bbbbb...mfm...",
        "....fmmmfmmmbbbbbbbfmmmf....",
        "....fmmmmfmmbbbbbbfmmmmf....",
        "....fmmm.f.mbbbbb.f.mmmf....",
        "....fm....fm.bbbmf....mf....",
        ".............kbk............",
        ".............k.k............",
    ],
    [
        "............................",
        "............................",
        "............................",
        "............................",
        "............................",
        ".............kb..bk.........",
        ".............bb..bb.........",
        ".............bbbHbbb........",
        ".....fffm....bbbbbebb.......",
        "..fffffmfffm..bbbbbbbn.fff..",
        "ffmmffmfmmmff.bbbbbbb..fmmff",
        ".m.fmfmfmmmmm.bbbbb...fmf.m.",
        "..fmmfmmfmmmbbbbbbbfmmfmmf..",
        ".fmmfmmmfmmmbbbbbbmfmmmfmmf.",
        "fmmmfmmm.fmmbbbbbmf.mmmfmmmf",
        "...mfmm.mfmmmbbbmmfm.mmfm...",
        "...fmm....fm.kbkmf....mmf...",
        "...f.........k.k........f...",
    ],
]

FRUIT = {
    "b": "#5b3a28", "d": "#4a3226", "l": "#e6c79a", "a": "#c98240", "k": "#2e2016", "e": "#14100c",
    "n": "#14100c", "m": "#473632", "f": "#7a6055", "p": "#d89090",
}

PIPI = {
    "b": "#4a3426", "d": "#3a281c", "l": "#d8b080", "a": "#c8803c", "k": "#2a1c14", "e": "#14100c",
    "n": "#14100c", "m": "#3e2f2b", "f": "#5e4a40", "p": "#d89090",
}

VAMPIRE_0 = [
    "............................",
    "............................",
    "............................",
    "............................",
    "c..........................c",
    "cc........................cc",
    "crc..........kb..bk......crc",
    "crrcc........bb..bb....ccrrc",
    "crrrrcc......bbbHbbb.ccrrrrc",
    ".crrrrrcc....bbbbbebcrrrrrc.",
    ".crrrrrrrcc...bbbbbbbnrrrrc.",
    "..crrrrrrrrcc.bbbbwbwrrrrc..",
    "..crrrrrrrrrccccccccccrrrc..",
    "...crrrrrrrrcccqqcccrrrrc...",
    "...crrrrrrrrccccccccrrrrc...",
    "....crrrrrrcccccccccrrrc....",
    "....cc.crrcc.cccccccc.cc....",
    ".............ccccccc........",
]

VAMPIRE_1 = [
    "............................",
    "............................",
    "............................",
    "............................",
    "............................",
    ".............kb..bk.........",
    ".............bb..bb.........",
    ".............bbbHbbb........",
    ".............bbbbbeb........",
    "c.............bbbbbbbn.....c",
    "ccc...........bbbbwbw....ccc",
    "crrccc......cccccccccccccrrc",
    "crrrrrccc....ccqqcccccrrrrrc",
    ".crrrrrrrcc..cccccccrrrrrrc.",
    ".crrrrrrrrrcccccccccrrrrrrc.",
    "..crrrrrrrrrccccccccrrrrrc..",
    "..ccrrrrrrrcccccccccrrrrcc..",
    "...c.ccrrccc.cccccccrcc.c...",
]

VAMPIRE = {
    "b": "#b6a6c6", "d": "#8c7ca0", "k": "#1c1624", "c": "#2a2036", "r": "#b3182e", "q": "#ffc83a",
    "e": "#ff3a4a", "w": "#ffffff", "n": "#d86a86", "l": "#d8cce0", "f": "#b3182e", "m": "#2a2036",
}

SPECIES = {
    "fruit-bat": {
        "palette": FRUIT,
        "patches": [
            (None, 12, 7, [
                ".aaaaaaa.",
                ".aaaaa.aa",
                "..aaallll",
                "..aaalll.",
                "..aaaaa..",
                "aaaaaaa..",
                "aaaaa....",
            ]),
        ],
    },
    "pipistrelle": {
        "palette": PIPI,
        "patches": [
            (0, 0, 3, [
                "----------------------------",
                "----------------------------",
                "---fm------------------mf---",
                "----fm----------------mf----",
                "----mff--------------ffm----",
                "-----mmfm-----------fmm-----",
                "----mffffm---bb--bb-fffm----",
                "----fmmfmff--bbbbbb--mmf----",
                "---fm-mfmmmf-bbbbebp-m-mf---",
                "-----mfmmmmm--bbbbb--fm-----",
                "------fmmm-mm-bbbb--mf------",
                "------fmm-m-mmbbbb-mmf------",
                "------f----mmmbbb----f------",
                "--------------k-k-----------",
                "--------------k-k-----------",
            ]),
            (1, 0, 3, [
                "----------------------------",
                "----------------------------",
                "----------------------------",
                "----------------------------",
                "----------------------------",
                "----------------------------",
                "-------------bb--bb---------",
                "-------ffm---bbbbbb---------",
                "-----ffffffm-bbbbebp-ff-----",
                "---ffmffmmmf--bbbbb--fmff---",
                "-----fmfmmmmm-bbbb--fmf-----",
                "----fmfmmmmmmmbbbbmmmfmf----",
                "---fmmfmmm-mmmbbb-mmmfmmf---",
                "-----fmm--mmm-kmkm--mmf-----",
                "-----f--------k-k-----f-----",
            ]),
            (0, 16, 10, "H"),
            (1, 16, 10, "H"),
        ],
    },
    "vampire": {
        "palette": VAMPIRE,
        "patches": [
            (None, 0, 0, ["-" * 28] * 18),
            (0, 0, 0, VAMPIRE_0),
            (1, 0, 0, VAMPIRE_1),
        ],
    },
}

COLOURS = {}
