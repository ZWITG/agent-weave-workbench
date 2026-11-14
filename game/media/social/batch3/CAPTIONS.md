# Relivable · batch 3: "Encore" and "A long life" (Instagram + TikTok)

Everything here is real gameplay from the 14 Nov updates: the Encore
mini-games (one per career) and the Life hub additions (pins, turning
points, back issues). Built in the house style in
`docs/ad-styles/relivable.md`: eyebrow tag, muted wordmark, serif
headline ending in a full stop, a tilted phone with the real game, one
colour per career, and the collage close.

Sizes: feed and carousels 1080×1350 (4:5); stories, Reels and TikToks
1080×1920 (9:16) MP4 with sound. Regenerate after a game update with:

```
flutter test tool/render_calling_promo_test.dart --dart-define=OUT=<foot>/calling
flutter test tool/render_life_hub_promo_test.dart --dart-define=OUT=<foot>/batch3
mkdir -p <foot>/all/stills && cp <foot>/calling/stills/*.png <foot>/batch3/stills/*.png <foot>/all/stills/
python3 tool/make_batch3_posts.py <foot>/all media/social/batch3
```

**What's in the batch (48 files):** 17 feed posts, 2 carousels (13 + 6
slides), 6 stories, 6 videos (each used as an Instagram Reel *and* a
TikTok).

> **Before boosting any of these as paid ads:** "Relivable" is an open
> trademark question (`docs/phase-2/01 Phase 2 Open Items.md`, A7). Posting
> organically is how batches 1 and 2 went out; putting money behind the name
> waits for IP counsel. Every post below is written so it can be boosted
> later without changes.

**Bio link:** `zwitg.github.io/relivable` (or the current web address).
**Guardrails (from `docs/phase-1/10 Go-to-Market.md` §1.3):** never name
BitLife, don't headline AI, nothing aimed at children.

---

## How to schedule it for free

No paid tool needed. Both apps have a scheduler built in:

- **Instagram → Meta Business Suite** (business.facebook.com, or the Meta
  Business Suite app). *Create post* or *Create reel* → add the file → paste
  the caption → *Schedule* → pick the date and time below. Up to 75 days
  ahead, so the whole month can go in one sitting. Stories: *Create story*
  → *Schedule*. Poll and link stickers can't be added to a scheduled story
  in every region; if yours can't, post the two sticker stories (marked ★)
  live from the Instagram app on the day.
- **TikTok → TikTok Studio** on a computer (tiktok.com/tiktokstudio →
  *Upload* → *Schedule*). It schedules up to 10 days ahead, so load TikTok in
  three sittings: **Sun 15 Nov** (posts to 25 Nov), **Tue 24 Nov** (to
  4 Dec), **Thu 3 Dec** (to 13 Dec). Photo posts: upload the images
  together and TikTok makes a swipeable photo post; add a trending sound in
  the app.

Times are **your local time**. They are early-evening slots, when both
apps
are busiest for a 16–24 audience: Instagram feed 6:00 pm, Instagram Reels
7:00 pm, TikTok 7:30 pm on weekdays and 12:30 pm at weekends. After two
weeks, check each app's insights for when *your* followers are online and
move the remaining slots to match.

---

## The release plan (4 weeks, Mon 16 Nov → Sun 13 Dec 2026)

The month runs in four phases. It opens loud with the update, spends the
middle two weeks showing one career at a time (each one a new reason to
look), then shifts to the "long life" features, and closes with a recap.
Comment bait ("what would you do?", polls) is spread through every week,
because comments are what both algorithms reward most.

| Week | Theme | Goal |
|---|---|---|
| 1 · 16–22 Nov | **Encore launch**: "Every job. Its own game." | Announce it, get reach with the two strongest videos |
| 2 · 23–29 Nov | **Career spotlights I**: actor, doctor, lawyer, pilot, politician | One career a day, each its own colour, comment questions |
| 3 · 30 Nov–6 Dec | **Career spotlights II + a long life**: musician, model, athlete, armed forces, vet, hustler; pins and turning points | Finish the careers, open the second theme |
| 4 · 7–13 Dec | **A long life + recap**: the paper, back issues, what's new | Saves and shares; end on the round-up |

