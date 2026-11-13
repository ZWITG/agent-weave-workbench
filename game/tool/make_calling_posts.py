"""Instagram batch 2: the "Calling" update (special careers).

Feed posts, a carousel, stories and a Reel, all from real gameplay
rendered by tool/render_calling_promo_test.dart. Each piece wears the look
of the career it shows: Marquee, Orbit, Fight Night, Chamber, Mahogany,
Market Day and the rest, with that look's colours and type. Layout helpers
come from tool/make_social_posts.py (batch 1).

Run from the game folder:
  flutter test tool/render_calling_promo_test.dart --dart-define=OUT=<footage>
  python3 tool/make_calling_posts.py <footage> media/social/calling [feed carousel stories reel]
"""

import math
import os
import subprocess
import sys
import wave

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

FOOT, OUT = sys.argv[1], sys.argv[2]
PARTS = sys.argv[3:] or ['feed', 'carousel', 'stories', 'reel']
# Batch 1's helpers read their paths from argv when imported.
sys.argv = [sys.argv[0], FOOT, '', OUT]
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_social_posts as b  # noqa: E402

from make_social_posts import (  # noqa: E402
    FH, FW, LOOKS, SH, SW, backdrop, badge, bottom_band, brand, chalk, footer, headline,
    phone_layer, save, scrim, serif, sora, stencil, tone_sfx, wrap,
)


def hexrgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def look(bg1, bg2, glow, glow2, accent, text, muted, head):
    return dict(bg1=hexrgb(bg1), bg2=hexrgb(bg2), glow=hexrgb(glow), glow2=hexrgb(glow2),
                accent=hexrgb(accent), text=hexrgb(text), muted=hexrgb(muted), head=head)


def sten(s, w=0):
    return stencil(s)


def chk(s, w=0):
    return chalk(int(s * 1.15))


# The game's career looks (lib/theme.dart, careerLooks), for the posts.
LOOKS.update({
    'actor': look('170A0E', '3A1420', 'B0233B', 'FFD27A', 'FFD27A', 'FFF1E6', 'C7A3A8', serif),
    'musician': look('0E0A1C', '2A1A4A', '8A5CFF', '4FF0D0', 'FF5FDC', 'F3EEFF', 'A99CC9', sora),
    'athlete': look('0A0E14', '1C2533', '9BE33C', 'C6FF4D', 'C6FF4D', 'F2F6F0', '9EA9B4', sten),
    'model': look('0C0C0D', '232326', 'E8B4C8', 'F4B8CF', 'F4B8CF', 'FAFAFA', 'A6A6AB',
                  lambda s, w=0: serif(s)),
    'politician': look('0B1020', '1C2742', 'C8A86A', 'FF7680', 'E0C27A', 'F5EFE0', 'ADA791', serif),
    'military': look('12140D', '262B1C', '8C9A5B', 'D4C48F', 'FF9A3C', 'EEEEDF', 'A6A88E', sten),
    'lawyer': look('160E0A', '2F1F17', 'B98A4E', '7FD4A6', 'E0B66E', 'F6EDE0', 'B9A38F', serif),
    'doctor': look('08161A', '163038', '4FD6C8', '9AF2E6', '4FD6C8', 'EAF7F6', '9DB9BC', sora),
    'pilot': look('0A0F18', '1C2A40', '6FA8FF', 'FFB547', 'FFB547', 'ECE8E1', '9A9A98', sora),
    'vet': look('141A10', '2A3A22', '8FBF5A', 'FFC857', 'FFC857', 'F1F2E6', 'A9B39A', chk),
    'hustler': look('1A140D', '2C2218', 'FF6B4A', '5EC8FF', 'FFD45E', 'F6EFE4', 'B8A893', chk),
    'police': look('0A0F1C', '1A2540', '5C9BFF', 'FF6B70', 'FF6B70', 'EEF2FA', '9DAAC6', sten),
    'astronaut': look('05070F', '161C30', '7FD3FF', 'FF8A3D', 'FF8A3D', 'F2F5FF', '9AA3C0', sora),
    'fighter': look('120808', '2A1515', 'FF5252', 'FFD34D', 'FFD34D', 'FFF2EC', 'C4A39C', sten),
})

