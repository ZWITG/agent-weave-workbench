"""Social batch 3: "Encore" (a game for every career) and "A long life"
(pins, turning points, back issues), for Instagram and TikTok.

House style: docs/ad-styles/relivable.md (the "Calling" reel style):
eyebrow tag, muted wordmark, serif headline ending in a full stop, a tilted
phone showing the real game, one accent per career, and a collage CTA
close. Layout and sound helpers come from make_calling_posts.py (batch 2).

Every still is real gameplay. Render them first, then gather them in one
folder's stills/:
  flutter test tool/render_calling_promo_test.dart --dart-define=OUT=<foot>
  flutter test tool/render_life_hub_promo_test.dart --dart-define=OUT=<foot>
  python3 tool/make_batch3_posts.py <foot> media/social/batch3 [feed carousels stories reels]
"""

import math
import os
import subprocess
import sys

from PIL import Image, ImageDraw

FOOT, OUT = sys.argv[1], sys.argv[2]
PARTS = sys.argv[3:] or ['feed', 'carousels', 'stories', 'reels']
sys.argv = [sys.argv[0], FOOT, OUT]
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_calling_posts as cp  # noqa: E402
import make_social_posts as b  # noqa: E402

from make_calling_posts import (  # noqa: E402
    BEAT, FOOT_LINE, FPS, LOOKS, NAMES, brand, corner_brand, ease, flash, headline, look, mosaic,
    paste_scaled, phone_layer, punch, score, serif, sora, still, sub_text, text_layer, whip, wrap,
)
from make_social_posts import FH, FW, SH, SW, backdrop, badge, bottom_band, footer, save  # noqa: E402

# Two looks for the long-life posts: the game's own Night Feed, and
# newsprint for the paper (sepia ink fading to near-black).
LOOKS['press'] = look('100C07', '2B2215', 'C9A15A', 'F2D9A0', 'F2D9A0', 'F5EEDF', 'B3A68C', serif)

ENCORE = [  # (career look, still, eyebrow, headline, sub)
    ('actor', 'coldread', 'MARQUEE · COLD READ', 'Hold it\nback.*',
     '"I\'m fine. Really." She has just lost the case. Read the note, then pick the delivery.'),
    ('doctor', 'triage', 'NIGHT SHIFT · TRIAGE', 'Resus.\nMajors.\nMinors.*',
     'Send each arrival to the right bay. Under-triage costs most. It gets faster.'),
    ('pilot', 'crosswind', 'FLIGHT DECK · CROSSWIND', 'Crab.\nFlare.\nLand.*',
     'Crab into the gusts, then flare. Every seat needs a check ride.'),
    ('lawyer', 'objection', 'MAHOGANY · CROSS-EXAM', 'Objection.*',
     'Object when the testimony doesn\'t square with your notes. And to hearsay.'),
    ('politician', 'debate', 'CHAMBER · THE DEBATE', 'Read the\nroom.*',
     'Pick the rebuttal the room wants to hear. Approval fills the seats.'),
    ('musician', 'soundcheck', 'BACKSTAGE · SOUNDCHECK', 'Ride the\nfaders.*',
     'Four faders, a room filling up, and a needle you want in the red.'),
    ('model', 'runway', 'RUNWAY · THE WALK', 'Turn.\nPose.\nWalk.*',
     'Turn to the press pit, then pose to the brief.'),
    ('athlete', 'matchday', 'FLOODLIGHTS · MATCH DAY', 'Pass or\nshoot?*',
     'Find the open teammate, or take it yourself.'),
    ('military', 'obstacle', 'FIELD KIT · OBSTACLES', 'Wall.\nWire.\nWater.*',
     'The right move for every obstacle, faster as you tire.'),
    ('vet', 'diagnose', 'MEADOW · DIAGNOSE', 'Two signs.\nOne cause.*',
     'Match the signs to the cause. The handbook is open.'),
    ('hustler', 'pitch', 'MARKET DAY · THE PITCH', 'Not while\nhe\'s\nlooking.*',
     'Call out to people who are looking. Never while an officer passes.'),
]


