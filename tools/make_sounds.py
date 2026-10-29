#!/usr/bin/env python3
"""Writes the tap sounds missing from assets/sounds (yip, quack and tweet are hand-kept)."""
import math
import struct
import wave
from pathlib import Path

RATE = 22050
PEAK = 0.35
OUT = Path(__file__).resolve().parent.parent / "assets" / "sounds"


class Lcg:
    def __init__(self, seed):
        self.state = seed

    def next(self):
        self.state = (self.state * 1664525 + 1013904223) & 0xFFFFFFFF
        return (self.state >> 8) / (1 << 23) - 1.0


def lerp(a, b, t):
    return a + (b - a) * t


def env(t, dur, attack, release):
    if t < attack:
        return t / attack
    left = dur - t
    return min(1.0, left / release) if left < release else 1.0


def decay(t, rate):
    return math.exp(-rate * t)


def osc(kind, phase):
    p = phase % 1.0
    if kind == "square":
        return 1.0 if p < 0.5 else -1.0
    if kind == "pulse":
        return 1.0 if p < 0.25 else -1.0
    if kind == "saw":
        return 2.0 * p - 1.0
    if kind == "tri":
        return 4.0 * abs(p - 0.5) - 1.0
    return math.sin(2 * math.pi * p)


def lowpass(samples, cutoff):
    a = 1.0 - math.exp(-2 * math.pi * cutoff / RATE)
    out, y = [], 0.0
    for x in samples:
        y += a * (x - y)
        out.append(y)
    return out


def highpass(samples, cutoff):
    low = lowpass(samples, cutoff)
    return [x - l for x, l in zip(samples, low)]


def tone(kind, f0, f1, dur, attack=0.005, release=0.02, rate=0.0, vibrato=None, curve=None):
    n = int(dur * RATE)
    out, phase = [], 0.0
    for i in range(n):
        t = i / RATE
        u = i / max(1, n - 1)
        if curve is not None:
            f = curve(u)
        else:
            f = lerp(f0, f1, u)
        if vibrato:
            depth, speed = vibrato
            f *= 1.0 + depth * math.sin(2 * math.pi * speed * t)
        phase += f / RATE
        out.append(osc(kind, phase) * env(t, dur, attack, release) * decay(t, rate))
    return out


def noise(dur, seed, attack=0.005, release=0.02, rate=0.0, shape=None):
    rng = Lcg(seed)
    n = int(dur * RATE)
    out = []
    for i in range(n):
        t = i / RATE
        e = env(t, dur, attack, release) * decay(t, rate)
        if shape:
            e *= shape(i / max(1, n - 1))
        out.append(rng.next() * e)
    return out


def silence(dur):
    return [0.0] * int(dur * RATE)


def mix(*parts):
    n = max(len(p) for p in parts)
    out = [0.0] * n
    for p in parts:
        for i, x in enumerate(p):
            out[i] += x
    return out


def seq(*parts):
    out = []
    for p in parts:
        out.extend(p)
    return out


def scale(samples, k):
    return [x * k for x in samples]


def finish(samples):
    fade = int(0.006 * RATE)
    n = len(samples)
    for i in range(min(fade, n)):
        samples[n - 1 - i] *= i / fade
        samples[i] *= min(1.0, i / (0.002 * RATE))
    top = max(abs(x) for x in samples)
    return [x * PEAK / top for x in samples]


def write(name, samples):
    samples = finish(samples)
    data = b"".join(struct.pack("<h", round(x * 32767)) for x in samples)
    with wave.open(str(OUT / f"{name}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data)


def woof():
    def bark(f0, f1):
        body = lowpass(tone("square", f0, f1, 0.11, 0.004, 0.04, rate=9), 1500)
        return body
    return seq(bark(230, 130), silence(0.045), bark(200, 110))


def meow():
    def glide(u):
        return lerp(420, 760, u / 0.4) if u < 0.4 else lerp(760, 460, (u - 0.4) / 0.6)
    a = tone("saw", 0, 0, 0.4, 0.05, 0.12, curve=glide, vibrato=(0.015, 7))
    b = tone("sine", 0, 0, 0.4, 0.05, 0.12, curve=glide, vibrato=(0.015, 7))
    return lowpass(mix(scale(a, 0.5), b), 2200)


def thump():
    body = tone("square", 120, 42, 0.16, 0.003, 0.05, rate=14)
    sub = tone("sine", 90, 38, 0.16, 0.003, 0.05, rate=10)
    return lowpass(mix(scale(body, 0.5), sub), 400)


def huff():
    puff = noise(0.2, 7, 0.03, 0.09, shape=lambda u: math.sin(math.pi * u) ** 0.8)
    return lowpass(lowpass(puff, 1200), 1600)


def bark():
    body = tone("pulse", 640, 430, 0.12, 0.003, 0.04, rate=11)
    grit = noise(0.04, 11, 0.002, 0.02, rate=40)
    return lowpass(mix(body, scale(grit, 0.3)), 2400)


def chk():
    def tick(seed, f):
        t = tone("square", f, f * 0.7, 0.013, 0.001, 0.006, rate=100)
        n = noise(0.013, seed, 0.0005, 0.006, rate=100)
        return highpass(mix(scale(t, 0.7), scale(n, 0.6)), 600)
    gap = silence(0.04)
    return seq(tick(21, 2000), gap, tick(22, 1800), gap, tick(23, 2100))


def squeak():
    a = tone("sine", 900, 2000, 0.17, 0.01, 0.05, rate=4)
    b = tone("tri", 900, 2000, 0.17, 0.01, 0.05, rate=4)
    return lowpass(mix(a, scale(b, 0.3)), 4000)


def click():
    def one(seed):
        t = tone("square", 2600, 1500, 0.02, 0.0005, 0.008, rate=90)
        n = noise(0.02, seed, 0.0005, 0.008, rate=90)
        return lowpass(highpass(mix(scale(t, 0.6), scale(n, 0.5)), 800), 5000)
    return seq(one(31), silence(0.09), one(32))


def hoo():
    def note(f0, f1):
        a = tone("sine", f0, f1, 0.17, 0.04, 0.07)
        b = tone("sine", f0 * 2, f1 * 2, 0.17, 0.04, 0.07)
        return mix(a, scale(b, 0.12))
    return seq(note(300, 280), silence(0.05), note(340, 250))


def eek():
    a = tone("sine", 2400, 4200, 0.1, 0.006, 0.04)
    b = tone("tri", 2400, 4200, 0.1, 0.006, 0.04)
    return lowpass(mix(a, scale(b, 0.25)), 6000)


def eep():
    def chirp(f0, f1):
        return tone("sine", f0, f1, 0.05, 0.004, 0.02)
    return seq(chirp(1500, 2300), silence(0.03), chirp(1700, 2600))


def snuff():
    def sniff(seed):
        n = noise(0.1, seed, 0.015, 0.05, shape=lambda u: 0.4 + 0.6 * math.sin(math.pi * min(1.0, u * 1.3)))
        band = highpass(lowpass(n, 1100), 250)
        return scale(band, 1.6)
    return seq(sniff(41), silence(0.06), sniff(42))


SOUNDS = {
    "woof": woof, "meow": meow, "thump": thump, "huff": huff, "bark": bark, "chk": chk,
    "squeak": squeak, "click": click, "hoo": hoo, "eek": eek, "eep": eep, "snuff": snuff,
}

if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for name, make in SOUNDS.items():
        write(name, make())