NAMES = {
    'actor': 'MARQUEE', 'musician': 'BACKSTAGE', 'athlete': 'FLOODLIGHTS', 'model': 'RUNWAY',
    'politician': 'CHAMBER', 'military': 'FIELD KIT', 'lawyer': 'MAHOGANY', 'doctor': 'NIGHT SHIFT',
    'pilot': 'FLIGHT DECK', 'vet': 'MEADOW', 'hustler': 'MARKET DAY', 'police': 'BLUE LINE',
    'astronaut': 'ORBIT', 'fighter': 'FIGHT NIGHT',
}

FOOT_LINE = 'Free · Android, iPhone, Windows & web'


def still(name):
    return Image.open(os.path.join(FOOT, 'stills', name + '.png')).convert('RGB')


def sub_text(img, lk, text, y, maxw=600, size=36):
    d = ImageDraw.Draw(img)
    y += 14
    for line in wrap(d, text, sora(size, 500), maxw):
        d.text((70, y + 16), line, font=sora(size, 500), fill=LOOKS[lk]['muted'])
        y += int(size * 1.28)
    return y


def post(name, lk, scr, head, sub, *, tag=None, size=104, tilt=-7, phone_w=560, py=470, sub_w=560):
    img = backdrop(lk, FW, FH, seed=sum(map(ord, name)))
    y = 70
    if tag:
        y = badge(img, tag, lk) + 34
    y = headline(img, lk, head, y, size, maxw=FW - 140)
    if sub:
        y = sub_text(img, lk, sub, y, sub_w)
    ph = phone_layer(scr, phone_w, lk, tilt)
    img.paste(ph, (FW - ph.width + 70, max(py, y - 60)), ph)
    bottom_band(img, lk)
    brand(img, lk)
    footer(img, lk, FOOT_LINE)
    save(img, name)


# ---------------- Feed posts (1080 x 1350) ----------------

