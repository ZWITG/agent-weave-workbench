"""Builds the Relivable promo video: "One life, one take".

The whole promo is a single life. A large age ring (the game's own) ticks
from 0 to 87 in the corner while real gameplay plays in a phone: growing
up, activities, a mini-game, people, prison (the Lockdown takeover and the
inside tabs), release, the rise to the very top (Molten, the Invitation, a
new tier, the Echelon), then old age, the heir, what is out now and what
comes next ("Generation 2"). Each part of the life wears the game's look
for it: Night Feed, Yard Time (stencil type, cell bars slamming into the
backdrop) and Gilded (serif type, molten gold running down the backdrop).
The score is synthesised here and the game's own sound effects land on
their moments.

Run from the game folder after rendering the footage:
  flutter test tool/render_promo_test.dart --dart-define=OUT=<footage>
  flutter test tool/render_intro_test.dart --plain-name vertical --dart-define=OUT=<intro>
  python3 tool/make_promo_video.py <footage> <intro> media/relivable-promo.mp4
"""

import math
import os
import subprocess
import sys
import wave

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

FOOT, INTRO, OUT = sys.argv[1], sys.argv[2], sys.argv[3]
W, H, FPS = 1080, 1920, 30
HERE = os.path.dirname(os.path.abspath(__file__))
FONTS = os.path.join(HERE, '..', 'assets', 'fonts')
SOUNDS = os.path.join(HERE, '..', 'assets', 'sounds')


def font(name, size, weight=None):
    f = ImageFont.truetype(os.path.join(FONTS, name), size)
    if weight is not None:
        f.set_variation_by_axes([weight])
    return f


def sora(size, w=700):
    return font('Sora-Variable.ttf', size, w)


def serif(size, w=700):
    return font('PlayfairDisplay-Variable.ttf', size, w)


def stencil(size):
    return font('StardosStencil-Bold.ttf', size)


def chalk(size):
    return font('Caveat-Bold.ttf', size)


# ---------------- Looks (the game's three palettes) ----------------

LOOKS = {
    'night': dict(bg1=(15, 18, 32), bg2=(27, 32, 51), glow=(124, 156, 255),
                  glow2=(255, 184, 107), accent=(255, 184, 107), text=(238, 241, 250),
                  muted=(169, 176, 199)),
    'yard': dict(bg1=(13, 21, 18), bg2=(26, 41, 36), glow=(77, 122, 105),
                 glow2=(159, 224, 193), accent=(159, 224, 193), text=(229, 239, 234),
                 muted=(147, 168, 159)),
    'gold': dict(bg1=(6, 5, 4), bg2=(22, 18, 11), glow=(212, 175, 90),
                 glow2=(246, 227, 161), accent=(226, 184, 78), text=(243, 235, 216),
                 muted=(163, 149, 119)),
}


def mix(a, b, k):
    return tuple(int(a[i] + (b[i] - a[i]) * k) for i in range(3))


def backdrop(look, t):
    """A gradient with two slow glows, like the game's GlowBackground."""
    L = LOOKS[look]
    key = (look, int(t * 4) % 400)
    if key in _bd_cache:
        return _bd_cache[key].copy()
    img = Image.new('RGB', (W, H), L['bg1'])
    grad = np.linspace(0, 1, H)[:, None]
    arr = (np.array(L['bg1'])[None, None, :] * (1 - grad[..., None]) +
           np.array(L['bg2'])[None, None, :] * grad[..., None])
    arr = np.repeat(arr, W, axis=1)
    img = Image.fromarray(arr.astype(np.uint8))
    glow = Image.new('L', (W, H), 0)
    d = ImageDraw.Draw(glow)
    ph = t * 0.4
    for (cx, cy, r, a) in [(220 + 60 * math.sin(ph), 380, 520, 90),
                           (880 + 40 * math.cos(ph * 0.8), 1300, 460, 60)]:
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=a)
    glow = glow.filter(ImageFilter.GaussianBlur(160))
    tint = Image.new('RGB', (W, H), L['glow'])
    img = Image.composite(tint, img, glow.point(lambda v: v * 0.55))
    _bd_cache[key] = img
    return img.copy()


