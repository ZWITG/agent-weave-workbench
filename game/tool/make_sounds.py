"""Synthesises Relivable's original sound effects into assets/sounds.

Run from the game folder:  python3 tool/make_sounds.py
Every sound is generated from sine, triangle and noise sources here, so
there are no third-party samples or licences to track.
"""

import os
import wave

import numpy as np

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'sounds')
rng = np.random.default_rng(7)


def t(sec):
    return np.arange(int(RATE * sec)) / RATE


def note(name):
    names = {'C': -9, 'D': -7, 'E': -5, 'F': -4, 'G': -2, 'A': 0, 'B': 2}
    base = names[name[0]]
    i = 1
    if name[1] in '#b':
        base += 1 if name[1] == '#' else -1
        i = 2
    octave = int(name[i:])
    return 440.0 * 2 ** ((base + (octave - 4) * 12) / 12)


def env(n, attack=0.005, decay=0.2, sustain=0.0, release=0.05):
    """Attack, exponential decay towards sustain, short release."""
    x = np.arange(n) / RATE
    a = np.clip(x / max(attack, 1e-4), 0, 1)
    d = sustain + (1 - sustain) * np.exp(-x / max(decay, 1e-4))
    e = a * d
    r = int(RATE * release)
    if r and r < n:
        e[-r:] *= np.linspace(1, 0, r)
    return e


def tone(freq, sec, kind='sine', **kw):
    x = t(sec)
    ph = 2 * np.pi * freq * x
    if kind == 'tri':
        w = 2 / np.pi * np.arcsin(np.sin(ph))
    elif kind == 'square':
        w = np.tanh(4 * np.sin(ph))
    elif kind == 'bell':
        # Inharmonic partials like a small bell.
        w = (np.sin(ph) + 0.5 * np.sin(2.76 * ph) + 0.25 * np.sin(5.4 * ph)) / 1.75
    else:
        w = np.sin(ph)
    return w * env(len(x), **kw)


def glide(f0, f1, sec, kind='sine', **kw):
    x = t(sec)
    f = np.geomspace(f0, f1, len(x))
    ph = 2 * np.pi * np.cumsum(f) / RATE
    w = np.sin(ph) if kind == 'sine' else 2 / np.pi * np.arcsin(np.sin(ph))
    return w * env(len(x), **kw)


def noise(sec, **kw):
    return rng.uniform(-1, 1, int(RATE * sec)) * env(int(RATE * sec), **kw)


def lowpass(x, alpha):
    y = np.zeros_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += alpha * (v - acc)
        y[i] = acc
    return y


def seq(parts, gap):
    """Lay sounds out one after another, overlapping by their tails."""
    total = int(RATE * gap * (len(parts) - 1)) + max(len(p) for p in parts)
    out = np.zeros(total)
    for k, p in enumerate(parts):
        s = int(RATE * gap * k)
        out[s:s + len(p)] += p
    return out


def mix(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[:len(p)] += p
    return out


def save(name, x, gain=0.8):
    x = x / (np.max(np.abs(x)) or 1) * gain
    data = (x * 32767).astype('<i2').tobytes()
    with wave.open(os.path.join(OUT, f'{name}.wav'), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data)


def jingle(hits, sec):
    out = np.zeros(int(RATE * sec))
    for k in range(hits):
        at = int(RATE * k * 0.045)
        b = tone(rng.uniform(2500, 5000), 0.18, 'bell', decay=0.05)
        out[at:at + len(b)] += b[:len(out) - at]
    return out


def applause(sec, claps):
    out = np.zeros(int(RATE * sec))
    for _ in range(claps):
        at = int(rng.uniform(0, sec - 0.03) * RATE)
        c = lowpass(noise(0.025, decay=0.006), 0.7)
        out[at:at + len(c)] += c * rng.uniform(0.4, 1)
    return out * np.linspace(1, 0.2, len(out))


sounds = {
    # Money in: two bright coin pings.
    'coin': seq([tone(note('B5'), 0.18, 'square', decay=0.06),
                 tone(note('E6'), 0.3, 'square', decay=0.12)], 0.07),
    # Money out: a soft falling pluck.
    'spend': glide(note('E5'), note('A4'), 0.22, 'tri', decay=0.08),
    # Buying something: a till drawer and a bell.
    'purchase': mix(lowpass(noise(0.08, decay=0.02), 0.5) * 0.6,
                    seq([tone(note('C6'), 0.5, 'bell', decay=0.25),
                         tone(note('G6'), 0.5, 'bell', decay=0.25)], 0.06)),
    # Promotion, award: a short rising fanfare.
    'promote': seq([tone(note(n), 0.35, 'tri', decay=0.18)
                    for n in ['C5', 'E5', 'G5', 'C6']], 0.09),
    # Births, weddings, big good news: a sparkling chime.
    'celebrate': mix(
        seq([tone(note(n), 0.6, 'bell', decay=0.3)
             for n in ['G5', 'B5', 'D6', 'G6', 'B6']], 0.07),
        lowpass(noise(1.0, decay=0.4), 0.9) * 0.08),
    # Loss: a slow, low minor fall.
    'sad': seq([tone(note(n), 0.9, 'sine', attack=0.05, decay=0.5)
                for n in ['A4', 'F4', 'D4']], 0.32),
    # Arrest: a two-tone siren.
    'siren': 0.7 * np.concatenate([glide(700, 950, 0.3, decay=5, release=0.02),
                             glide(950, 700, 0.3, decay=5, release=0.02)] * 2)
    * np.linspace(1, 0.4, int(RATE * 0.3) * 4),
    # Big news pop-up: ding-dong.
    'news': seq([tone(note('E5'), 0.5, 'bell', decay=0.25),
                 tone(note('C5'), 0.6, 'bell', decay=0.3)], 0.2),
    # Panels opening: a soft whoosh.
    'whoosh': lowpass(noise(0.3, attack=0.12, decay=0.1), 0.15),
    # Mini-games.
    'hit': mix(tone(180, 0.1, decay=0.03), lowpass(noise(0.04, decay=0.01), 0.6) * 0.5),
    'miss': glide(220, 140, 0.18, 'tri', decay=0.08),
    'win': seq([tone(note(n), 0.25, 'square', decay=0.1)
                for n in ['E5', 'G5', 'C6']], 0.08),
    'lose': glide(note('G4'), note('C4'), 0.55, 'tri', decay=0.3),
    'tick': mix(tone(1500, 0.05, decay=0.01), tone(900, 0.05, decay=0.015)),
    # New home: keys jingling.
    'keys': jingle(8, 0.7),
    # Fame: a crowd cheer and applause.
    'cheer': mix(lowpass(noise(1.3, attack=0.25, decay=0.6), 0.08) * 1.2,
                 applause(1.3, 70) * 0.5),
    # Illness: a slow heartbeat.
    'heartbeat': seq([tone(60, 0.18, decay=0.06), tone(55, 0.18, decay=0.06),
                      np.zeros(int(RATE * 0.1)),
                      tone(60, 0.18, decay=0.06), tone(55, 0.18, decay=0.06)], 0.14),
}

if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    for name, x in sounds.items():
        save(name, x)
        print(f'{name}: {len(x) / RATE:.2f}s')