def feed():
    # 01: the hook: three careers, three whole different games.
    img = backdrop('night', FW, FH, seed=101)
    badge(img, 'NEW UPDATE · CALLING', 'night', x=FW // 2 - 230)
    y = headline(img, 'night', 'Pick your\ncalling.*', 150, 128, align='center')
    d = ImageDraw.Draw(img)
    t = '14 careers. 14 whole new looks.'
    d.text(((FW - d.textlength(t, font=sora(40, 600))) / 2, y + 10), t, font=sora(40, 600),
           fill=LOOKS['night']['muted'])
    for (scr, lk, x, t, w, y) in [
        ('hub_actor', 'actor', -70, -9, 330, 600),
        ('hub_fighter', 'fighter', FW - 400, 9, 330, 600),
        ('hub_astronaut', 'astronaut', None, 0, 360, 550),
    ]:
        ph = phone_layer(still(scr), w, lk, t)
        img.paste(ph, (FW // 2 - ph.width // 2 if x is None else x, y), ph)
    bottom_band(img, 'night')
    brand(img, 'night')
    footer(img, 'night', FOOT_LINE)
    save(img, '01_pick_your_calling.jpg')

    post('02_mars.jpg', 'astronaut', still('hub_astronaut'), 'Go to Mars.\nMaybe come\nback.*',
         'Every launch shows its risk first. Train harder, fly safer, or scrub.',
         tag='NEW CAREER · ASTRONAUT', size=110)
    post('03_read_the_tell.jpg', 'fighter', still('game_fight'), 'READ THE TELL.\nTHROW THE\nPUNCH.*',
         'Boxing or MMA. Guard the jab, slip the hook, strike the opening.',
         tag='NEW CAREER · FIGHTER', size=96)
    post('04_repaints.jpg', 'actor', still('hub_actor'), 'Every career\nrepaints the\nwhole game.*',
         'Start a special career and the whole game takes on its look.', size=100)
    post('05_judge.jpg', 'lawyer', still('hub_lawyer'), 'Your cousin is\nin the dock.\nYou\'re the\njudge.*',
         'Step aside, or hear the case? Comment what you would do.', size=92, py=560)
    post('06_seats.jpg', 'politician', still('hub_politician'), '100 seats.\nHow many\nare yours?*',
         'Approval is a chamber that lights up as voters come round.', size=110)
    post('07_ko.jpg', 'fighter', still('stamp_fighter'), 'KO.*',
         'Every career result gets stamped in its own style: THAT\'S A WRAP, SUSTAINED, CODE BLUE.',
         size=220, py=420)
    post('08_busk_or_scam.jpg', 'hustler', still('hub_hustler'), 'Busk it.\nOr scam it.*',
         'Street hustlers can run scams now. Every one leaves evidence.', size=120)
    post('09_one_engine.jpg', 'pilot', still('hub_pilot'), '4,700 hours.\nOne engine\nwarning.*',
         'Divert, or run the checklist and carry on?', size=100)
    whats_new()


def whats_new():
    img = backdrop('night', FW, FH, seed=111)
    d = ImageDraw.Draw(img)
    badge(img, "WHAT'S NEW", 'night')
    y = headline(img, 'night', 'The Calling\nupdate.*', 160, 92) + 24
    rows = [
        ('astronaut', 'ORBIT', 'New: astronauts. The station, the Moon, then Mars.'),
        ('fighter', 'FIGHT NIGHT', 'New: fighters. Boxing or MMA, and a title belt.'),
        ('actor', 'MARQUEE', '14 careers, each with its own look and instrument.'),
        ('lawyer', 'MAHOGANY', 'Your people: a boss, an ally and a rival.'),
        ('hustler', 'MARKET DAY', 'Scams, fixed fights and judges who know the accused.'),
    ]
    for lk, t, s in rows:
        L = LOOKS[lk]
        d.rounded_rectangle((70, y, FW - 70, y + 150), 26, fill=L['bg2'], outline=L['accent'], width=3)
        d.text((104, y + 22), t, font=L['head'](44), fill=L['accent'])
        d.text((104, y + 88), s, font=sora(28, 500), fill=L['text'])
        y += 168
    brand(img, 'night')
    save(img, '10_whats_new.jpg')


# ---------------- Carousel (1080 x 1350) ----------------

SLIDES = [
    ('actor', 'Actor', 'Audition, get cast, win a Golden Reel.'),
    ('musician', 'Musician', 'Write, record, tour. Watch the needle hit the red.'),
    ('athlete', 'Athlete', 'Seasons, injuries and a final under the floodlights.'),
    ('politician', 'Politician', 'Speeches, bills and a chamber to win over.'),
    ('astronaut', 'Astronaut', 'Dock with the station. Then aim higher.'),
    ('fighter', 'Fighter', 'Fight camp, weigh-in, fight night.'),
    ('doctor', 'Doctor', 'Night shifts, triage and a winter crisis.'),
    ('police', 'Police', 'The academy, casework and Internal Affairs.'),
    ('military', 'Armed forces', 'Drills, the officer course and deployments.'),
]


def carousel():
    n = len(SLIDES) + 2
    img = backdrop('night', FW, FH, seed=120)
    headline(img, 'night', 'Swipe\nthrough\n14 careers ›*', 300, 130)
    sub_text(img, 'night', 'Each one changes the whole game: its colours, its type, its world.', 760, 800, 40)
    brand(img, 'night')
    footer(img, 'night', f'1/{n}  swipe ›')
    save(img, 'carousel_01.jpg')
    for i, (lk, title, line) in enumerate(SLIDES, 2):
        img = backdrop(lk, FW, FH, seed=120 + i)
        d = ImageDraw.Draw(img)
        d.text((70, 76), NAMES[lk], font=sora(30, 800), fill=LOOKS[lk]['accent'])
        y = headline(img, lk, title + '.*', 120, 120)
        sub_text(img, lk, line, y, 470)
        ph = phone_layer(still('hub_' + lk), 560, lk, -6 if i % 2 else 6)
        img.paste(ph, (FW - ph.width + 70 if i % 2 else -60, 420), ph)
        bottom_band(img, lk)
        brand(img, lk)
        footer(img, lk, f'{i}/{n}  swipe ›')
        save(img, f'carousel_{i:02d}.jpg')
    img = backdrop('night', FW, FH, seed=140)
    headline(img, 'night', 'Which one\nare you?*', 280, 140, align='center')
    sub_text(img, 'night', '…plus model, lawyer, pilot, vet and street hustler.', 640, 900, 40)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((200, FH - 300, FW - 200, FH - 210), 45, fill=LOOKS['night']['accent'])
    t = 'Play free · link in bio'
    d.text(((FW - d.textlength(t, font=sora(40, 800))) / 2, FH - 282), t, font=sora(40, 800),
           fill=LOOKS['night']['bg1'])
    brand(img, 'night')
    save(img, f'carousel_{n:02d}.jpg')


# ---------------- Stories (1080 x 1920) ----------------

def stories():
    # Astronaut or fighter? A split for the poll sticker.
    img = Image.new('RGB', (SW, SH))
    top = backdrop('astronaut', SW, SH // 2, seed=7)
    bot = backdrop('fighter', SW, SH // 2, seed=8)
    img.paste(top, (0, 0))
    img.paste(bot, (0, SH // 2))
    ph = phone_layer(still('hub_astronaut'), 330, 'astronaut', -8)
    img.paste(ph, (SW - ph.width + 40, 60), ph)
    ph = phone_layer(still('game_fight'), 330, 'fighter', 8)
    img.paste(ph, (-40, SH // 2 + 200), ph)
    d = ImageDraw.Draw(img)
    d.text((70, 400), 'Astronaut', font=sora(130, 800), fill=LOOKS['astronaut']['text'])
    d.text((70, 560), 'the Moon, then Mars', font=sora(48, 600), fill=LOOKS['astronaut']['accent'])
    t = 'FIGHTER'
    d.text((SW - 70 - d.textlength(t, font=stencil(150)), SH // 2 + 140), t, font=stencil(150),
           fill=LOOKS['fighter']['text'])
    t = 'boxing or MMA'
    d.text((SW - 70 - d.textlength(t, font=sora(48, 600)), SH // 2 + 320), t, font=sora(48, 600),
           fill=LOOKS['fighter']['accent'])
    d.ellipse((SW // 2 - 110, SH // 2 - 110, SW // 2 + 110, SH // 2 + 110), fill=(15, 18, 32),
              outline=(255, 184, 107), width=8)
    f = sora(96, 800)
    d.text((SW // 2 - d.textlength('OR', font=f) / 2, SH // 2 - 60), 'OR', font=f, fill=(238, 241, 250))
    save(img, 'story_1_astronaut_or_fighter.jpg')

    # The update story, in Marquee.
    img = backdrop('actor', SW, SH, seed=9)
    scrim(img, 700, 0.5)
    badge(img, 'NEW UPDATE', 'actor', y=240)
    headline(img, 'actor', 'Calling.*', 330, 190)
    d = ImageDraw.Draw(img)
    d.text((70, 570), '14 careers. Each one turns\nthe whole game into its world.', font=sora(48, 600),
           fill=LOOKS['actor']['text'])
    ph = phone_layer(still('hub_actor'), 560, 'actor', -5)
    img.paste(ph, (SW // 2 - ph.width // 2, 740), ph)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((200, SH - 250, SW - 200, SH - 150), 50, fill=LOOKS['actor']['accent'])
    t = 'Play free · link in bio'
    d.text(((SW - d.textlength(t, font=sora(42, 800))) / 2, SH - 228), t, font=sora(42, 800),
           fill=LOOKS['actor']['bg1'])
    save(img, 'story_2_calling.jpg')


# ---------------- Reel (1080 x 1920, with sound) ----------------
#
# 12 seconds at 120 bpm. A beat is 15 frames and every cut lands on one.
#   0.0s  The hook: "Pick a job. The whole game changes." while the game
#         strobes through its looks, so the point lands before a thumb moves.
#   1.5s  The two new careers, then actor and musician: two beats each,
#         whip cuts, and the new ones' best moment (mission success, the KO).
#   5.5s  Four more, one beat each, so the cut speeds up.
#   7.5s  A count to 14 across all fourteen looks, over a riser.
#   9.0s  The drop: "Which one are you?" and the call to action.

FPS = 30
BEAT = 15  # frames a beat at 120 bpm

REEL_LONG = [  # (look, title, line, payoff still for the second beat, sound)
    ('astronaut', 'Astronaut', 'Dock. Then aim for Mars.', 'recap_astronaut', 'win'),
    ('fighter', 'Fighter', 'Read the tell. Take the belt.', 'stamp_fighter', 'hit'),
    ('actor', 'Actor', 'Win a Golden Reel.', None, 'cheer'),
    ('musician', 'Musician', 'Push the needle into the red.', None, 'promote'),
]
REEL_FAST = [('politician', 'Politician', 'news'), ('doctor', 'Doctor', 'heartbeat'),
             ('police', 'Cop', 'siren'), ('athlete', 'Athlete', 'win')]
HOOK = ['astronaut', 'fighter', 'actor', 'musician', 'politician', 'doctor', 'police', 'athlete', 'hustler']


def ease(x):
    return 1 - (1 - max(0.0, min(1.0, x))) ** 3


_backdrops = {}


def bd(lk, seed):
    if (lk, seed) not in _backdrops:
        _backdrops[(lk, seed)] = backdrop(lk, SW, SH, seed=seed)
    return _backdrops[(lk, seed)].copy()


def clip_frame(lk, i):
    fs = sorted(os.listdir(os.path.join(FOOT, 'reel_' + lk)))
    return Image.open(os.path.join(FOOT, 'reel_' + lk, fs[min(i, len(fs) - 1)])).convert('RGB')


def paste_phone(img, scr, lk, width, top, tilt):
    ph = phone_layer(scr, width, lk, tilt)
    img.paste(ph, (SW // 2 - ph.width // 2, top - 80), ph)


def hblur(img, r):
    """A horizontal motion blur for the whip cuts."""
    a = np.asarray(img).astype(np.float32)
    c = np.cumsum(np.pad(a, ((0, 0), (r + 1, r), (0, 0)), mode='edge'), axis=1)
    return Image.fromarray(((c[:, 2 * r + 1:] - c[:, :-2 * r - 1]) / (2 * r + 1)).clip(0, 255).astype(np.uint8))


def whip(prev, cur, t, direction):
    off = int(SW * ease(t))
    img = Image.new('RGB', (SW, SH))
    img.paste(prev, (-off * direction, 0))
    img.paste(cur, ((SW - off) * direction, 0))
    r = int(90 * math.sin(math.pi * min(1, t)))
    return hblur(img, r) if r > 2 else img


def punch(img, s):
    """Zooms the whole frame by s (> 1) about its centre."""
    w, h = int(SW * s), int(SH * s)
    big = img.resize((w, h), Image.BILINEAR)
    return big.crop(((w - SW) // 2, (h - SH) // 2, (w - SW) // 2 + SW, (h - SH) // 2 + SH))


def flash(img, a):
    return Image.blend(img, Image.new('RGB', img.size, (255, 255, 255)), a) if a > 0 else img


def corner_brand(img, lk):
    d = ImageDraw.Draw(img)
    f = sora(30, 800)
    d.text((SW - 70 - d.textlength('RELIVABLE', font=f), 114), 'RELIVABLE', font=f, fill=LOOKS[lk]['muted'])


def career_frame(k, lk, title, line, j, n, payoff=None):
    L = LOOKS[lk]
    img = bd(lk, 300 + k)
    d = ImageDraw.Draw(img)
    tag = NAMES[lk] + ('  ·  NEW' if lk in ('astronaut', 'fighter') else '')
    d.text((70, 110), tag, font=sora(38, 800), fill=L['accent'])
    corner_brand(img, lk)
    rise = int(70 * (1 - ease((j + 1) / 6)))
    y = headline(img, lk, title + '.', 170 + rise, 150 if line else 176)
    if line:
        for ln in wrap(d, line, sora(52, 700), SW - 140):
            d.text((70, y + 12), ln, font=sora(52, 700), fill=L['accent'])
            y += 66
    tilt = -3 if k % 2 else 3
    if payoff and j >= n // 2:
        p = (j - n // 2 + 1) / 5
        paste_phone(img, still(payoff), lk, int(860 + 90 * (1 - ease(p))), 470, tilt)
    else:
        paste_phone(img, clip_frame(lk, j + 10), lk, int(800 + 60 * j / n), 600 - int(30 * j / n), tilt)
    return img


def hook_frame(j):
    lk = HOOK[min(len(HOOK) - 1, j // 5)]
    img = bd(lk, 400)
    shake = (j % 5 == 0) * 10
    paste_phone(img, still('hub_' + lk), lk, 860, 720 + shake, 3 if (j // 5) % 2 else -3)
    corner_brand(img, lk)
    text = 'Pick a job.' if j < BEAT else 'Pick a job.\nThe whole game\nchanges.*'
    headline(img, lk, text, 190, 116, maxw=SW - 120, x=60, color=None)
    return img


def count_frame(j):
    i = min(13, j // 3)
    lk = list(NAMES)[i]
    L = LOOKS[lk]
    img = bd(lk, 500 + i)
    d = ImageDraw.Draw(img)
    n = str(i + 1)
    f = L['head'](520)
    d.text(((SW - d.textlength(n, font=f)) / 2, 470), n, font=f, fill=L['accent'])
    for txt, fy, fnt, col in [('CAREERS', 1120, sora(84, 800), L['text']),
                              (NAMES[lk], 1250, sora(44, 800), L['muted'])]:
        d.text(((SW - d.textlength(txt, font=fnt)) / 2, fy), txt, font=fnt, fill=col)
    return img


def mosaic():
    """All fourteen Hubs' scenes, two across, dimmed: the outro's backdrop."""
    img = Image.new('RGB', (SW, SH))
    tw, th = SW // 2, SH // 7 + 1
    for i, lk in enumerate(NAMES):
        s = still('hub_' + lk)
        crop = s.crop((0, 0, s.width, int(s.width * th / tw)))
        img.paste(crop.resize((tw, th), Image.LANCZOS), ((i % 2) * tw, (i // 2) * th))
    img = img.filter(ImageFilter.GaussianBlur(3))
    return Image.blend(img, Image.new('RGB', img.size, LOOKS['night']['bg1']), 0.62)


def text_layer(text, fnt, fill, pad=20):
    tmp = ImageDraw.Draw(Image.new('L', (1, 1)))
    w, h = int(tmp.textlength(text, font=fnt)), int(fnt.size * 1.3)
    lay = Image.new('RGBA', (w + 2 * pad, h + 2 * pad), (0, 0, 0, 0))
    ImageDraw.Draw(lay).text((pad, pad), text, font=fnt, fill=fill)
    return lay


def paste_scaled(img, lay, cy, s):
    if s <= 0:
        return
    l2 = lay.resize((max(1, int(lay.width * s)), max(1, int(lay.height * s))), Image.BICUBIC)
    img.paste(l2, (SW // 2 - l2.width // 2, int(cy - l2.height / 2)), l2)


def outro_frames(n):
    L = LOOKS['night']
    back = mosaic()
    l1 = text_layer('Which one', sora(150, 800), L['text'])
    l2 = text_layer('are you?', sora(150, 800), L['accent'])
    l3 = text_layer('14 careers · one life · free', sora(46, 700), L['muted'])
    cta = Image.new('RGBA', (720, 120), (0, 0, 0, 0))
    cd = ImageDraw.Draw(cta)
    cd.rounded_rectangle((0, 0, 719, 119), 60, fill=L['accent'])
    t = 'Play free · link in bio'
    cd.text(((720 - cd.textlength(t, font=sora(46, 800))) / 2, 30), t, font=sora(46, 800), fill=L['bg1'])
    for j in range(n):
        img = punch(back, 1.0 + 0.06 * j / n)
        pop = lambda at: 0 if j < at else 1 + 0.25 * (1 - ease((j - at + 1) / 6))  # noqa: E731
        paste_scaled(img, l1, 660, pop(0))
        paste_scaled(img, l2, 820, pop(3))
        paste_scaled(img, l3, 990, pop(14) and 1)
        if j >= 24:
            paste_scaled(img, cta, 1150, pop(24) + 0.03 * math.sin((j - 24) / 30 * 2 * math.pi * 2))
        brand(img, 'night', y=SH - 250, center=True)
        d = ImageDraw.Draw(img)
        d.text(((SW - d.textlength(FOOT_LINE, font=sora(32, 600))) / 2, SH - 150), FOOT_LINE,
               font=sora(32, 600), fill=L['muted'])
        yield flash(img, max(0, 0.9 - j * 0.22))


# ---------------- The score ----------------

RATE = 44100
SOUND_DIR = b.SOUNDS


def _env(n, decay):
    return np.exp(-np.arange(n) / RATE * decay)


def _noise(n, seed):
    return np.random.default_rng(seed).uniform(-1, 1, n)


def _hp(x):
    return np.diff(x, prepend=0)


def _tone(freq, n, harmonics=1):
    t = np.arange(n) / RATE
    return sum(np.sin(2 * np.pi * freq * h * t) / h for h in range(1, harmonics + 1))


def _add(out, at, x, gain=1.0):
    s = int(at * RATE)
    if s >= len(out):
        return
    e = min(len(out), s + len(x))
    out[s:e] += x[: e - s] * gain


def midi(m):
    return 440 * 2 ** ((m - 69) / 12)


def score(beats, events, path, bpm=120):
    """A synthesised four-on-the-floor track with the game's sounds on top.
    beats: (start, end, section) where section is groove, build or drop."""
    beat = 60 / bpm
    secs = max(e for _, e, _ in beats) * beat
    n = int(secs * RATE)
    drums, music = np.zeros(n), np.zeros(n)
    duck = np.ones(n)
    # Am, F, C, G: root and minor or major third.
    prog = [(45, 3), (41, 4), (48, 4), (43, 4)]
    kn = int(0.25 * RATE)
    kt = np.arange(kn) / RATE
    kick = np.sin(2 * np.pi * np.cumsum(45 + 90 * np.exp(-kt * 35)) / RATE) * _env(kn, 9)
    clap = _hp(_noise(int(0.18 * RATE), 1)) * _env(int(0.18 * RATE), 22)
    hat = _hp(_hp(_noise(int(0.05 * RATE), 2))) * _env(int(0.05 * RATE), 80)
    ohat = _hp(_hp(_noise(int(0.2 * RATE), 3))) * _env(int(0.2 * RATE), 18)
    for (b0, b1, sec) in beats:
        for b in range(b0, b1):
            at = b * beat
            root, third = prog[(b // 4) % 4]
            if sec in ('groove', 'drop', 'hook'):
                _add(drums, at, kick, 0.9)
                s = int(at * RATE)
                duck[s:s + int(0.3 * RATE)] = np.minimum(duck[s:s + int(0.3 * RATE)],
                                                         1 - 0.7 * _env(min(int(0.3 * RATE), n - s), 10))
                for q in range(4):
                    _add(drums, at + q * beat / 4, hat, 0.16 if q % 2 else 0.09)
            if sec in ('groove', 'drop'):
                _add(drums, at + beat / 2, ohat, 0.12)
                if b % 2:
                    _add(drums, at, clap, 0.5)
                for q in (0.5, 0.75):  # bass on the offbeats, under the kick
                    bn = int(beat / 4 * RATE)
                    _add(music, at + q * beat, np.tanh(2 * _tone(midi(root), bn, 4)) * _env(bn, 6), 0.32)
            if sec == 'hook':
                bn = int(beat * 0.9 * RATE)
                _add(music, at, np.tanh(2 * _tone(midi(root), bn, 4)) * _env(bn, 5), 0.3)
            if sec == 'build':
                # A snare roll that doubles each beat.
                k = b - b0
                for q in range(2 ** (k + 1)):
                    _add(drums, at + q * beat / 2 ** (k + 1), clap, 0.18 + 0.12 * k)
            # Chords: a bright stab every beat in the groove, held pads in the drop.
            if sec in ('groove', 'hook', 'drop', 'build'):
                cn = int(beat * (1.0 if sec != 'groove' else 0.45) * RATE)
                ch = sum(_tone(midi(root + 12 + iv), cn, 5) for iv in (0, third, 7, 12))
                _add(music, at, ch * _env(cn, 2.5 if sec != 'groove' else 7), 0.05)
    # The riser into the drop, and the hits.
    for (b0, b1, sec) in beats:
        if sec == 'build':
            rn = int((b1 - b0) * beat * RATE)
            ramp = np.linspace(0, 1, rn) ** 2
            sweep = np.sin(2 * np.pi * np.cumsum(np.linspace(220, 1400, rn)) / RATE)
            _add(music, b0 * beat, (_hp(_noise(rn, 5)) * 0.5 + sweep * 0.3) * ramp, 0.5)
        if sec in ('hook', 'drop'):
            bn = int(1.2 * RATE)
            bt = np.arange(bn) / RATE
            boom = np.sin(2 * np.pi * np.cumsum(30 + 60 * np.exp(-bt * 6)) / RATE) * _env(bn, 3)
            _add(drums, b0 * beat, boom, 1.0)
            _add(drums, b0 * beat, _hp(_noise(int(1.5 * RATE), 7)) * _env(int(1.5 * RATE), 3), 0.25)
    out = drums + music * duck
    for (at, name, gain) in events:
        with wave.open(os.path.join(SOUND_DIR, name + '.wav')) as w:
            sr = w.getframerate()
            data = np.frombuffer(w.readframes(w.getnframes()), dtype='<i2').astype(float) / 32768
        data = np.interp(np.arange(0, len(data), sr / RATE), np.arange(len(data)), data)[: int(0.9 * RATE)]
        tail = min(len(data), int(0.08 * RATE))
        data[len(data) - tail:] *= np.linspace(1, 0, tail)
        _add(out, at, data, gain)
    fade = int(0.7 * RATE)
    out[-fade:] *= np.linspace(1, 0, fade)
    out /= np.max(np.abs(out)) + 1e-9
    pcm = (np.tanh(out * 1.6) / np.tanh(1.6) * 0.92 * 32767).astype('<i2')
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(pcm.tobytes())


def reel():
    name = 'reel_calling.mp4'
    tmp = os.path.join(OUT, name + '.video.mp4')
    ff = subprocess.Popen(['ffmpeg', '-y', '-loglevel', 'error', '-f', 'rawvideo', '-pix_fmt', 'rgb24',
                           '-s', f'{SW}x{SH}', '-r', str(FPS), '-i', '-', '-c:v', 'libx264', '-crf', '18',
                           '-preset', 'slow', '-pix_fmt', 'yuv420p', tmp], stdin=subprocess.PIPE)
    frames = 0
    events = []

    def put(img):
        nonlocal frames
        ff.stdin.write(img.tobytes())
        frames += 1

    def sec():
        return frames / FPS

    # The hook: 3 beats.
    events += [(0.0, 'hit', 0.9)]
    prev = None
    for j in range(3 * BEAT):
        if j % 5 == 0 and j:
            events.append((sec(), 'tap', 0.35))
        prev = punch(hook_frame(j), 1 + 0.06 * (1 - ease((j % BEAT + 1) / 5)))
        put(prev)
    # Two beats each, with a whip cut in.
    for k, (lk, title, line, payoff, sfx) in enumerate(REEL_LONG):
        n = 2 * BEAT
        events.append((sec() - 0.12, 'whoosh', 0.55))
        events.append((sec() + (BEAT / FPS if payoff else 0.15), sfx, 0.8))
        for j in range(n):
            img = career_frame(k, lk, title, line, j, n, payoff)
            if j < 5:
                img = whip(prev, img, (j + 1) / 5, 1 if k % 2 == 0 else -1)
            if payoff and j == n // 2:
                img = flash(img, 0.5)
            put(img)
            prev = img
    # One beat each, with a punch cut.
    for k, (lk, title, sfx) in enumerate(REEL_FAST, len(REEL_LONG)):
        events.append((sec(), sfx, 0.6))
        for j in range(BEAT):
            img = career_frame(k, lk, title, None, j, BEAT)
            put(flash(punch(img, 1 + 0.08 * (1 - ease((j + 1) / 4))), 0.35 if j == 0 else 0))
    # The count to 14: 3 beats.
    for j in range(3 * BEAT):
        if j % 3 == 0 and j < 42:
            events.append((sec(), 'tick', 0.5))
        put(count_frame(j))
    drop = frames // BEAT
    events += [(sec(), 'celebrate', 0.9), (sec() + 24 / FPS, 'coin', 0.7)]
    # The drop and the outro: 6 beats.
    for img in outro_frames(6 * BEAT):
        put(img)
    ff.stdin.close()
    ff.wait()
    total = frames // BEAT
    wav = os.path.join(OUT, name + '.wav')
    score([(0, 3, 'hook'), (3, drop - 3, 'groove'), (drop - 3, drop, 'build'), (drop, total, 'drop')],
          events, wav)
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', tmp, '-i', wav, '-c:v', 'copy', '-c:a', 'aac',
                    '-b:a', '192k', '-shortest', '-movflags', '+faststart', os.path.join(OUT, name)], check=True)
    os.remove(tmp)
    os.remove(wav)
    print('wrote', os.path.join(OUT, name), f'({frames / FPS:.1f}s)')


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    b.OUT = OUT
    for part in PARTS:
        globals()[part]()