_bd_cache = {}


def backdrop_mix(a, b, k, t):
    if k <= 0:
        return backdrop(a, t)
    if k >= 1:
        return backdrop(b, t)
    return Image.blend(backdrop(a, t), backdrop(b, t), k)


# ---------------- The phone ----------------

PW, PH_ = 666, 1441
PX, PY = (W - PW) // 2 + 70, 400
_mask = Image.new('L', (PW, PH_), 0)
ImageDraw.Draw(_mask).rounded_rectangle((0, 0, PW - 1, PH_ - 1), 58, fill=255)


def phone(canvas, screen, look, zoom=1.0, dx=0, dy=0, shake=(0, 0)):
    L = LOOKS[look]
    sw, sh = screen.size
    if zoom != 1.0:
        cw, ch = sw / zoom, sh / zoom
        x0 = (sw - cw) / 2 + dx
        y0 = (sh - ch) / 2 + dy
        screen = screen.crop((int(x0), int(y0), int(x0 + cw), int(y0 + ch)))
    s = screen.resize((PW, PH_), Image.BILINEAR)
    x, y = PX + shake[0], PY + shake[1]
    # Glow and bezel.
    glow = Image.new('L', (W, H), 0)
    ImageDraw.Draw(glow).rounded_rectangle((x - 30, y - 30, x + PW + 30, y + PH_ + 30), 90, fill=150)
    glow = glow.filter(ImageFilter.GaussianBlur(40))
    canvas.paste(Image.new('RGB', (W, H), L['glow']), (0, 0), glow.point(lambda v: v * 0.5))
    ImageDraw.Draw(canvas).rounded_rectangle((x - 14, y - 14, x + PW + 14, y + PH_ + 14), 72,
                                             fill=(5, 6, 9), outline=mix(L['accent'], (0, 0, 0), 0.4), width=3)
    canvas.paste(s, (x, y), _mask)


# ---------------- The age ring (the game's own, writ large) ----------------

def age_ring(canvas, age, look, alpha=1.0, at=(150, 1040)):
    if alpha <= 0:
        return
    L = LOOKS[look]
    layer = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    (cx, cy), r = at, 112
    a = int(255 * alpha)
    d.ellipse((cx - r, cy - r, cx + r, cy + r), outline=L['muted'] + (int(a * 0.35),), width=10)
    frac = max(0.0, min(1.0, age / 100))
    if frac > 0:
        d.arc((cx - r, cy - r, cx + r, cy + r), -90, -90 + 360 * frac,
              fill=L['accent'] + (a,), width=12)
    f = sora(96, 800) if look == 'night' else (stencil(92) if look == 'yard' else serif(100, 800))
    txt = str(int(age))
    tw = d.textlength(txt, font=f)
    d.text((cx - tw / 2, cy - 62), txt, font=f, fill=L['text'] + (a,))
    lab = sora(24, 700)
    lw = d.textlength('AGE', font=lab)
    d.text((cx - lw / 2, cy - r - 52), 'AGE', font=lab, fill=L['accent'] + (a,))
    canvas.paste(layer, (0, 0), layer)


# ---------------- Captions ----------------

def caption(canvas, look, text, sub=None, k=1.0):
    """The caption band above the phone, in the look's own type."""
    if k <= 0:
        return
    L = LOOKS[look]
    layer = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    a = int(255 * k)
    rise = int((1 - k) * 24)
    if look == 'yard':
        f = stencil(64)
        text = text.upper()
    elif look == 'gold':
        f = serif(70, 700)
    else:
        f = sora(64, 800)
    y = 110 + rise
    for line in text.split('\n'):
        tw = d.textlength(line, font=f)
        d.text(((W - tw) / 2, y), line, font=f, fill=L['text'] + (a,))
        y += int(f.size * 1.18)
    if sub:
        sf = chalk(52) if look == 'yard' else sora(34, 500)
        tw = d.textlength(sub, font=sf)
        d.text(((W - tw) / 2, y + 6), sub, font=sf, fill=L['accent'] + (a,))
    canvas.paste(layer, (0, 0), layer)