### Day by day

| Date | Instagram (feed 6:00 pm · Reel 7:00 pm) | Instagram story | TikTok (7:30 pm weekdays · 12:30 pm weekends) |
|---|---|---|---|
| **Mon 16 Nov** | Feed: `01_every_job_its_own_game.jpg` | `story_3_encore.jpg` (link sticker) | `reel_1_every_job.mp4` |
| Tue 17 Nov | Reel: `reel_1_every_job.mp4` | | Photo post: `carousel_a_01–13.jpg` |
| Wed 18 Nov | Carousel: `carousel_a_01–13.jpg` | ★ `story_1_hold_or_rip.jpg` (poll) | `reel_2_cold_read.mp4` |
| Thu 19 Nov | Feed: `02_coldread.jpg` | | |
| Fri 20 Nov | Reel: `reel_2_cold_read.mp4` | | `reel_3_triage.mp4` |
| Sat 21 Nov | Feed: `03_triage.jpg` | | |
| Sun 22 Nov | | ★ `story_2_pass_or_shoot.jpg` (poll) | `reel_6_which_are_you.mp4` |
| **Mon 23 Nov** | Reel: `reel_3_triage.mp4` | | `reel_4_objection.mp4` |
| Tue 24 Nov | Feed: `05_objection.jpg` | | |
| Wed 25 Nov | Feed: `04_crosswind.jpg` | `story_6_runway.jpg` | Photo post: `02_coldread.jpg` + `03_triage.jpg` + `05_objection.jpg` |
| Thu 26 Nov | Reel: `reel_4_objection.mp4` | | |
| Fri 27 Nov | Feed: `06_debate.jpg` | | Photo post: `04_crosswind.jpg` + `06_debate.jpg` |
| Sat 28 Nov | Reel: `reel_6_which_are_you.mp4` | | `reel_1_every_job.mp4` *(re-post with a new caption: the hook still works on new viewers)* |
| Sun 29 Nov | | | |
| **Mon 30 Nov** | Feed: `07_soundcheck.jpg` | | Photo post: `07_soundcheck.jpg` + `08_runway.jpg` + `09_matchday.jpg` |
| Tue 1 Dec | Feed: `08_runway.jpg` | | |
| Wed 2 Dec | Feed: `09_matchday.jpg` | | `reel_5_long_life.mp4` |
| Thu 3 Dec | Reel: `reel_5_long_life.mp4` | `story_5_pinned.jpg` (link sticker) | |
| Fri 4 Dec | Feed: `10_obstacle.jpg` | | Photo post: `10_obstacle.jpg` + `11_diagnose.jpg` + `12_pitch.jpg` |
| Sat 5 Dec | Feed: `13_pinned.jpg` | | |
| Sun 6 Dec | Feed: `11_diagnose.jpg` | | Photo post: `13_pinned.jpg` + `14_turning_points.jpg` |
| **Mon 7 Dec** | Feed: `12_pitch.jpg` | | |
| Tue 8 Dec | Feed: `14_turning_points.jpg` | | Photo post: `carousel_b_01–06.jpg` |
| Wed 9 Dec | Carousel: `carousel_b_01–06.jpg` | ★ `story_4_born_year.jpg` (question sticker) | |
| Thu 10 Dec | Feed: `15_back_issue.jpg` | | Photo post: `15_back_issue.jpg` + `16_front_page.jpg` |
| Fri 11 Dec | Feed: `16_front_page.jpg` | | |
| Sat 12 Dec | | | `reel_6_which_are_you.mp4` *(re-post, new caption)* |
| Sun 13 Dec | Feed: `17_whats_new.jpg` | `story_3_encore.jpg` (re-run, link sticker) | Photo post: `17_whats_new.jpg` |

