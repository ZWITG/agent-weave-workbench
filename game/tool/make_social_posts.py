"""Builds a batch of Instagram posts, stories and Reels from real gameplay.

Every piece leads with one big line that stops the scroll, puts the real
game in a tilted phone that breaks out of the frame, and wears the game's
own look for its subject: Night Feed, Yard Time (stencil type, cell bars)
or Gilded (serif type, molten gold). Update posts carry a "NEW UPDATE"
badge.

Run from the game folder after rendering the promo footage:
  flutter test tool/render_promo_test.dart --dart-define=OUT=<footage>
  python3 tool/make_social_posts.py <footage> media/relivable-promo.mp4 media/social
"""

import math
import os
import subprocess
import sys
import wave

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

FOOT, PROMO, OUT = sys.argv[1], sys.argv[2], sys.argv[3]
HERE = os.path.dirname(os.path.abspath(__file__))
FONTS = os.path.join(HERE, '..', 'assets', 'fonts')
SOUNDS = os.path.join(HERE, '..', 'assets', 'sounds')
os.makedirs(OUT, exist_ok=True)


def font(name, size, weight=None):
    f = ImageFont.truetype(os.path.join(FONTS, name), size)
    if weight is not None:
        f.set_variation_by_axes([weight])
    return f


def sora(s, w=800):
    return font('Sora-Variable.ttf', s, w)


def serif(s, w=800):
    return font('PlayfairDisplay-Variable.ttf', s, w)


def stencil(s):
    return font('StardosStencil-Bold.ttf', s)


def chalk(s):
    return font('Caveat-Bold.ttf', s)


LOOKS = {
    'night': dict(bg1=(15, 18, 32), bg2=(36, 43, 72), glow=(124, 156, 255), glow2=(181, 124, 255),
                  accent=(255, 184, 107), text=(238, 241, 250), muted=(169, 176, 199), head=sora),
    'yard': dict(bg1=(10, 17, 14), bg2=(30, 48, 41), glow=(77, 122, 105), glow2=(159, 224, 193),
                 accent=(159, 224, 193), text=(229, 239, 234), muted=(147, 168, 159), head=lambda s, w=0: stencil(s)),
    'gold': dict(bg1=(5, 4, 3), bg2=(28, 22, 12), glow=(212, 175, 90), glow2=(246, 227, 161),
                 accent=(226, 184, 78), text=(243, 235, 216), muted=(163, 149, 119), head=serif),
}