def cut(name, *bands):
    """A real screenshot with the parts that matter brought together: each
    (top, bottom) band in order, joined edge to edge, so the phone shows the
    moment (the line, the patient, the buttons) instead of empty space."""
    s = still(name)
    out = Image.new('RGB', (s.width, sum(b1 - b0 for b0, b1 in bands)))
    y = 0
    for b0, b1 in bands:
        out.paste(s.crop((0, b0, s.width, b1)), (0, y))
        y += b1 - b0
    return out


def enc(game):
    # 2x stills (780 x 1688): the title bar, the progress and notes, then
    # the prompt and the answer buttons.
    if game == 'crosswind':  # the runway is the moment: keep it whole
        return cut('encore_' + game, (0, 130), (440, 1420))
    return cut('encore_' + game, (0, 130), (440, 640), (720, 1420))


def paper(name):
    # The masthead, the lead story and the first section.
    return cut(name, (0, 1120))


def turning():
    # The header, then the filtered feed down to the search bar.
    return cut('life_turning_points', (0, 170), (180, 1120))


def pinned():
    # Keep the name header, skip the stat tiles, start at Pinned.
    return cut('life_pinned', (0, 180), (520, 1688))


def eyebrow(img, text, lk, x=70, y=76):
    """The house eyebrow: small, bold, letter-spaced, in the frame's accent."""
    d = ImageDraw.Draw(img)
    f = sora(28, 800)
    for ch in text:
        d.text((x, y), ch, font=f, fill=LOOKS[lk]['accent'])
        x += d.textlength(ch, font=f) + 3
    return y + 40


def wordmark(img, lk, y=76):
    d = ImageDraw.Draw(img)
    f = sora(28, 800)
    t = 'RELIVABLE'
    x = img.size[0] - 70 - (d.textlength(t, font=f) + 3 * len(t))
    for ch in t:
        d.text((x, y), ch, font=f, fill=LOOKS[lk]['muted'])
        x += d.textlength(ch, font=f) + 3


def post(name, lk, scr, tag, head, sub, *, size=112, tilt=-7, phone_w=560, sub_w=520, foot=None):
    img = backdrop(lk, FW, FH, seed=sum(map(ord, name)))
    y = eyebrow(img, tag, lk)
    wordmark(img, lk)
    y = headline(img, lk, head, y + 30, size, maxw=FW - 140)
    if sub:
        y = sub_text(img, lk, sub, y, sub_w)
    paste_phone_above_band(img, scr, lk, tilt, y, phone_w)
    bottom_band(img, lk)
    brand(img, lk)
    footer(img, lk, foot or FOOT_LINE)
    save(img, name)


def paste_phone_above_band(img, scr, lk, tilt, text_bottom, phone_w=560, x=None):
    """The phone's bottom edge sits just above the brand band, so the answer
    buttons stay visible; it shrinks when the headline runs long."""
    for w in range(phone_w, 380, -30):
        ph = phone_layer(scr, w, lk, tilt)
        top = FH - 175 - (ph.height - 80)
        if top >= text_bottom - 110:
            break
    img.paste(ph, (FW - ph.width + 80 if x is None else x, top), ph)


def cta_pill(img, lk, y, text='Play free · link in bio', size=42):
    d = ImageDraw.Draw(img)
    W = img.size[0]
    f = sora(size, 800)
    w = d.textlength(text, font=f) + 120
    d.rounded_rectangle(((W - w) / 2, y, (W + w) / 2, y + size * 2.2), size * 1.1, fill=LOOKS[lk]['accent'])
    d.text(((W - d.textlength(text, font=f)) / 2, y + size * 0.5), text, font=f, fill=LOOKS[lk]['bg1'])


def close_frame(W, H, line1, line2, stat, name=None):
    """The house closing frame: dimmed collage, two-line serif, stat, CTA."""
    back = mosaic()
    img = back.resize((W, int(back.height * W / back.width))).crop((0, 0, W, H)) if H != SH else back
    L = LOOKS['night']
    y = H * 0.30
    d = ImageDraw.Draw(img)
    for t, col in [(line1, L['text']), (line2, L['accent'])]:
        f = serif(132)
        d.text(((W - d.textlength(t, font=f)) / 2, y), t, font=f, fill=col)
        y += 168
    f = sora(40, 600)
    d.text(((W - d.textlength(stat, font=f)) / 2, y + 40), stat, font=f, fill=L['muted'])
    cta_pill(img, 'night', int(y + 140))
    brand(img, 'night', y=H - 230, center=True)
    f = sora(30, 600)
    d.text(((W - d.textlength(FOOT_LINE, font=f)) / 2, H - 140), FOOT_LINE, font=f, fill=L['muted'])
    if name:
        save(img, name)
    return img


