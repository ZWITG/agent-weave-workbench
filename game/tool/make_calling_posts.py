"""Instagram batch 2: the "Calling" update (special careers).

Feed posts, a carousel, stories and a Reel, all from real gameplay
rendered by tool/render_calling_promo_test.dart. Each piece wears the look
of the career it shows: Marquee, Orbit, Fight Night, Chamber, Mahogany,
Market Day and the rest, with that look's colours and type. Layout helpers
come from tool/make_social_posts.py (batch 1).

Run from the game folder:
  flutter test tool/render_calling_promo_test.dart --dart-define=OUT=<footage>
  python3 tool/make_calling_posts.py <footage> media/social/calling
"""

import os
import subprocess
import sys

from PIL import Image, ImageDraw

FOOT, OUT = sys.argv[1], sys.argv[2]
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

REEL = [
    ('actor', 'Actor'), ('musician', 'Musician'), ('athlete', 'Athlete'), ('politician', 'Politician'),
    ('astronaut', 'Astronaut'), ('fighter', 'Fighter'), ('doctor', 'Doctor'), ('police', 'Police'),
]


def reel():
    name = 'reel_calling.mp4'
    per = 45  # frames a look: 1.5 seconds
    outro = 60
    secs = (len(REEL) * per + outro) / 30
    tmp = os.path.join(OUT, name + '.video.mp4')
    ff = subprocess.Popen(['ffmpeg', '-y', '-loglevel', 'error', '-f', 'rawvideo', '-pix_fmt', 'rgb24',
                           '-s', f'{SW}x{SH}', '-r', '30', '-i', '-', '-c:v', 'libx264', '-crf', '19',
                           '-pix_fmt', 'yuv420p', tmp], stdin=subprocess.PIPE)
    events = [(0.0, 'whoosh', 0.6)]
    for k, (lk, title) in enumerate(REEL):
        base = backdrop(lk, SW, SH, seed=200 + k)
        d = ImageDraw.Draw(base)
        d.text((70, 120), NAMES[lk], font=sora(40, 800), fill=LOOKS[lk]['accent'])
        headline(base, lk, f'POV: you\'re\na {title.lower()}.*' if title[0] not in 'AEIOU'
                 else f'POV: you\'re\nan {title.lower()}.*', 180, 110)
        brand(base, lk, y=SH - 150, center=True)
        events.append((k * per / 30, 'promote' if k % 2 else 'tap', 0.7))
        frames = sorted(os.listdir(os.path.join(FOOT, 'reel_' + lk)))
        for i in range(per):
            img = base.copy()
            scr = Image.open(os.path.join(FOOT, 'reel_' + lk, frames[i % len(frames)])).convert('RGB')
            # The phone pops in, then settles.
            grow = min(1, (i + 1) / 6)
            ph = phone_layer(scr, int(600 * (0.92 + 0.08 * grow)), lk, -4 if k % 2 else 4)
            img.paste(ph, (SW // 2 - ph.width // 2, 520), ph)
            ff.stdin.write(img.tobytes())
    # The outro.
    end = backdrop('night', SW, SH, seed=230)
    headline(end, 'night', 'Which one\nare you?*', 640, 150, align='center')
    d = ImageDraw.Draw(end)
    t = '14 careers · free to play'
    d.text(((SW - d.textlength(t, font=sora(48, 700))) / 2, 1020), t, font=sora(48, 700),
           fill=LOOKS['night']['muted'])
    brand(end, 'night', y=SH - 220, center=True)
    events.append((len(REEL) * per / 30, 'celebrate', 0.9))
    for _ in range(outro):
        ff.stdin.write(end.tobytes())
    ff.stdin.close()
    ff.wait()
    wav = os.path.join(OUT, name + '.wav')
    tone_sfx(events, secs, wav, bpm=120, mood='gold')
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', tmp, '-i', wav, '-c:v', 'copy', '-c:a', 'aac',
                    '-b:a', '160k', '-shortest', '-movflags', '+faststart', os.path.join(OUT, name)], check=True)
    os.remove(tmp)
    os.remove(wav)
    print('wrote', os.path.join(OUT, name))


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    b.OUT = OUT
    for part in sys.argv[4:] or ['feed', 'carousel', 'stories', 'reel']:
        globals()[part]()