def backdrop(look, W, H, seed=0):
    L = LOOKS[look]
    g = np.linspace(0, 1, H)[:, None, None]
    arr = np.array(L['bg1'])[None, None] * (1 - g) + np.array(L['bg2'])[None, None] * g
    img = Image.fromarray(np.repeat(arr, W, axis=1).astype(np.uint8))
    glow = Image.new('L', (W, H), 0)
    d = ImageDraw.Draw(glow)
    rng = np.random.default_rng(seed)
    for (cx, cy, r, a) in [(W * 0.15 + rng.uniform(-60, 60), H * 0.25, W * 0.55, 120),
                           (W * 0.9, H * 0.75 + rng.uniform(-80, 80), W * 0.5, 80)]:
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=int(a))
    glow = glow.filter(ImageFilter.GaussianBlur(W * 0.16))
    img = Image.composite(Image.new('RGB', (W, H), L['glow']), img, glow.point(lambda v: v * 0.5))
    # Film grain so flat colour does not band.
    noise = Image.fromarray(rng.integers(0, 18, (H, W), dtype=np.uint8), 'L')
    return Image.composite(Image.new('RGB', (W, H), (255, 255, 255)), img, noise.point(lambda v: v // 3))


def bars(img, look='yard', alpha=255):
    W, H = img.size
    layer = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    n = 7
    for i in range(n + 1):
        x = int(i * W / n)
        d.rectangle((x - 11, 0, x + 11, H), fill=(34, 48, 42, alpha))
        d.rectangle((x - 6, 0, x - 2, H), fill=(140, 168, 156, int(alpha * 0.8)))
    img.paste(layer, (0, 0), layer)


def drips(img, n=22, seed=3, reach=1.0):
    W, H = img.size
    d = ImageDraw.Draw(img)
    rng = np.random.default_rng(seed)
    for _ in range(n):
        x = int(rng.uniform(0, W))
        w = int(rng.uniform(4, 13))
        y = int(H * reach * rng.uniform(0.15, 0.95))
        d.rectangle((x - w // 2, 0, x + w // 2, y), fill=(206, 160, 62))
        d.rectangle((x - w // 4, 0, x, y), fill=(255, 236, 170))
        d.ellipse((x - w, y - w * 2, x + w, y), fill=(255, 236, 170))


def scrim(img, y1, strength=0.82):
    """Darkens the top of the image (down to y1, fading out) so headlines
    stay readable over bars and molten gold."""
    W, H = img.size
    a = np.zeros((H, 1), dtype=float)
    a[:y1, 0] = strength
    fade = 160
    a[y1:y1 + fade, 0] = np.linspace(strength, 0, min(fade, max(0, H - y1)))
    mask = Image.fromarray((np.repeat(a, W, axis=1) * 255).astype(np.uint8), 'L')
    img.paste(Image.new('RGB', (W, H), (0, 0, 0)), (0, 0), mask)


def bottom_band(img, look):
    """A dark band at the bottom for the brand line, over the phone."""
    W, H = img.size
    a = np.zeros((H, 1), dtype=float)
    a[H - 200:H - 130, 0] = np.linspace(0, 0.92, 70)
    a[H - 130:, 0] = 0.92
    mask = Image.fromarray((np.repeat(a, W, axis=1) * 255).astype(np.uint8), 'L')
    img.paste(Image.new('RGB', (W, H), LOOKS[look]['bg1']), (0, 0), mask)


def phone_layer(screen, width, look, tilt=-6):
    """The game in a phone, tilted, with a glow."""
    L = LOOKS[look]
    sw, sh = screen.size
    h = int(width * sh / sw)
    pad = 18
    ph = Image.new('RGBA', (width + 2 * pad, h + 2 * pad), (0, 0, 0, 0))
    d = ImageDraw.Draw(ph)
    d.rounded_rectangle((0, 0, width + 2 * pad - 1, h + 2 * pad - 1), 78, fill=(5, 6, 9, 255),
                        outline=tuple(int(c * 0.6) for c in L['accent']) + (255,), width=4)
    s = screen.resize((width, h), Image.LANCZOS)
    m = Image.new('L', (width, h), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, width - 1, h - 1), 62, fill=255)
    ph.paste(s, (pad, pad), m)
    ph = ph.rotate(tilt, resample=Image.BICUBIC, expand=True)
    glow = Image.new('RGBA', ph.size, L['glow'] + (0,))
    glow.putalpha(ph.split()[3].filter(ImageFilter.GaussianBlur(40)).point(lambda v: int(v * 0.6)))
    out = Image.new('RGBA', (ph.width + 160, ph.height + 160), (0, 0, 0, 0))
    out.paste(glow, (80, 80), glow)
    out.paste(ph, (80, 80), ph)
    return out


def wrap(d, text, f, maxw):
    lines = []
    for para in text.split('\n'):
        cur = ''
        for w in para.split(' '):
            t = (cur + ' ' + w).strip()
            if d.textlength(t, font=f) <= maxw:
                cur = t
            else:
                lines.append(cur)
                cur = w
        lines.append(cur)
    return lines


def headline(img, look, text, y, size, maxw=None, color=None, align='left', x=70, lead=1.02):
    d = ImageDraw.Draw(img)
    W = img.size[0]
    L = LOOKS[look]
    f = L['head'](size)
    maxw = maxw or W - 2 * x
    lines = wrap(d, text, f, maxw)
    for i, line in enumerate(lines):
        col = color or L['text']
        if line.endswith('*'):
            line, col = line[:-1], L['accent']
        lx = x if align == 'left' else (W - d.textlength(line, font=f)) / 2
        d.text((lx, y), line, font=f, fill=col)
        y += int(size * lead)
    return y


def badge(img, text, look, x=70, y=70):
    L = LOOKS[look]
    d = ImageDraw.Draw(img)
    f = sora(26, 800)
    w = d.textlength(text, font=f)
    d.rounded_rectangle((x, y, x + w + 44, y + 54), 27, fill=L['accent'])
    d.text((x + 22, y + 10), text, font=f, fill=L['bg1'])
    return y + 54


def brand(img, look, y=None, center=False):
    """The Relivable mark: an age ring around an R, and the name."""
    W, H = img.size
    L = LOOKS[look]
    d = ImageDraw.Draw(img)
    y = y if y is not None else H - 110
    x = 70 if not center else W // 2 - 150
    r = 30
    d.ellipse((x, y, x + 2 * r, y + 2 * r), outline=L['muted'], width=5)
    d.arc((x, y, x + 2 * r, y + 2 * r), -90, 200, fill=L['accent'], width=6)
    f = sora(30, 800)
    d.text((x + r - d.textlength('R', font=f) / 2, y + 11), 'R', font=f, fill=L['text'])
    d.text((x + 2 * r + 18, y + 10), 'RELIVABLE', font=sora(34, 800), fill=L['text'])


def footer(img, look, text):
    W, H = img.size
    L = LOOKS[look]
    d = ImageDraw.Draw(img)
    f = sora(28, 500)
    tw = d.textlength(text, font=f)
    d.text((W - 70 - tw, H - 92), text, font=f, fill=L['muted'])


def screen(name):
    return Image.open(os.path.join(FOOT, 'stills', name + '.png')).convert('RGB')


def frame(clip, i):
    fs = sorted(os.listdir(os.path.join(FOOT, clip)))
    return Image.open(os.path.join(FOOT, clip, fs[min(i, len(fs) - 1)])).convert('RGB')


def save(img, name):
    p = os.path.join(OUT, name)
    img.convert('RGB').save(p, quality=95)
    print('wrote', p)


# ---------------- Feed posts (1080 x 1350) ----------------

FW, FH = 1080, 1350


def post(name, look, scr, head, sub, *, badge_text=None, tilt=-7, phone_w=560, px=None, py=470,
         deco=None, size=112, foot='Free · Android, iPhone, Windows & web'):
    img = backdrop(look, FW, FH, seed=sum(map(ord, name)))
    if deco == 'bars':
        bars(img, alpha=150)
    if deco == 'drips':
        drips(img)
    if deco:
        scrim(img, 430)
    y = 70
    if badge_text:
        y = badge(img, badge_text, look) + 34
    y = headline(img, look, head, y, size, maxw=FW - 140)
    if sub:
        d = ImageDraw.Draw(img)
        for line in wrap(d, sub, sora(36, 500), 560):
            d.text((70, y + 16), line, font=sora(36, 500), fill=LOOKS[look]['muted'])
            y += 46
    ph = phone_layer(scr, phone_w, look, tilt)
    x = px if px is not None else FW - ph.width + 70
    img.paste(ph, (x, max(py, y - 60)), ph)
    bottom_band(img, look)
    brand(img, look)
    if foot:
        footer(img, look, foot)
    save(img, name)


def feed():
    post('01_booked.jpg', 'yard', frame('lockdown', 112), 'YOU GOT BOOKED.',
         'Go to prison and the whole game goes inside with you.', badge_text='NEW UPDATE · LOCKDOWN',
         deco='bars', size=104)
    post('02_gold.jpg', 'gold', frame('molten', 150), 'Hit $100M.\nThe game turns\nto gold.*',
         None, badge_text='NEW UPDATE · MOLTEN', deco='drips', size=96)
    post('03_invited.jpg', 'gold', frame('molten', 245), 'You are cordially invited.',
         'The upper echelon opens at $100,000,000. Most players never see this screen.', size=96)
    post('04_the_list.jpg', 'gold', screen('echelon_1'), '8 tycoons.\n1 List.*',
         'Climb past them, feud with them, or buy them out.', badge_text='NEW UPDATE · THE ECHELON', size=120)
    post('05_yard_name.jpg', 'yard', screen('prison_id'), 'WHAT WOULD THE YARD CALL YOU?',
         'Lift and you are Bench. Study and you are Professor. Snitch and you are Canary. Comment yours.',
         badge_text='NEW UPDATE · THE YARD', size=86, py=560)
    post('06_what_would_you_do.jpg', 'night', screen('event_0'), 'What would\nyou do?*',
         'Every year asks you something, and the game remembers what you answered. Comment A, B or C.',
         size=118)
    post('07_87_years.jpg', 'night', screen('life_24'), 'Live 87 years\nin one evening.*',
         'School, love, work, money, family. One year at a time.', size=100)
    post('08_things_to_do.jpg', 'night', screen('activities_0'), '500+ things\nto do.*',
         'Swipe up for activities: from a quiet walk to a heist.', size=120)
    post('09_minigames.jpg', 'night', screen('mini_1'), 'Every activity\nis a mini-game.*',
         'Lift, sneak, deal blackjack, keep the rhythm.', size=100)
    patch_notes()
    launch()


def patch_notes():
    img = backdrop('night', FW, FH, seed=11)
    d = ImageDraw.Draw(img)
    badge(img, "WHAT'S NEW", 'night')
    y_end = headline(img, 'night', 'Our biggest\nupdates yet.*', 160, 84)
    items = [
        ('LOCKDOWN', 'Prison takes over the whole game: bars, stencils, a new look.', 'yard'),
        ('THE YARD', 'A map of the prison, cell items, contraband and a yard name.', 'yard'),
        ('THE ECHELON', 'Rival tycoons, influence, moonshots and heirs at the top.', 'gold'),
        ('MOLTEN', 'Reach $100M and molten gold takes over the game.', 'gold'),
        ('1.0', 'Out now on Android, iPhone, Windows and the web.', 'night'),
    ]
    y = y_end + 30
    for t, s, look in items:
        L = LOOKS[look]
        d.rounded_rectangle((70, y, FW - 70, y + 150), 26, fill=tuple(int(c * 0.6) for c in L['bg2']),
                            outline=L['accent'], width=3)
        f = stencil(44) if look == 'yard' else serif(48) if look == 'gold' else sora(44, 800)
        d.text((104, y + 22), t, font=f, fill=L['accent'])
        d.text((104, y + 86), s, font=sora(28, 500), fill=L['text'])
        y += 172
    brand(img, 'night')
    save(img, '10_whats_new.jpg')


def launch():
    img = backdrop('night', FW, FH, seed=12)
    d = ImageDraw.Draw(img)
    badge(img, 'OUT NOW', 'night', x=FW // 2 - 90)
    headline(img, 'night', 'Every choice is\nremembered.*', 170, 100, align='center')
    ph = phone_layer(screen('life_17'), 330, 'night', -9)
    img.paste(ph, (-60, 440), ph)
    ph3 = phone_layer(screen('echelon_0'), 330, 'gold', 9)
    img.paste(ph3, (FW - ph3.width + 60, 440), ph3)
    ph2 = phone_layer(screen('prison_yard'), 350, 'yard', 0)
    img.paste(ph2, (FW // 2 - ph2.width // 2, 400), ph2)
    bottom_band(img, 'night')
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((180, FH - 250, FW - 180, FH - 160), 45, fill=LOOKS['night']['accent'])
    t = 'Play free · link in bio'
    f = sora(40, 800)
    d.text(((FW - d.textlength(t, font=f)) / 2, FH - 232), t, font=f, fill=LOOKS['night']['bg1'])
    brand(img, 'night', y=FH - 120)
    save(img, '11_out_now.jpg')


# ---------------- Carousel: a whole life in five slides ----------------

def carousel():
    slides = [
        ('night', None, 'Swipe to live\na whole life ›*', None, 'Age 0'),
        ('night', screen('life_08'), 'Age 8.', 'Best friends, a first pet, and a grandmother with a photo album.', 'Age 8'),
        ('yard', frame('lockdown', 112), 'AGE 31. BOOKED.', 'One bad choice, four years inside. The game changes with you.', 'Age 31'),
        ('gold', screen('echelon_0'), 'Age 46.\nBillionaire.*', 'Rivals, influence, a moonshot, and heirs to prepare.', 'Age 46'),
        ('night', None, 'Age 87.\nYour daughter takes over.*', 'Then you play her life. Every choice is remembered.', 'Age 87'),
    ]
    for i, (look, scr, head, sub, age) in enumerate(slides, 1):
        img = backdrop(look, FW, FH, seed=40 + i)
        if look == 'yard':
            bars(img, alpha=120)
        if look == 'gold':
            drips(img, n=14)
        if look != 'night':
            scrim(img, 420)
        d = ImageDraw.Draw(img)
        # A big age ring that fills slide by slide.
        a = int(age.split()[1])
        cx, cy, r = FW - 150, 150, 80
        d.ellipse((cx - r, cy - r, cx + r, cy + r), outline=LOOKS[look]['muted'], width=9)
        if a:
            d.arc((cx - r, cy - r, cx + r, cy + r), -90, -90 + 360 * a / 100, fill=LOOKS[look]['accent'], width=11)
        f = sora(64, 800)
        d.text((cx - d.textlength(str(a), font=f) / 2, cy - 38), str(a), font=f, fill=LOOKS[look]['text'])
        size = 120 if scr is None else 92
        y = headline(img, look, head, 300 if scr is None else 90, size, maxw=FW - 340 if scr else FW - 140)
        if sub:
            for line in wrap(d, sub, sora(36, 500), 600 if scr else 900):
                d.text((70, y + 16), line, font=sora(36, 500), fill=LOOKS[look]['muted'])
                y += 46
        if scr is not None:
            ph = phone_layer(scr, 540, look, -6 if i % 2 else 6)
            img.paste(ph, (FW - ph.width + 70 if i % 2 else -60, max(440, y - 40)), ph)
            bottom_band(img, look)
        if i == len(slides):
            d.rounded_rectangle((70, FH - 300, 640, FH - 210), 45, fill=LOOKS[look]['accent'])
            d.text((110, FH - 282), 'Play free · link in bio', font=sora(38, 800), fill=LOOKS[look]['bg1'])
        brand(img, look)
        if i < len(slides):
            footer(img, look, f'{i}/{len(slides)}  swipe ›')
        save(img, f'carousel_{i}.jpg')


# ---------------- Stories (1080 x 1920) ----------------

SW, SH = 1080, 1920


def stories():
    # A split "this or that" for the poll sticker.
    img = Image.new('RGB', (SW, SH))
    top = backdrop('yard', SW, SH // 2, seed=7)
    bars(top, alpha=140)
    bot = backdrop('gold', SW, SH // 2, seed=8)
    drips(bot, n=16)
    img.paste(top, (0, 0))
    img.paste(bot, (0, SH // 2))
    d = ImageDraw.Draw(img)
    ph = phone_layer(screen('prison_yard'), 330, 'yard', -8)
    img.paste(ph, (SW - ph.width + 40, 80), ph)
    ph = phone_layer(screen('echelon_0'), 330, 'gold', 8)
    img.paste(ph, (-40, SH // 2 + 300), ph)
    d = ImageDraw.Draw(img)
    d.text((70, 380), 'PRISON', font=stencil(150), fill=LOOKS['yard']['text'])
    d.text((70, 560), 'yard name, contraband,\nthe great escape', font=chalk(60), fill=LOOKS['yard']['accent'])
    d.text((SW - 70 - d.textlength('Billionaire', font=serif(130)), SH // 2 + 140), 'Billionaire',
           font=serif(130), fill=LOOKS['gold']['accent'])
    d.text((SW - 70 - d.textlength('rivals, moonshots, heirs', font=sora(42, 500)), SH // 2 + 320),
           'rivals, moonshots, heirs', font=sora(42, 500), fill=LOOKS['gold']['text'])
    d.ellipse((SW // 2 - 110, SH // 2 - 110, SW // 2 + 110, SH // 2 + 110), fill=(15, 18, 32), outline=(255, 184, 107), width=8)
    f = sora(96, 800)
    d.text((SW // 2 - d.textlength('OR', font=f) / 2, SH // 2 - 60), 'OR', font=f, fill=(238, 241, 250))
    d.text((70, SH - 130), 'Add a poll sticker in the middle   ·   RELIVABLE', font=sora(30, 500), fill=(243, 235, 216))
    save(img, 'story_1_prison_or_billionaire.jpg')

    # The update story.
    img = backdrop('gold', SW, SH, seed=9)
    drips(img, n=30, reach=0.5)
    scrim(img, 720, 0.7)
    badge(img, 'NEW UPDATE', 'gold', y=260)
    headline(img, 'gold', 'Molten.', 350, 190)
    d = ImageDraw.Draw(img)
    d.text((70, 580), 'Reach $100,000,000 and the\nwhole game turns to gold.', font=sora(48, 600), fill=LOOKS['gold']['text'])
    ph = phone_layer(frame('molten', 300), 560, 'gold', -5)
    img.paste(ph, (SW // 2 - ph.width // 2, 760), ph)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((200, SH - 250, SW - 200, SH - 150), 50, fill=LOOKS['gold']['accent'])
    t = 'Play free · link in bio'
    d.text(((SW - d.textlength(t, font=sora(42, 800))) / 2, SH - 228), t, font=sora(42, 800), fill=(5, 4, 3))
    save(img, 'story_2_molten.jpg')


# ---------------- Reels (1080 x 1920, with sound) ----------------

def tone_sfx(events, secs, path, bpm=100, mood='gold'):
    rate = 44100
    n = int(secs * rate)
    out = np.zeros(n)
    beat = 60 / bpm
    t = np.arange(n) / rate
    root = 50 if mood == 'yard' else 53
    for k, iv in enumerate([0, 7, 12, 16] if mood == 'gold' else [0, 3, 7, 12]):
        out += 0.04 * np.sin(2 * np.pi * 440 * 2 ** ((root + iv - 69) / 12) * t)
    out *= np.minimum(1, t / 0.8)
    for b in np.arange(0, secs, beat):
        s = int(b * rate)
        kn = int(0.16 * rate)
        kt = np.arange(kn) / rate
        kick = np.sin(2 * np.pi * (50 + 80 * np.exp(-kt * 30)) * kt) * np.exp(-kt * 14) * 0.3
        out[s:s + kn] += kick[: max(0, min(kn, n - s))]
    for (at, name, gain) in events:
        with wave.open(os.path.join(SOUNDS, name + '.wav')) as w:
            sr = w.getframerate()
            data = np.frombuffer(w.readframes(w.getnframes()), dtype='<i2').astype(float) / 32768
        data = np.interp(np.arange(0, len(data), sr / rate), np.arange(len(data)), data)
        s = int(at * rate)
        e = min(n, s + len(data))
        out[s:e] += data[: e - s] * gain * 0.6
    fade = int(0.6 * rate)
    out[-fade:] *= np.linspace(1, 0, fade)
    pcm = (np.tanh(out * 1.3) * 0.85 * 32767).astype('<i2')
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(pcm.tobytes())


def reel(name, look, clip, head1, head2, secs, sfx, deco):
    fs = sorted(os.listdir(os.path.join(FOOT, clip)))
    tmp = os.path.join(OUT, name + '.video.mp4')
    ff = subprocess.Popen(['ffmpeg', '-y', '-loglevel', 'error', '-f', 'rawvideo', '-pix_fmt', 'rgb24',
                           '-s', f'{SW}x{SH}', '-r', '30', '-i', '-', '-c:v', 'libx264', '-crf', '19',
                           '-pix_fmt', 'yuv420p', tmp], stdin=subprocess.PIPE)
    base = backdrop(look, SW, SH, seed=21)
    n = int(secs * 30)
    for i in range(n):
        img = base.copy()
        k = i / n
        if deco == 'bars' and k > 0.25:
            bars(img, alpha=int(150 * min(1, (k - 0.25) / 0.05)))
        if deco == 'drips':
            drips(img, n=26, reach=min(1, k * 1.5))
        fi = min(len(fs) - 1, i)
        scr = Image.open(os.path.join(FOOT, clip, fs[fi])).convert('RGB')
        ph = phone_layer(scr, 640, look, -4)
        img.paste(ph, (SW // 2 - ph.width // 2, 520), ph)
        head = head1 if k < 0.5 else head2
        headline(img, look, head, 150, 104, align='center')
        brand(img, look, y=SH - 150, center=True)
        ff.stdin.write(img.tobytes())
    ff.stdin.close()
    ff.wait()
    wav = os.path.join(OUT, name + '.wav')
    tone_sfx(sfx, secs, wav, mood='yard' if look == 'yard' else 'gold')
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', tmp, '-i', wav, '-c:v', 'copy', '-c:a', 'aac',
                    '-b:a', '160k', '-shortest', '-movflags', '+faststart', os.path.join(OUT, name)], check=True)
    os.remove(tmp)
    os.remove(wav)
    print('wrote', os.path.join(OUT, name))


def reels():
    reel('reel_1_lockdown.mp4', 'yard', 'lockdown', 'POV: YOU MADE\nONE BAD CHOICE', 'AND THE WHOLE\nGAME WENT INSIDE',
         7.5, [(0.0, 'siren', 0.5), (1.38, 'clang', 1.0)], 'bars')
    reel('reel_2_molten.mp4', 'gold', 'molten', 'POV: you just\nhit $100 million', 'and the game\nturned to gold.*',
         10.6, [(0.0, 'whoosh', 0.7), (4.05, 'coin', 0.8), (6.9, 'celebrate', 0.9)], 'drips')
    # A 20-second cut-down of the full promo: the hook, prison, gold, the end.
    cuts = [(3.4, 6.4), (23.2, 28.1), (43.0, 52.3), (75.8, 80.0)]
    parts = []
    for i, (a, b) in enumerate(cuts):
        p = os.path.join(OUT, f'_cut{i}.mp4')
        subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-ss', str(a), '-to', str(b), '-i', PROMO,
                        '-c:v', 'libx264', '-crf', '19', '-c:a', 'aac', '-ar', '44100', p], check=True)
        parts.append(p)
    lst = os.path.join(OUT, '_cuts.txt')
    with open(lst, 'w') as f:
        f.writelines(f"file '{os.path.abspath(p)}'\n" for p in parts)
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-f', 'concat', '-safe', '0', '-i', lst,
                    '-c', 'copy', '-movflags', '+faststart', os.path.join(OUT, 'reel_3_trailer_20s.mp4')], check=True)
    for p in parts + [lst]:
        os.remove(p)
    print('wrote', os.path.join(OUT, 'reel_3_trailer_20s.mp4'))


if __name__ == '__main__':
    feed()
    carousel()
    stories()
    reels()