# ---------------- Feed posts (1080 x 1350) ----------------

def feed():
    # 01: the announcement. Three careers, three new games.
    img = backdrop('night', FW, FH, seed=301)
    eyebrow(img, 'NEW UPDATE · ENCORE', 'night')
    wordmark(img, 'night')
    y = headline(img, 'night', 'Every job.\nIts own\ngame.*', 150, 120)
    sub_text(img, 'night', '11 careers just got their own mini-game.', y, 560, 38)
    for (scr, lk, x, t, w, yy) in [
        ('coldread', 'actor', -60, -9, 330, 640),
        ('crosswind', 'pilot', FW - 410, 9, 330, 640),
        ('triage', 'doctor', None, 0, 360, 590),
    ]:
        ph = phone_layer(enc(scr), w, lk, t)
        img.paste(ph, (FW // 2 - ph.width // 2 if x is None else x, yy), ph)
    bottom_band(img, 'night')
    brand(img, 'night')
    footer(img, 'night', FOOT_LINE)
    save(img, '01_every_job_its_own_game.jpg')

    for i, (lk, g, tag, head, sub) in enumerate(ENCORE, 2):
        lines = head.count('\n') + 1
        post(f'{i:02d}_{g}.jpg', lk, enc(g), tag, head, sub,
             size=150 if lines == 1 else (128 if lines == 2 else 112), tilt=-7 if i % 2 else 7)

    # The long life.
    post('13_pinned.jpg', 'night', pinned(), 'LIFE HUB · NEW',
         'You haven\'t\nseen your dad\nin 19 years.*',
         'Pin anyone. The year feed tells you when it matters: birthdays, news, long silences.',
         size=100)
    post('14_turning_points.jpg', 'night', turning(), 'LIFE HUB · TURNING POINTS',
         'Every big\nmoment.\nOne place.*',
         'Marrying, prison, your first flat. From birth on, nothing dropped.', size=110, tilt=7)
    post('15_back_issue.jpg', 'press', paper('news_back_issue'), 'THE PAPER · BACK ISSUES',
         'Read any\nyear\'s\npaper.*',
         'Search by year or by a word. Even the years your ancestors lived.', size=120)
    post('16_front_page.jpg', 'press', paper('news_today'), 'THE PAPER',
         'Make the\nfront page.*', 'The world prints what happened this year. Sometimes it\'s you.',
         size=128, tilt=7)
    whats_new()


def whats_new():
    img = backdrop('night', FW, FH, seed=317)
    d = ImageDraw.Draw(img)
    eyebrow(img, "WHAT'S NEW", 'night')
    wordmark(img, 'night')
    y = headline(img, 'night', 'Encore.*', 140, 120) + 10
    rows = [
        ('actor', 'MARQUEE', '11 careers, 11 new mini-games of their own.'),
        ('athlete', 'FLOODLIGHTS', 'Second acts: coach, pundit, director, designer.'),
        ('doctor', 'NIGHT SHIFT', 'Careers reach your life: co-stars, doping, lawsuits.'),
        ('lawyer', 'MAHOGANY', 'Youth unit and restorative justice in prison.'),
        ('press', 'THE PAPER', 'Pins, turning points and back issues.'),
    ]
    for lk, t, s in rows:
        L = LOOKS[lk]
        d.rounded_rectangle((70, y, FW - 70, y + 150), 26, fill=L['bg2'], outline=L['accent'], width=3)
        d.text((104, y + 22), t, font=L['head'](44), fill=L['accent'])
        d.text((104, y + 88), s, font=sora(28, 500), fill=L['text'])
        y += 168
    brand(img, 'night')
    save(img, '17_whats_new.jpg')


# ---------------- Carousels (1080 x 1350) ----------------

def carousels():
    # A: 11 careers, 11 games.
    n = len(ENCORE) + 2
    img = backdrop('night', FW, FH, seed=330)
    eyebrow(img, 'ENCORE · SWIPE', 'night')
    wordmark(img, 'night')
    headline(img, 'night', '11 careers.\n11 new\ngames ›*', 300, 128)
    sub_text(img, 'night', 'Each one plays like the job. Swipe to find yours.', 760, 800, 40)
    brand(img, 'night')
    footer(img, 'night', f'1/{n}  swipe ›')
    save(img, 'carousel_a_01.jpg')
    for i, (lk, g, tag, head, sub) in enumerate(ENCORE, 2):
        img = backdrop(lk, FW, FH, seed=330 + i)
        y = eyebrow(img, tag, lk)
        wordmark(img, lk)
        y = headline(img, lk, head.replace('\n', ' ').replace('*', '') + '*', y + 30, 104, maxw=FW - 140)
        y = sub_text(img, lk, sub, y, 520, 34)
        paste_phone_above_band(img, enc(g), lk, -6 if i % 2 else 6, y, x=None if i % 2 else -70)
        bottom_band(img, lk)
        brand(img, lk)
        footer(img, lk, f'{i}/{n}  swipe ›')
        save(img, f'carousel_a_{i:02d}.jpg')
    close_frame(FW, FH, 'Which game', 'is yours?', '14 careers · one life · free', f'carousel_a_{n:02d}.jpg')

    # B: keeping track of a long life.
    slides = [
        ('night', 'life_pinned', 'PINNED', 'Pin who\nmatters.*', 'Bond, when you last met, their news. Or your release date.'),
        ('night', 'life_turning_points', 'TURNING POINTS', 'Your life\'s\nbig moments.*', 'A filter that keeps every one, from birth on.'),
        ('press', 'news_back_issue', 'BACK ISSUES', 'Any year\'s\nfront page.*', 'Search by year or by a word. Your ancestors\' years too.'),
        ('press', 'news_today', 'THE PAPER', 'The world\nkeeps going.*', 'And it remembers what you did.'),
    ]
    n = len(slides) + 2
    img = backdrop('press', FW, FH, seed=360)
    eyebrow(img, 'LIFE HUB · SWIPE', 'press')
    wordmark(img, 'press')
    headline(img, 'press', 'Keeping track\nof a long\nlife ›*', 300, 120)
    sub_text(img, 'press', 'Eighty years, eight generations. Here\'s how you follow it.', 760, 800, 40)
    brand(img, 'press')
    footer(img, 'press', f'1/{n}  swipe ›')
    save(img, 'carousel_b_01.jpg')
    for i, (lk, s, tag, head, sub) in enumerate(slides, 2):
        post(f'carousel_b_{i:02d}.jpg', lk, {'life_pinned': pinned, 'life_turning_points': turning}.get(s, lambda: paper(s))(), tag, head, sub, size=112,
             tilt=-6 if i % 2 else 6, foot=f'{i}/{n}  swipe ›')
    close_frame(FW, FH, 'One life.', 'Every year of it.', 'every choice remembered · free', f'carousel_b_{n:02d}.jpg')


# ---------------- Stories (1080 x 1920) ----------------

def split_story(name, top, bot, a, b_, ga, gb):
    img = Image.new('RGB', (SW, SH))
    img.paste(backdrop(top, SW, SH // 2, seed=7), (0, 0))
    img.paste(backdrop(bot, SW, SH // 2, seed=8), (0, SH // 2))
    ph = phone_layer(enc(ga), 330, top, -8)
    img.paste(ph, (SW - ph.width + 40, 60), ph)
    ph = phone_layer(enc(gb), 330, bot, 8)
    img.paste(ph, (-40, SH // 2 + 200), ph)
    d = ImageDraw.Draw(img)
    d.text((70, 420), a[0], font=LOOKS[top]['head'](130), fill=LOOKS[top]['text'])
    d.text((70, 590), a[1], font=sora(46, 700), fill=LOOKS[top]['accent'])
    f = LOOKS[bot]['head'](130)
    d.text((SW - 70 - d.textlength(b_[0], font=f), SH // 2 + 160), b_[0], font=f, fill=LOOKS[bot]['text'])
    f = sora(46, 700)
    d.text((SW - 70 - d.textlength(b_[1], font=f), SH // 2 + 330), b_[1], font=f, fill=LOOKS[bot]['accent'])
    d.ellipse((SW // 2 - 110, SH // 2 - 110, SW // 2 + 110, SH // 2 + 110), fill=(15, 18, 32),
              outline=(255, 184, 107), width=8)
    f = sora(96, 800)
    d.text((SW // 2 - d.textlength('OR', font=f) / 2, SH // 2 - 60), 'OR', font=f, fill=(238, 241, 250))
    save(img, name)


def story_feature(name, lk, scr, tag, head, line, cta='Play free · link in bio'):
    img = backdrop(lk, SW, SH, seed=sum(map(ord, name)))
    y = eyebrow(img, tag, lk, y=230)
    wordmark(img, lk, y=230)
    y = headline(img, lk, head, y + 30, 150) + 30
    d = ImageDraw.Draw(img)
    for ln in wrap(d, line, sora(46, 600), SW - 140):
        d.text((70, y + 10), ln, font=sora(46, 600), fill=LOOKS[lk]['text'])
        y += 60
    ph = phone_layer(scr, 540, lk, -5)
    img.paste(ph, (SW // 2 - ph.width // 2, max(y + 10, 760)), ph)
    if cta:
        bottom_band(img, lk)
        cta_pill(img, lk, SH - 260, cta)
    save(img, name)


def stories():
    split_story('story_1_hold_or_rip.jpg', 'actor', 'doctor', ('Actor', 'hold it back'), ('Doctor', 'resus or minors'),
                'coldread', 'triage')
    split_story('story_2_pass_or_shoot.jpg', 'athlete', 'lawyer', ('Athlete', 'pass or shoot'),
                ('Lawyer', 'object or let it go'), 'matchday', 'objection')
    story_feature('story_3_encore.jpg', 'pilot', enc('crosswind'), 'NEW UPDATE', 'Encore.*',
                  '11 careers. 11 new games. Every job plays like the job.')
    story_feature('story_4_born_year.jpg', 'press', paper('news_back_issue'), 'BACK ISSUES',
                  'What year\nwere you\nborn?*', 'Reply with it. We\'ll tell you the headline.', cta=None)
    story_feature('story_5_pinned.jpg', 'night', pinned(), 'LIFE HUB · NEW', 'Pin them.*',
                  'Never lose track of the people who matter.')
    story_feature('story_6_runway.jpg', 'model', enc('runway'), 'RUNWAY', 'Your turn.*',
                  'Turn to the press pit. Pose to the brief.')


# ---------------- Reels / TikToks (1080 x 1920, with sound) ----------------
#
# Every video is built the same way as the Calling reel: on a 120 bpm grid
# (a beat is 15 frames), cuts land on the beat, with a hook in the first
# second and the collage close at the end. The same file goes to Instagram
# Reels and TikTok; only the caption changes.

_bd = {}


def bd(lk, seed):
    if (lk, seed) not in _bd:
        _bd[(lk, seed)] = backdrop(lk, SW, SH, seed=seed)
    return _bd[(lk, seed)].copy()


def game_frame(k, lk, tag, head, scr, j, n, line=None, size=150):
    """One beat-frame: eyebrow, wordmark, serif headline, tilted phone."""
    L = LOOKS[lk]
    img = bd(lk, 600 + k)
    d = ImageDraw.Draw(img)
    f = sora(36, 800)
    d.text((70, 110), tag, font=f, fill=L['accent'])
    corner_brand(img, lk)
    rise = int(70 * (1 - ease((j + 1) / 6)))
    y = headline(img, lk, head, 180 + rise, size, maxw=SW - 140)
    if line:
        for ln in wrap(d, line, sora(48, 700), SW - 140):
            d.text((70, y + 12), ln, font=sora(48, 700), fill=L['accent'])
            y += 62
    w = int(780 + 70 * j / max(1, n))
    ph = phone_layer(scr, w, lk, -3 if k % 2 else 3)
    img.paste(ph, (SW // 2 - ph.width // 2, max(y - 40, 640) - int(30 * j / max(1, n))), ph)
    return img


def outro(n, line1, line2, stat):
    L = LOOKS['night']
    base = mosaic()
    l1 = text_layer(line1, serif(150), L['text'])
    l2 = text_layer(line2, serif(150), L['accent'])
    l3 = text_layer(stat, sora(46, 700), L['muted'])
    for j in range(n):
        img = punch(base, 1.0 + 0.06 * j / n)
        pop = lambda at: 0 if j < at else 1 + 0.25 * (1 - ease((j - at + 1) / 6))  # noqa: E731
        paste_scaled(img, l1, 660, pop(0))
        paste_scaled(img, l2, 830, pop(3))
        paste_scaled(img, l3, 1000, pop(12) and 1)
        if j >= 20:
            cta_pill(img, 'night', 1110)
        brand(img, 'night', y=SH - 250, center=True)
        d = ImageDraw.Draw(img)
        d.text(((SW - d.textlength(FOOT_LINE, font=sora(32, 600))) / 2, SH - 150), FOOT_LINE,
               font=sora(32, 600), fill=L['muted'])
        yield flash(img, max(0, 0.9 - j * 0.22))


class Reel:
    def __init__(self, name):
        self.name = name
        self.tmp = os.path.join(OUT, name + '.video.mp4')
        self.ff = subprocess.Popen(
            ['ffmpeg', '-y', '-loglevel', 'error', '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-s', f'{SW}x{SH}',
             '-r', str(FPS), '-i', '-', '-c:v', 'libx264', '-crf', '18', '-preset', 'medium', '-pix_fmt',
             'yuv420p', self.tmp], stdin=subprocess.PIPE)
        self.frames = 0
        self.events = []
        self.prev = None

    def sec(self):
        return self.frames / FPS

    def put(self, img):
        self.ff.stdin.write(img.convert('RGB').tobytes())
        self.frames += 1
        self.prev = img

    def sfx(self, name, gain=0.6, at=None):
        self.events.append((self.sec() if at is None else at, name, gain))

    def beats(self, fn, n, whip_in=True, direction=1):
        for j in range(n):
            img = fn(j)
            if whip_in and self.prev is not None and j < 5:
                img = whip(self.prev, img, (j + 1) / 5, direction)
            self.put(img)

    def finish(self, sections):
        self.ff.stdin.close()
        self.ff.wait()
        wav = os.path.join(OUT, self.name + '.wav')
        score(sections(self.frames // BEAT), self.events, wav)
        subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', self.tmp, '-i', wav, '-c:v', 'copy', '-c:a',
                        'aac', '-b:a', '192k', '-shortest', '-movflags', '+faststart',
                        os.path.join(OUT, self.name)], check=True)
        os.remove(self.tmp)
        os.remove(wav)
        print('wrote', os.path.join(OUT, self.name), f'({self.frames / FPS:.1f}s)')


def std_sections(drop):
    return lambda total: [(0, 2, 'hook'), (2, drop - 2, 'groove'), (drop - 2, drop, 'build'), (drop, total, 'drop')]


def reel_encore():
    """R1: every job, its own game. 11 games on the beat, ~15 s."""
    r = Reel('reel_1_every_job.mp4')
    r.sfx('hit', 0.9, 0)
    r.beats(lambda j: punch(game_frame(0, 'night', 'NEW UPDATE · ENCORE', 'Every job.\nIts own\ngame.*',
                                       enc(ENCORE[(j // 5) % 11][1]), j, 2 * BEAT), 1.0 + 0.04 * (j % 5 == 0)),
            2 * BEAT, whip_in=False)
    for k, (lk, g, tag, head, sub) in enumerate(ENCORE):
        r.sfx('whoosh', 0.45, r.sec() - 0.1)
        r.sfx(['tap', 'coin', 'tick'][k % 3], 0.5)
        r.beats(lambda j: game_frame(k + 1, lk, tag, head.replace('\n', ' '), enc(g), j, BEAT, size=128), BEAT,
                direction=1 if k % 2 else -1)
    drop = r.frames // BEAT
    r.sfx('celebrate', 0.9)
    for img in outro(5 * BEAT, 'Which game', 'is yours?', '14 careers · one life · free'):
        r.put(img)
    r.finish(std_sections(drop))


def reel_single(name, lk, g, tag, q, choices, reveal):
    """A 'what would you do' video for one game: question, game, choices, the close."""
    r = Reel(name)
    r.sfx('hit', 0.9, 0)
    r.beats(lambda j: game_frame(0, lk, tag, q, enc(g), j, 3 * BEAT, size=120), 3 * BEAT, whip_in=False)
    for k, c in enumerate(choices):
        r.sfx('tap', 0.6)
        r.beats(lambda j: punch(game_frame(1, lk, tag, c, enc(g), j, BEAT, size=170),
                                1 + 0.07 * (1 - ease((j + 1) / 4))), BEAT, whip_in=False)
    r.sfx('whoosh', 0.5, r.sec() - 0.1)
    r.beats(lambda j: game_frame(2, lk, tag, reveal, enc(g), j, 3 * BEAT, size=110), 3 * BEAT, direction=-1)
    drop = r.frames // BEAT
    r.sfx('celebrate', 0.8)
    for img in outro(4 * BEAT, 'What would', 'you do?', 'comment below · play free'):
        r.put(img)
    r.finish(std_sections(drop))


def reel_long_life():
    """R5: a long life. Pins, turning points, back issues."""
    r = Reel('reel_5_long_life.mp4')
    r.sfx('hit', 0.9, 0)
    r.beats(lambda j: game_frame(0, 'night', 'LIFE HUB · NEW', 'You haven\'t\nseen your dad\nin 19 years.*',
                                 pinned(), j, 4 * BEAT, size=120), 4 * BEAT, whip_in=False)
    for k, (lk, s, tag, head) in enumerate([
        ('night', 'life_turning_points', 'TURNING POINTS', 'Every big\nmoment.*'),
        ('press', 'news_back_issue', 'BACK ISSUES', 'Any year.\nAny word.*'),
        ('press', 'news_today', 'THE PAPER', 'Make the\nfront page.*'),
    ]):
        r.sfx('whoosh', 0.45, r.sec() - 0.1)
        r.sfx('news' if lk == 'press' else 'tap', 0.55)
        r.beats(lambda j: game_frame(k + 1, lk, tag, head, still(s), j, 2 * BEAT, size=140), 2 * BEAT,
                direction=1 if k % 2 else -1)
    drop = r.frames // BEAT
    r.sfx('celebrate', 0.8)
    for img in outro(4 * BEAT, 'One life.', 'Every year.', 'every choice remembered · free'):
        r.put(img)
    r.finish(std_sections(drop))


def reel_quiz():
    """R6: which career are you? A fast 1-to-11 count through the games."""
    r = Reel('reel_6_which_are_you.mp4')
    r.sfx('hit', 0.9, 0)
    r.beats(lambda j: game_frame(0, 'night', 'SCREENSHOT TO PICK', 'Stop the\nscroll on\nyour job.*',
                                 enc('coldread'), j, 2 * BEAT, size=120), 2 * BEAT, whip_in=False)
    for k, (lk, g, tag, head, sub) in enumerate(ENCORE):
        r.sfx('tick', 0.55)
        title = tag.split(' · ')[1].title()

        def fn(j, lk=lk, g=g, title=title, k=k):
            img = game_frame(k + 1, lk, f'{k + 1} / 11', title + '.', enc(g), j, 8, size=150)
            return flash(img, 0.3) if j == 0 else img
        r.beats(fn, 8, whip_in=False)
    drop = r.frames // BEAT
    r.sfx('celebrate', 0.8)
    for img in outro(4 * BEAT, 'Which one', 'did you get?', 'comment it · play free'):
        r.put(img)
    r.finish(std_sections(drop))


def reels():
    reel_encore()
    reel_single('reel_2_cold_read.mp4', 'actor', 'coldread', 'MARQUEE · COLD READ',
                '"I\'m fine.\nReally."*', ['Hold it\nback?', 'Play it\nstraight?', 'Let it\nrip?'],
                'She just lost\nthe case.\nShe is not\nfine.*')
    reel_single('reel_3_triage.mp4', 'doctor', 'triage', 'NIGHT SHIFT · TRIAGE',
                'Man, 65.\nFell. Can\'t\nstand.*', ['Resus?', 'Majors?', 'Minors?'],
                'Under-triage\ncosts most.\nIt gets\nfaster.*')
    reel_single('reel_4_objection.mp4', 'lawyer', 'objection', 'MAHOGANY · CROSS-EXAM',
                '"I was at the\ncorner\nshop."*', ['Object?', 'Let it\ngo?', 'Hearsay?'],
                'Check it\nagainst your\nnotes.*')
    reel_long_life()
    reel_quiz()


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    b.OUT = OUT
    cp.OUT = OUT
    for part in PARTS:
        globals()[part]()