**Totals:** Instagram 25 feed posts and Reels plus 7 stories; TikTok 17
posts (6 videos, 2 re-posts and 9 photo posts). That's about 6 a week on
Instagram and 4 on TikTok, inside the 3–5+ a week the go-to-market plan
targets, and no look runs two days in a row.

**Every week:** reply to every comment in the first hour (the "what would
you do?" posts are built for it), pin the best comment, and reshare any
player's post to stories. On Fridays, note which post did best and make
sure the next week has more like it.

### What to measure

Check each app's insights every Sunday; the numbers that matter here are
the ones the go-to-market plan already tracks:
- **Reach per Reel/TikTok**: are new people seeing it? (the video hooks)
- **Comments per post**: did the question land? (the "what would you do" posts)
- **Saves and shares**: the carousels and the long-life posts are built for these.
- **Profile visits → link taps**: is anyone going to play?
- **Followers**: toward 5K across platforms by T-6 (10 Go-to-Market §2).

---

## Feed posts

### 01_every_job_its_own_game.jpg · NEW UPDATE · ENCORE
**Caption:** Every job. Its own game. 🎭🩺✈️
11 careers just got a mini-game of their own: actors do a cold read, doctors triage the night's arrivals, pilots land in a crosswind. Every job plays like the job.
Which one are you trying first? 👇
**Alt text:** Three phones showing Relivable's new mini-games: an actor's cold read, a doctor's triage and a pilot's crosswind landing.

### 02_coldread.jpg · MARQUEE · COLD READ
**Caption:** "I'm fine. Really." 🎭
She has just lost the case. She is not fine. Read the note under the line, then pick the delivery: hold it back, play it straight, or let it rip.
How would you play it?
**Alt text:** A phone showing the actor's cold-read game: the line "I'm fine. Really." with buttons Hold it back, Play it straight and Let it rip.

### 03_triage.jpg · NIGHT SHIFT · TRIAGE
**Caption:** Man, 65. Fell, hip pain, cannot stand. 🩺
Resus, majors or minors? Doctors now triage every arrival on the night shift. Under-triage costs most, and it gets faster.
Where are you sending him? Comment RESUS, MAJORS or MINORS.
**Alt text:** A phone showing the triage game: an arrival card reading "Man, 65 · Fell, hip pain, cannot stand" and buttons Resus, Majors and Minors.

### 04_crosswind.jpg · FLIGHT DECK · CROSSWIND
**Caption:** Crab. Flare. Land. ✈️
Every seat in the cockpit needs a check ride now: a crosswind landing you fly yourself. Hold into the gusts, keep her on the centreline, flare low.
Ever landed one for real? 👀
**Alt text:** A phone showing the crosswind landing game: a runway, the aircraft drifting off the centreline, and Steer left / Steer right buttons.

### 05_objection.jpg · MAHOGANY · CROSS-EXAM
**Caption:** Objection. ⚖️
"I was standing at the corner shop." Your notes say the café. Lawyers now cross-examine witnesses: object to what doesn't square with your notes, and to hearsay.
Let it stand or object?
**Alt text:** A phone showing the cross-examination game: the witness's line, the lawyer's notes, and buttons Let it stand and Objection!

### 06_debate.jpg · CHAMBER · THE DEBATE
**Caption:** Read the room. 🏛️
Politicians now debate live: pick the rebuttal the room wants to hear: the facts, a real story, hit back, or agree then pivot. Approval fills the seats.
What's your move?
**Alt text:** A phone showing the debate game: an opponent's line "We all want safer streets" and four rebuttal buttons.

### 07_soundcheck.jpg · BACKSTAGE · SOUNDCHECK
**Caption:** Ride the faders. 🎸
Doors are open and the room is filling up. Musicians now run their own soundcheck: vocals, guitar, bass and drums, and a needle you want in the red.
**Alt text:** A phone showing the soundcheck game: four faders for vocals, guitar, bass and drums.

### 08_runway.jpg · RUNWAY · THE WALK
**Caption:** Turn. Pose. Walk. 📸
Models now walk the runway: turn to the press pit when someone shouts, then pose to the brief.
Playful or fierce? 👇
**Alt text:** A phone showing the runway game: the catwalk, a note that the press pit is on the left, and Turn left, Hold centre and Turn right buttons.

### 09_matchday.jpg · FLOODLIGHTS · MATCH DAY
**Caption:** Pass or shoot? ⚽
You have the ball. Centre is open, the rest are marked. Athletes now play match day: find the open teammate, or take it yourself.
**Alt text:** A phone showing the match-day game: a pitch from above, and Pass left, Pass centre, Pass right and Shoot buttons.

### 10_obstacle.jpg · FIELD KIT · OBSTACLES
**Caption:** Wall. Wire. Water. 🪖
The armed forces obstacle course: the right move for every obstacle, faster as you tire. A 2-metre wall, smooth, no footholds. What do you do?
**Alt text:** A phone showing the obstacle course game: a 2-metre wall ahead and a choice of moves.

### 11_diagnose.jpg · MEADOW · DIAGNOSE
**Caption:** Two signs. One cause. 🐑
Vets now diagnose in the clinic: match two signs to their cause, with the handbook open.
**Alt text:** A phone showing the vet's diagnose game: symptoms to match with their cause.

### 12_pitch.jpg · MARKET DAY · THE PITCH
**Caption:** Not while he's looking. 🎪
Street hustlers now work the pitch: call out to people who are looking, never while an officer passes.
**Alt text:** A phone showing the street pitch game: a crowd passing a stall, with the rush-hour and crowd meters.

### 13_pinned.jpg · LIFE HUB · NEW
**Caption:** You haven't seen your dad in 19 years. 📌
Pin anyone in your life and the Life feed keeps track: your bond, when you last saw them, their news, a round birthday coming up. In prison? Pin your release date and your next parole hearing.
Who would you pin first?
**Alt text:** A phone showing the Life feed with a Pinned section: Liam, father, bond 59%, last seen 19 years ago, and Selma, mother, last seen 7 years ago.

### 14_turning_points.jpg · LIFE HUB · TURNING POINTS
**Caption:** Every big moment. One place. ⭐
A new Life feed filter keeps every turning point from birth on: marrying, prison, your first flat, the box of family photographs. Nothing drops off.
**Alt text:** A phone showing the Turning points filter: a timeline of moments by age, from running a marathon at 33 to a new chapter at 40.

### 15_back_issue.jpg · THE PAPER · BACK ISSUES
**Caption:** Read any year's paper. 🗞️
The newspaper now keeps back issues: open any year's front page, search by year or by a word, even the years your ancestors lived.
**Alt text:** A phone showing a 2027 back issue of The Chicago Chronicle: "The Summer Games open with a record number of countries."

### 16_front_page.jpg · THE PAPER
**Caption:** Make the front page. 🗞️
Every year the world prints what happened, and what it means for you: jobs, house prices, taxes, crime. Sometimes the story is you.
**Alt text:** A phone showing today's Chicago Chronicle with "What this means for you": jobs, home values, a tax rebate, more police.

### 17_whats_new.jpg · WHAT'S NEW
**Caption:** What's new: 11 careers with their own mini-games, second acts when a career ends (coach, pundit, director, designer…), careers that reach into your life, a youth unit and restorative justice in prison, and pins, turning points and back issues to keep track of a long life.
Free on Android, iPhone, Windows and the web. Link in bio.
**Alt text:** A list of the update's features, each in its career's colours.

## Carousels

### carousel_a_01–13.jpg · "11 careers. 11 new games ›"
**Caption:** Swipe through 11 new games ›
Every career plays like the job now. Which one is yours? 👇
**Alt text (per slide):** 1: "11 careers. 11 new games." 2–12: one career's mini-game each: cold read, triage, crosswind landing, cross-examination, debate, soundcheck, runway, match day, obstacle course, diagnose, the pitch. 13: "Which game is yours?" with a play-free button.

### carousel_b_01–06.jpg · "Keeping track of a long life ›"
**Caption:** Eighty years, eight generations. Here's how you keep track ›
Pin who matters, filter the big moments, and read any year's paper. Save this for your next long life. 📌
**Alt text (per slide):** 1: "Keeping track of a long life." 2: pinned people. 3: the Turning points filter. 4: a back issue of the paper. 5: today's paper. 6: "One life. Every year of it." with a play-free button.

## Stories

- **story_1_hold_or_rip.jpg** ★: add a **poll sticker** over the "OR" circle: *Actor* / *Doctor*.
- **story_2_pass_or_shoot.jpg** ★: **poll sticker** over "OR": *Athlete* / *Lawyer*.
- **story_3_encore.jpg**: **link sticker** over the "Play free" button.
- **story_4_born_year.jpg** ★: **question sticker** under the headline: "What year were you born?" Reply to the best answers with the headline the game printed that year.
- **story_5_pinned.jpg**: **link sticker** over the button.
- **story_6_runway.jpg**: add an **emoji slider** 🔥 over the empty space at the top.

## Videos (Instagram Reels and TikTok)

Same file on both apps; use the TikTok caption on TikTok (shorter, with
TikTok-native tags). Turn on TikTok's auto-captions. Choose "Allow duets
and stitches": the "what would you do" videos are made to be stitched.

### reel_1_every_job.mp4 (9 s)
**Instagram:** Every job. Its own game. 11 careers, 11 new mini-games. Which one are you? 👇 #lifesim #indiegame #mobilegame #newupdate #choicesmatter
**TikTok:** every job has its own game now 😭 which one are you #lifesim #indiegame #gaming #mobilegame #fyp
**TikTok re-post (28 Nov):** pick a job, play the job 🎭🩺✈️⚖️ #lifesim #indiegame #fyp

### reel_2_cold_read.mp4 (6.5 s)
**Instagram:** "I'm fine. Really." She just lost the case. How do you play it: hold it back, play it straight, or let it rip? 🎭
**TikTok:** how would YOU deliver this line 🎭 #acting #lifesim #indiegame #fyp

### reel_3_triage.mp4 (6.5 s)
**Instagram:** Man, 65. Fell, can't stand. Resus, majors or minors? Comment your call 🩺
**TikTok:** you're the doctor. where does he go? 🩺 #nurse #doctor #lifesim #indiegame #fyp

### reel_4_objection.mp4 (6.5 s)
**Instagram:** "I was at the corner shop." Your notes say otherwise. Object or let it go? ⚖️
**TikTok:** objection or let it slide? ⚖️ #lawyer #lifesim #indiegame #fyp

### reel_5_long_life.mp4 (7 s)
**Instagram:** You haven't seen your dad in 19 years. Pin the people who matter, keep every turning point, read any year's paper. 📌
**TikTok:** the game remembered i hadn't called my dad in 19 years 💀 #lifesim #indiegame #gaming #fyp

### reel_6_which_are_you.mp4 (6 s)
**Instagram:** Screenshot to pick your job. Which one did you get? 👇
**TikTok:** screenshot to pick your career 📸 comment what you got #lifesim #screenshotgame #indiegame #fyp
**TikTok re-post (12 Dec):** stop the scroll on your job 👀 #lifesim #fyp

**Shared hashtags** for Instagram (pick 5–8): `#lifesim #lifesimulator #indiegame #mobilegame #indiedev #careers #choicesmatter #simulationgame #newupdate #gamedev`