# ---------------- Backdrop takeovers ----------------

def bars(canvas, k, look='yard'):
    """Cell bars dropping into the backdrop (k 0..1), heavy at the end."""
    if k <= 0:
        return
    d = ImageDraw.Draw(canvas)
    drop = min(1.0, k) ** 2
    for i in range(9):
        x = 40 + i * 125
        top = int(-H + drop * H)
        d.rectangle((x, top, x + 18, top + H), fill=(52, 70, 63))
        d.rectangle((x + 4, top, x + 8, top + H), fill=(150, 175, 165))
    for y0 in (300, 1600):
        y = int(y0 - H + drop * H)
        d.rectangle((0, y, W, y + 22), fill=(48, 62, 56))


def molten(canvas, k, t):
    """Molten gold running down the backdrop (k 0..1)."""
    if k <= 0:
        return
    rng = np.random.default_rng(9)
    d = ImageDraw.Draw(canvas)
    for i in range(26):
        x = int(rng.uniform(0, W))
        w = int(rng.uniform(3, 11))
        start = rng.uniform(0, 0.4)
        p = max(0.0, min(1.0, (k - start) / 0.55))
        y = int((H + 60) * p * p)
        if y <= 0:
            continue
        d.rectangle((x - w // 2, 0, x + w // 2, y), fill=(206, 160, 62))
        d.rectangle((x - w // 4, 0, x, y), fill=(255, 236, 170))
        d.ellipse((x - w, y - w * 2, x + w, y), fill=(255, 236, 170))


# ---------------- Full-screen cards ----------------

def card_bg(look, t):
    return backdrop(look, t)


def centered(d, y, text, f, fill):
    tw = d.textlength(text, font=f)
    d.text(((W - tw) / 2, y), text, font=f, fill=fill)


def ease(x):
    x = max(0.0, min(1.0, x))
    return 1 - (1 - x) ** 3


# ---------------- Footage ----------------

def still(name):
    return Image.open(os.path.join(FOOT, 'stills', name + '.png')).convert('RGB')


def clip_frames(name):
    d = os.path.join(FOOT, name)
    return [os.path.join(d, f) for f in sorted(os.listdir(d))]


# ---------------- The timeline ----------------
# Each beat: (kind, seconds, data). Ages tick between beats.

beats = []


def beat(kind, secs, **kw):
    beats.append(dict(kind=kind, secs=secs, **kw))


beat('intro', 3.4)
beat('hook', 3.0)
beat('still', 1.7, img='life_08', look='night', age=(1, 8), cap='Live a whole life,\none year at a time.')
beat('still', 1.8, img='event_0', look='night', age=(8, 11), cap='Every year asks\nyou something.')
beat('still', 1.6, img='event_1', look='night', age=(11, 14), cap='Every year asks\nyou something.', sub='And your choices come back later.')
beat('still', 1.5, img='life_17', look='night', age=(14, 17), cap='Grow up.')
beat('still', 1.6, img='event_2', look='night', age=(17, 21), cap='Mess up.')
beat('still', 1.5, img='life_24', look='night', age=(21, 24), cap='Start out.')
beat('still', 1.6, img='activities_0', look='night', age=(24, 25), cap='Swipe up:\n500+ things to do.')
beat('still', 1.3, img='activities_1', look='night', age=(25, 26), cap='Swipe up:\n500+ things to do.', zoom=1.05)
beat('still', 1.2, img='mini_0', look='night', age=(26, 27), cap='Mini-games\nfor everything.')
beat('still', 1.3, img='mini_1', look='night', age=(27, 28), cap='Mini-games\nfor everything.', zoom=1.06)
beat('still', 1.7, img='people', look='night', age=(28, 30), cap='People remember\nwhat you did.')
beat('clip', 4.9, clip='lockdown', look='night', to='yard', age=(31, 31), cap='Cross the line…', cap2='…and prison takes\nover the game.', slam=0.30 * 4.6 / 4.9 * 4.9, sfx=[(0.0, 'siren', 0.5), (1.38, 'clang', 1.0)])
beat('still', 1.3, img='prison_cell', look='yard', age=(31, 32), cap='Every tab\ngoes inside.', sub='2 years down, 2 to go')
beat('still', 1.2, img='prison_visits', look='yard', age=(32, 32), cap='Visiting room.')
beat('still', 1.2, img='prison_file', look='yard', age=(32, 33), cap='Case file.')
beat('still', 1.2, img='prison_canteen', look='yard', age=(33, 33), cap='Commissary.')
beat('still', 1.4, img='prison_id', look='yard', age=(33, 34), cap='Earn a yard name.', sub='a.k.a. "Books"')
beat('still', 1.7, img='prison_yard', look='yard', age=(34, 35), cap='The Yard.', zoom=1.08, dy=180)
beat('clip', 2.9, clip='release', look='yard', to='night', age=(35, 35), cap='Get out.', cap2='Start again.', sfx=[(0.1, 'gate', 0.9)])
beat('clip', 10.6, clip='molten', look='night', to='gold', age=(36, 46), cap='Or rise…', cap2='…to the very top.', molten=True,
     sfx=[(0.0, 'whoosh', 0.7), (4.05, 'coin', 0.8), (6.9, 'celebrate', 0.9)])
beat('clip', 2.7, clip='tier', look='gold', age=(46, 52), cap='Billionaire.', sfx=[(0.6, 'promote', 0.9)])
beat('still', 1.4, img='gilded_life', look='gold', age=(52, 53), cap='The whole game\nturns to gold.')
beat('still', 1.5, img='echelon_0', look='gold', age=(53, 55), cap='Climb the List.')
beat('still', 1.6, img='echelon_1', look='gold', age=(55, 58), cap='Rival tycoons.\nInfluence. Moonshots.')
beat('still', 1.6, img='echelon_2', look='gold', age=(58, 61), cap='Prepare your heirs.')
beat('features', 4.2, age=(61, 80))
beat('heir', 3.8, age=(80, 87))
beat('out', 3.4)
beat('next', 6.0)
beat('end', 4.2)

TOTAL = sum(b['secs'] for b in beats)

# ---------------- Rendering ----------------

intro_frames = sorted(os.listdir(os.path.join(INTRO, 'vertical')))


def render_card(b, lt, t):
    kind = b['kind']
    k = lt / b['secs']
    if kind == 'intro':
        i = min(len(intro_frames) - 1, int(lt * 60))
        img = Image.open(os.path.join(INTRO, 'vertical', intro_frames[i])).convert('RGB')
        if lt > b['secs'] - 0.4:
            img = Image.blend(img, Image.new('RGB', (W, H), (0, 0, 0)), (lt - (b['secs'] - 0.4)) / 0.4)
        return img
    if kind == 'hook':
        img = card_bg('night', t)
        d = ImageDraw.Draw(img)
        lines = ['What if every', 'choice you made', 'was remembered?']
        for i, line in enumerate(lines):
            a = ease((lt - i * 0.45) / 0.5)
            col = mix(LOOKS['night']['bg1'], LOOKS['night']['text'] if i < 2 else LOOKS['night']['accent'], a)
            centered(d, 700 + i * 120 + int((1 - a) * 30), line, sora(84, 800), col)
        age_ring(img, 0, 'night', ease(lt / 0.8), at=(W // 2, 1300))
        return img
    if kind == 'features':
        img = card_bg('gold', t)
        d = ImageDraw.Draw(img)
        centered(d, 330, 'One life.', serif(96, 800), LOOKS['gold']['text'])
        centered(d, 450, 'Every way to live it.', serif(64, 600), LOOKS['gold']['accent'])
        chips = ['School', 'Love', 'Careers', 'Business', 'Fame', 'Crime', 'Prison', 'Pets',
                 '24 countries', 'Heists', 'Health', 'Dynasties', 'A living world', 'Rich list']
        x, y = 90, 640
        for i, c in enumerate(chips):
            a = ease((lt - 0.4 - i * 0.12) / 0.35)
            f = sora(40, 600)
            w = d.textlength(c, font=f) + 56
            if x + w > W - 90:
                x, y = 90, y + 104
            if a > 0:
                d.rounded_rectangle((x, y + int((1 - a) * 20), x + w, y + 78 + int((1 - a) * 20)), 39,
                                    outline=mix(LOOKS['gold']['bg1'], LOOKS['gold']['accent'], a), width=3,
                                    fill=mix(LOOKS['gold']['bg1'], (28, 23, 14), a))
                d.text((x + 28, y + 14 + int((1 - a) * 20)), c, font=f,
                       fill=mix(LOOKS['gold']['bg1'], LOOKS['gold']['text'], a))
            x += w + 18
        age_ring(img, b['age'][0] + (b['age'][1] - b['age'][0]) * k, 'gold', at=(W // 2, 1560))
        return img
    if kind == 'heir':
        img = card_bg('night', t)
        d = ImageDraw.Draw(img)
        a1 = ease(lt / 0.6)
        a2 = ease((lt - 1.4) / 0.6)
        centered(d, 640, 'Age 87.', sora(96, 800), mix(LOOKS['night']['bg1'], LOOKS['night']['text'], a1))
        centered(d, 770, 'A life well lived.', sora(56, 500), mix(LOOKS['night']['bg1'], LOOKS['night']['muted'], a1))
        centered(d, 960, 'Then your daughter', sora(76, 800), mix(LOOKS['night']['bg1'], LOOKS['night']['text'], a2))
        centered(d, 1060, 'takes over.', sora(76, 800), mix(LOOKS['night']['bg1'], LOOKS['night']['accent'], a2))
        age_ring(img, b['age'][0] + (b['age'][1] - b['age'][0]) * ease(k * 1.4), 'night', at=(W // 2, 420))
        return img
    if kind == 'out':
        img = card_bg('night', t)
        d = ImageDraw.Draw(img)
        centered(d, 520, 'OUT NOW', sora(44, 800), LOOKS['night']['accent'])
        centered(d, 600, 'Relivable 1.0', sora(110, 800), LOOKS['night']['text'])
        plats = ['Android', 'iPhone', 'Windows', 'Web']
        for i, p in enumerate(plats):
            a = ease((lt - 0.3 - i * 0.18) / 0.4)
            y = 860 + i * 120
            d.rounded_rectangle((260, y + int((1 - a) * 24), 820, y + 92 + int((1 - a) * 24)), 46,
                                fill=mix(LOOKS['night']['bg1'], (35, 42, 69), a),
                                outline=mix(LOOKS['night']['bg1'], (74, 83, 120), a), width=2)
            centered(d, y + 18 + int((1 - a) * 24), p, sora(46, 700), mix(LOOKS['night']['bg1'], LOOKS['night']['text'], a))
        centered(d, 1400, 'Free. Plus unlocked for founders.', sora(38, 500), LOOKS['night']['muted'])
        return img
    if kind == 'next':
        img = card_bg('night', t)
        d = ImageDraw.Draw(img)
        centered(d, 300, 'GENERATION 2', sora(46, 800), LOOKS['night']['accent'])
        centered(d, 380, 'Coming next', sora(104, 800), LOOKS['night']['text'])
        items = [('App Store & Google Play', 'in the stores'),
                 ('Cloud saves', 'your dynasty on every device'),
                 ('Story Packs', 'film stardom, hospital nights, old money'),
                 ('Character art', 'faces for everyone you meet'),
                 ('More languages', 'Spanish, Portuguese, German, French'),
                 ('Friend challenges', 'same seed, different lives')]
        for i, (head, sub) in enumerate(items):
            a = ease((lt - 0.5 - i * 0.55) / 0.45)
            y = 600 + i * 168 + int((1 - a) * 30)
            d.ellipse((140, y + 20, 172, y + 52), fill=mix(LOOKS['night']['bg1'], LOOKS['night']['accent'], a))
            d.text((210, y), head, font=sora(52, 800), fill=mix(LOOKS['night']['bg1'], LOOKS['night']['text'], a))
            d.text((210, y + 68), sub, font=sora(34, 400), fill=mix(LOOKS['night']['bg1'], LOOKS['night']['muted'], a))
        # Plans, not promises.
        centered(d, 1660, 'Planned features. Details may change.', sora(30, 400), LOOKS['night']['muted'])
        return img
    if kind == 'end':
        img = card_bg('night', t)
        a = ease(lt / 0.8)
        age_ring_big(img, a)
        d = ImageDraw.Draw(img)
        centered(d, 1130, 'RELIVABLE', sora(120, 800), mix(LOOKS['night']['bg1'], LOOKS['night']['text'], a))
        b2 = ease((lt - 0.7) / 0.6)
        centered(d, 1290, 'Every choice is remembered.', sora(50, 500), mix(LOOKS['night']['bg1'], LOOKS['night']['accent'], b2))
        b3 = ease((lt - 1.4) / 0.6)
        centered(d, 1460, 'zwitg.github.io/agent-weave-workbench', sora(34, 500), mix(LOOKS['night']['bg1'], LOOKS['night']['muted'], b3))
        if lt > b['secs'] - 0.5:
            img = Image.blend(img, Image.new('RGB', (W, H), (0, 0, 0)), (lt - (b['secs'] - 0.5)) / 0.5)
        return img
    raise ValueError(kind)


def age_ring_big(img, a):
    """The end card: the age ring closing into a full circle."""
    layer = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    cx, cy, r = W // 2, 800, 220
    d.ellipse((cx - r, cy - r, cx + r, cy + r), outline=(52, 59, 92, int(255 * a)), width=16)
    d.arc((cx - r, cy - r, cx + r, cy + r), -90, -90 + 360 * a, fill=LOOKS['night']['accent'] + (255,), width=20)
    f = sora(150, 800)
    tw = d.textlength('R', font=f)
    d.text((cx - tw / 2, cy - 100), 'R', font=f, fill=LOOKS['night']['text'] + (int(255 * a),))
    img.paste(layer, (0, 0), layer)


def render():
    ff = subprocess.Popen(
        ['ffmpeg', '-y', '-loglevel', 'error', '-f', 'rawvideo', '-pix_fmt', 'rgb24',
         '-s', f'{W}x{H}', '-r', str(FPS), '-i', '-',
         '-c:v', 'libx264', '-preset', 'medium', '-crf', '18', '-pix_fmt', 'yuv420p',
         OUT + '.video.mp4'],
        stdin=subprocess.PIPE)
    t0 = 0.0
    prev_screen = None
    last_cap = None
    sfx_events = []
    for b in beats:
        n = int(round(b['secs'] * FPS))
        frames = clip_frames(b['clip']) if b['kind'] == 'clip' else None
        img_still = still(b['img']) if b['kind'] == 'still' else None
        for s in b.get('sfx', []):
            sfx_events.append((t0 + s[0], s[1], s[2]))
        if b['kind'] == 'still' and b['img'].startswith(('life', 'event')):
            sfx_events.append((t0 + 0.05, 'age_up', 0.35))
        for i in range(n):
            lt = i / FPS
            t = t0 + lt
            k = lt / b['secs']
            if b['kind'] in ('still', 'clip'):
                look = b['look']
                to = b.get('to', look)
                # The look changes with the takeover: at the slam for
                # Lockdown, as the gold sets for Molten, at once on release.
                if b['kind'] == 'clip':
                    shift = {'lockdown': (0.28, 0.45), 'release': (0.15, 0.6), 'molten': (0.1, 0.5)}.get(b['clip'], (0, 1))
                    tk = ease((k - shift[0]) / (shift[1] - shift[0]))
                else:
                    tk = 0
                canvas = backdrop_mix(look, to, tk, t)
                cur_look = to if tk > 0.5 else look
                shake = (0, 0)
                if b.get('clip') == 'lockdown':
                    bars(canvas, (k - 0.12) / 0.16)
                    slam = (k - 0.28) / 0.08
                    if 0 <= slam <= 1:
                        amp = 18 * (1 - slam)
                        shake = (int(amp * math.sin(slam * 40)), int(amp * 0.5 * math.cos(slam * 33)))
                if b.get('clip') == 'release':
                    bars(canvas, 1 - ease((k - 0.05) / 0.5))
                if b.get('molten'):
                    molten(canvas, k * 1.6, t)
                if frames:
                    fi = min(len(frames) - 1, int(lt * 30))
                    screen = Image.open(frames[fi]).convert('RGB')
                    zoom, dx, dy = 1.0, 0, 0
                else:
                    screen = img_still
                    z = b.get('zoom', 1.03)
                    zoom = 1.0 + (z - 1.0) * ease(k)
                    dx, dy = 0, b.get('dy', 0) * ease(k)
                    # Cross-fade from the previous screen.
                    if prev_screen is not None and lt < 0.2:
                        screen = Image.blend(prev_screen, screen, lt / 0.2)
                phone(canvas, screen, cur_look, zoom, dx, dy, shake)
                cap = b['cap']
                if 'cap2' in b and k > 0.45:
                    cap = b['cap2']
                    ck = ease((k - 0.45) / 0.08)
                else:
                    ck = 1 if cap == last_cap else ease(lt / 0.3)
                caption(canvas, cur_look, cap, b.get('sub'), ck)
                a0, a1 = b['age']
                age_ring(canvas, a0 + (a1 - a0) * k, cur_look)
                if i == n - 1:
                    prev_screen = screen
            else:
                canvas = render_card(b, lt, t)
                prev_screen = None
            ff.stdin.write(canvas.tobytes())
        last_cap = b.get('cap2') or b.get('cap')
        t0 += b['secs']
        print(f'{t0:5.1f}s / {TOTAL:.1f}s {b["kind"]} {b.get("img") or b.get("clip") or ""}', flush=True)
    ff.stdin.close()
    ff.wait()
    return sfx_events



# ---------------- The score ----------------

RATE = 44100


def note(n):
    return 440.0 * 2 ** ((n - 69) / 12)


def score(sfx_events):
    total = int(TOTAL * RATE) + RATE
    out = np.zeros((total, 2))
    rng = np.random.default_rng(3)
    bpm = 96
    beat_s = 60 / bpm

    # Sections (start, end, chords as MIDI roots, mood).
    marks = []
    t = 0
    for b in beats:
        marks.append((t, b))
        t += b['secs']

    def mood_at(x):
        for (s, b) in reversed(marks):
            if x >= s:
                look = b.get('to') if b['kind'] == 'clip' and x - s > b['secs'] * 0.3 else b.get('look')
                if b['kind'] in ('features',):
                    return 'gold'
                if b['kind'] in ('heir', 'out', 'next', 'end', 'hook'):
                    return 'warm' if b['kind'] != 'heir' else 'soft'
                if b['kind'] == 'intro':
                    return 'soft'
                return look or 'night'
        return 'soft'

    progs = {
        'night': [57, 53, 60, 55],     # A minor, F, C, G: hopeful
        'soft': [57, 53, 60, 55],
        'yard': [50, 46, 48, 45],      # D minor, Bb, C, A: tense
        'gold': [53, 50, 55, 60],      # F, Dm, G, C with 7ths: lush
        'warm': [48, 55, 57, 53],      # C, G, Am, F: uplifting
    }
    shapes = {
        'night': [0, 3, 7, 10], 'soft': [0, 3, 7, 12], 'yard': [0, 3, 7, 13],
        'gold': [0, 4, 7, 11], 'warm': [0, 4, 7, 12],
    }
    bar = beat_s * 4
    nbars = int(TOTAL / bar) + 2
    for bi in range(nbars):
        start = bi * bar
        mood = mood_at(start + 0.01)
        root = progs[mood][bi % 4]
        if mood == 'night' and bi % 4 == 0:
            root = 57
        n = int(bar * RATE)
        tt = np.arange(n) / RATE
        env = np.minimum(1, tt / 0.25) * np.exp(-tt / (bar * 0.9))
        pad = np.zeros(n)
        for iv in shapes[mood]:
            for det in (-0.06, 0.06):
                f = note(root + iv) * (1 + det / 100)
                pad += np.sin(2 * np.pi * f * tt) * 0.5 + 0.18 * np.sin(4 * np.pi * f * tt)
        pad *= env * (0.05 if mood != 'soft' else 0.035)
        bass = np.sin(2 * np.pi * note(root - 12) * tt) * np.exp(-tt / 0.9) * 0.16
        s = int(start * RATE)
        if s >= total:
            break
        e = min(total, s + n)
        out[s:e, 0] += (pad + bass)[: e - s]
        out[s:e, 1] += (pad * 0.9 + bass)[: e - s]
        # Rhythm: none in the soft parts; a ticking clock in prison; a
        # full beat with sparkles at the top; a driving beat at the end.
        for q in range(4):
            bt = start + q * beat_s
            bs = int(bt * RATE)
            if mood in ('night', 'gold', 'warm'):
                kn = int(0.18 * RATE)
                kt = np.arange(kn) / RATE
                kick = np.sin(2 * np.pi * (55 + 90 * np.exp(-kt * 30)) * kt) * np.exp(-kt * 14) * (0.38 if mood != 'night' else 0.26)
                out[bs:bs + kn, :] += kick[: max(0, min(kn, total - bs))][:, None]
            if mood in ('night', 'gold', 'warm', 'yard'):
                hs = int((bt + beat_s / 2) * RATE)
                hn = int(0.05 * RATE)
                hat = rng.uniform(-1, 1, hn) * np.exp(-np.arange(hn) / RATE * 70) * (0.05 if mood != 'yard' else 0.09)
                hat = np.diff(np.concatenate([[0], hat]))
                out[hs:hs + hn, :] += hat[: max(0, min(hn, total - hs))][:, None]
            if mood == 'gold' and q % 2 == 0:
                bn = int(0.8 * RATE)
                btt = np.arange(bn) / RATE
                f = note(root + 24 + [0, 7, 11, 14][(bi + q) % 4])
                bell = (np.sin(2 * np.pi * f * btt) + 0.4 * np.sin(2 * np.pi * f * 2.76 * btt)) * np.exp(-btt * 4) * 0.05
                out[bs:bs + bn, :] += bell[: max(0, min(bn, total - bs))][:, None]
    # The game's own sounds on their moments.
    for (at, name, gain) in sfx_events:
        path = os.path.join(SOUNDS, name + '.wav')
        if not os.path.exists(path):
            continue
        with wave.open(path) as w:
            sr = w.getframerate()
            data = np.frombuffer(w.readframes(w.getnframes()), dtype='<i2').astype(float) / 32768
        idx = np.arange(0, len(data), sr / RATE)
        data = np.interp(idx, np.arange(len(data)), data)
        s = int(at * RATE)
        e = min(total, s + len(data))
        out[s:e, :] += (data[: e - s] * gain * 0.6)[:, None]
    # Gentle master: fade in and out, then limit.
    fade = int(1.5 * RATE)
    out[:fade] *= np.linspace(0, 1, fade)[:, None]
    end = int(TOTAL * RATE)
    out[end - fade:end] *= np.linspace(1, 0, fade)[:, None]
    out[end:] = 0
    out = np.tanh(out * 1.4) * 0.85
    pcm = (out * 32767).astype('<i2')
    with wave.open(OUT + '.audio.wav', 'wb') as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(pcm.tobytes())


def sfx_list():
    """The sound-effect moments, without rendering (for REUSE=1)."""
    t0, ev = 0.0, []
    for b in beats:
        for s in b.get('sfx', []):
            ev.append((t0 + s[0], s[1], s[2]))
        if b['kind'] == 'still' and b['img'].startswith(('life', 'event')):
            ev.append((t0 + 0.05, 'age_up', 0.35))
        t0 += b['secs']
    return ev


if __name__ == '__main__':
    os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
    if os.environ.get('REUSE') == '1' and os.path.exists(OUT + '.video.mp4'):
        events = sfx_list()
    else:
        events = render()
    score(events)
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', OUT + '.video.mp4', '-i', OUT + '.audio.wav',
                    '-c:v', 'copy', '-c:a', 'aac', '-b:a', '192k', '-shortest', '-movflags', '+faststart', OUT],
                   check=True)
    os.remove(OUT + '.video.mp4')
    os.remove(OUT + '.audio.wav')
    print('Wrote', OUT, f'({TOTAL:.1f} s)')
