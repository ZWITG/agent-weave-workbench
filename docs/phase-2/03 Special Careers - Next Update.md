---
title: "03 Special Careers - Next Update"
project: Relivable
phase: 2
status: wave 1 in progress (13 Nov 2026); defaults taken for D3–D5, D1–D2 open
updated: 2026-11-13
tags: [relivable, phase-2, careers, special-careers, themes, plan]
---

# 03 Special Careers: Next Update ("Calling")

*Purpose:* list every special career BitLife has, compare it with what
Relivable has today and with what players ask for, then plan one update
built around special careers: their looks (themes), their activities and
upgrades to the menus around them.

## 1. What Relivable has today

Special careers are flagged `special: true` in `engine/careers.dart`. The
police career is not flagged, but it has the deepest system of all
(`engine/policing.dart`), so it is counted here. Since 13 Nov every one of
them has its own look (`theme.dart` `careerLooks`) and the Curtain moment
when you start (`ui/career_curtain.dart`).

| Career | Ladder | Entry rule | Signature mechanic today (`jobs.dart` `_specialYear`) | Look |
|---|---|---|---|---|
| Actor | Extra → Movie star (5) | Drama at school, or Charisma 60 and Looks 55 | Audition scene 35% a year (3 choices); big break 3–8% | Marquee |
| Musician | Busker → Touring headliner (4) | Creativity 55 and lessons, a band or a choir | Big break only. **The music system (`music.dart`: songs, albums, labels, gigs, tours) is a hobby and does not know about the career** | Backstage |
| Athlete | Amateur → All-star (4) | Athleticism 70 and a school team season | Injury 8%, retirement from 35, big break | Floodlights |
| Model | Catalogue → Supermodel (4) | Looks 70 | Bookings dry up after 35; big break | Runway |
| Politician | Council member → Head of government (4) | Charisma 55, no arrest | Election every 4 years (campaign hard or clean); records now cost votes | Chamber |
| Armed forces | Private → Colonel (5) | Health 60, Athleticism 50 | Deployment 25% (front line or support) | Field Kit |
| Lawyer / judge | Associate → Judge (4) | Law degree and the bar | Big case 30% (fight or settle); defends themselves in court | Mahogany |
| Doctor | Resident → Chief of medicine (4) | Medicine degree | Hospital case 30% (more tests or treat) | Night Shift |
| Pilot | First officer → Chief pilot (4) | Flight school licence | **Nothing** | Flight Deck |
| Vet | Junior vet → Practice owner (4) | Veterinary degree | **Nothing** | Meadow |
| Street hustler | Busker → Street legend (4) | None, from 14 | Random yearly income | Market Day |
| Police | Cadet → Police chief (5) | School, clean record | Academy mini-games, casework on the crime evidence scale, bribes, Internal Affairs, undercover, own cases, badge card | Blue Line |

Around them:
- **Fame** (`celebrity.dart`, `social.dart`): special careers above the first
  step raise fame; awards name your job; brand deals, paparazzi, scandals.
- **Menus:** Path › Career shows status, the ladder, the job board and (for
  police only) a badge card. Activities › Work has 10 generic actions (work
  harder, slack off, ask for a raise, freelance...). **No special career
  has its own activities or its own screen.** Crime has Back Alley, prison
  has the Yard and the upper echelon has the Echelon screen; careers have
  nothing comparable.
- **Looks:** palettes and the Curtain only. Unlike Yard Time (stencils,
  chalk, the Yard map) and Gilded (the molten seam, Playfair), the career
  looks have no decals, type or motifs yet.

**In one line:** police is a game, the other eleven are a ladder with one
yearly pop-up, and two of them (pilot, vet) have not even that.

## 2. BitLife's special careers

> [!warning] Limits
> Guide pages could not be opened from this session (network settings);
> this uses search-result summaries from fan guides (Prima Games, Pro Game
> Guides, Destructoid, Twinfinite and others) plus the repo's earlier
> research (`research_notes/BitLife complete feature guide/careers_money_crime.md`).
> Guides disagree on prices and some details; nothing here is official.

BitLife keeps special careers under Occupation › Special Careers. Almost all
are **paid job packs** (about $2–7 each) or come with Boss Mode.

| BitLife career | What it is (as reported) | Relivable |
|---|---|---|
| **Actor** | Looks matter; hire an agent, audition for TV and film roles, fame and award nominations; a "Movie Star" update | Actor with auditions; **no agent, no roles or projects, no award season of its own** |
| **Musician** | Solo or band; audition for a record label; albums, concerts, world tours; genres favour different album types; popularity fades without releases or tours | Musician career **plus** a separate music hobby with songs, labels and tours: **the two are not connected** |
| **Athlete** | Pick a sport (baseball, soccer and others); school → college → pros; a soccer "World BitCup" challenge | Athlete with injuries and retirement; **no sport, no league, no contracts, no matches** |
| **Model** | Tiers from body-part model to supermodel; modelling lessons, headshots, auditions | Model; **no castings, portfolio or agency** |
| **Politician** | School board → mayor → governor → president (35+, US); self-funded campaigns; approval rating moved by bills, speeches, rallies; a Political Expansion Pack (2025) | Politician with elections; **no approval rating, bills or office actions** |
| **Astronaut** | STEM degree, pilot licence, Space Academy; missions (spacewalk, lunar exploration, Mars), research and fame; ranks up to general | **Not in the game** |
| **Street Hustler** | Busker, street performer, scam artist, panhandler; choose a street by police presence, footfall and crime level | Street hustler (legal only, no street choice) |
| **Mafia** | Six families, ranks to Godfather, extortion | Crews (`underworld.dart`) |
| **Business** | Found or take over a company as CEO | Businesses (`business_kinds.dart`, `economy.dart`), not a career |
| **Dealer** | Drug dealing (unverified detail) | Not in the game (owner decision D1 in the Crime plan) |
| **Secret Agent** | Recruit and train agents, gadgets, missions, an infiltration puzzle | Police undercover is the nearest thing |
| **Ultimate Fighter** (2026) | League and street fights, Street Cred, a skill shop of moves, stamina, a fighting mini-game | **Not in the game** |
| Royalty | By birth, not a career | Not in the game |
| Regular "special" jobs | Military, police, doctor, lawyer/judge and pilot appear to be ordinary jobs in BitLife | **Relivable treats these as special: we are ahead here** |

What BitLife does that we do not: each career has **its own menu** (agent,
auditions, label, league, missions), **its own resource** (Street Cred,
approval rating, popularity) and often **its own mini-game** (fighting,
infiltration). What it gets criticised for: **paywalls** and careers that
feel **repetitive** once you are in them.

## 3. What players want

Sources: search summaries of player comments and reviews (a third-party
review aggregator, App Store pages) and the Phase 1 research
(`docs/phase-1/03 Player Research and Wishlist.md`,
`research_notes/Life sim game phase 1/reddit_player_wishlist.md`). Reddit
was not reachable. Directional, not a vote count.

1. **Jobs get boring and repetitive.** The most direct complaint: once you
   have the job, the same few pop-ups repeat.
2. **Deeper music:** editing, collaborating and producing.
3. **New special careers:** a boxing or fighting career, a superhero or
   villain path, a supreme court role, and (Phase 1) a police academy,
   which is now built.
4. **"Cutscenes" to make it feel more alive.** Relivable's Lockdown,
   Molten and the Curtain are this.
5. **No paywalls** (the number-two complaint in the genre). Every special
   career stays free here.
6. **Clear unlock paths.** Many guides exist only to explain how to get
   into a career (agents, labels, academies). Show the path in the game.
7. **Choices that matter, with visible odds** (Crime plan, section 3).

**What follows for us:** depth inside each career beats more careers.
Every special career needs things to *do* (a menu of its own), a resource
that moves because of what you did, and a moment or two you play rather
than read.

## 4. Options, scored

Scored 1–5 for player value (V), how much it closes a BitLife gap (G) and
effort (E, 5 = smallest).

| # | Option | V | G | E | Notes |
|---|---|---|---|---|---|
| 1 | **Career Hub:** one shared screen and data shape that gives every special career a signature meter, a menu of activities, a season calendar and a moment | 5 | 5 | 3 | The core of the update; turns 11 thin careers into games without 11 bespoke engines |
| 2 | **Deepen the 11 careers** on the Hub (section 6.2) | 5 | 5 | 2 | The big writing job; can ship in two waves |
| 3 | **Look upgrades:** a motif decal, a type accent and a stamped result card for every look | 4 | 2 | 4 | Builds on the career looks just shipped |
| 4 | **Menu upgrades:** a Special careers tab on the job board with unlock checklists, a career category at the top of Activities, promotion and retirement moments | 4 | 3 | 4 | Answers "how do I get in?" |
| 5 | **Connect music:** the musician career runs on the music system (signed artist = label deal) | 4 | 3 | 4 | Fixes a real disconnect; players asked for deeper music |
| 6 | **New: Astronaut** ("Orbit" look) | 4 | 4 | 3 | Clear BitLife gap; missions fit the Hub |
| 7 | **New: Fighter** ("Fight Night" look) | 4 | 4 | 3 | Asked for (boxing) and new in BitLife; needs a fight mini-game |
| 8 | **New: Secret agent** | 3 | 3 | 3 | Overlaps police undercover; later |
| 9 | **New: Director, chef, firefighter** | 3 | 2 | 3 | Nice; less asked for |

## 5. Decisions only the owner can make

| # | Decision | Why it matters |
|---|---|---|
| D1 | **Which new careers, if any, ride with this update?** Recommendation: Astronaut and Fighter in wave 2, the rest later | Each one is about a session of writing plus a look and a mini-game |
| D2 | **Street hustler: allow scams?** BitLife's Street Hustler includes a scam artist. Today the career says "legal hustles only". If yes, scams use the crime system (evidence, cases, heat) | Ties into the age rating like the Crime plan's D1 |
| D3 | **Career look vs Gilded.** Today Gilded wins (a rich actor sees gold). Options: keep it, career wins, or a Settings choice | A famous rich performer is common |
| D4 | **Real sports?** Recommendation: fictional leagues ("the Summer Games" style from the 1.0 legal pass), generic sports (football, basketball, tennis, boxing) | Avoids league trademarks |
| D5 | **Musician: one system.** Recommendation: merge the career into `music.dart` so the hobby and the career share songs, labels and tours | Changes how the existing music hobby feels |

## 6. Recommended update: "Calling"

Options 1–5 as the core (wave 1 and wave 2), options 6–7 if D1 says yes.

### 6.1 The Career Hub (shared framework)

One engine shape and one screen, filled with data per career, the way the
crime list and the Yard map work.

| Piece | What it is | Example (Actor) |
|---|---|---|
| **Signature meter** (0–100) | The career's own resource, moved by what you do, shown on the Hub and in the header strip | *Buzz*: auditions, roles, reviews and press move it; it drifts down in quiet years |
| **Activities** (4–6, energy-limited) | Career-only actions in the career's look, each showing its odds and what helps | Audition, take a class, network at a party, read scripts, press tour, hire or fire your agent |
| **Season calendar** | The career's year in 3–4 beats, shown as a strip; each beat queues a scene | Pilot season → shoot → release and reviews → awards |
| **A played moment** | One original mini-game per career, with Skip at 0.6 and a turn-based version (the existing mini-game rules) | *Cold read*: lines scroll, tap on the beat |
| **Contacts** | 2–3 career NPCs with bond (`relationships.dart`) | Agent, a rival actor, a director who likes you |
| **Ladder rules** | Promotion from the meter and milestones, shown on the ladder like police ranks | Lead actor needs Buzz 60 and a released film |
| **Exit** | A retirement or pivot scene with a legacy line for the Life Recap | Character actor, director, drama teacher |

Code: `engine/career_hub.dart` (the shape, the year, meter maths) and one
data file per career (`engine/careers/actor.dart`...), reusing
`Storylet`/`Choice` scenes. UI: `ui/career_hub_screen.dart` (like
`echelon_screen.dart`), opened from Path › Career and the Activities
category.

### 6.2 Each career on the Hub

All mini-games are original designs; names below are working titles.

| Career | Meter | Activities (beyond Work's) | Season | Played moment | Links to the rest of the game |
|---|---|---|---|---|---|
| **Actor** · Marquee | Buzz | Audition, class, network, read scripts, press tour, agent | Pilot season, shoot, release, awards | Cold read (rhythm of lines) | Fame and image; awards (`celebrity.dart`); paparazzi; co-star romance (`love.dart`) |
| **Musician** · Backstage | Following | Write, record, release, gig, tour, collaborate, produce for others | Write, record, release, tour | Soundcheck (match levels on a mixing desk) | **Runs on `music.dart`** (D5); band members as NPCs; label deals; producing (player ask) |
| **Athlete** · Floodlights | Form | Train, rest, film study, sign a sponsor, talk to the press, ask for a transfer | Pre-season, season (results table), play-offs, off-season contract | Match day (reaction and timing, one per sport) | Injuries (`health.dart`); doping uses the crime evidence scale; team ownership (`elite.dart`); coaching or punditry after |
| **Model** · Runway | Portfolio | Castings, test shoots, fashion week, brand campaigns, diet and gym | Castings, shows, campaigns | Walk (pace and turn timing on a runway) | Brand deals (`social.dart`); age curve kept; pivot to designer or agency owner |
| **Politician** · Chamber | Approval | Speech, rally, vote on a bill, constituency surgery, fundraise, form a coalition | Session, budget, scandal season, election | Debate (pick the rebuttal against a clock) | Bills come from world events (`world.dart`); records and scandals (`career_law.dart`); head of government ties into Echelon influence |
| **Armed forces** · Field Kit | Readiness | Drill, courses, leave, volunteer for a mission, mentor recruits | Training, deployment, leave | Obstacle course (timing and stamina) | The draft (`country_life.dart`); medals; injuries and veteran care (`health.dart`) |
| **Lawyer / judge** · Mahogany | Reputation | Take a case (defence, prosecution, civil), research, settle, court a client, run for judge | Caseload, trial, appeals | Objection (spot the flaw in testimony) | **Defend people you know** who are arrested; judges hear cases from the crime list; lawsuits (`heists.dart`) |
| **Doctor** · Night Shift | Ward trust | Shifts, specialise, research, teach, volunteer abroad | Rotations, a crisis winter, review | Triage (order patients by signs) | Treat people you know (`health.dart`); malpractice through lawsuits |
| **Pilot** · Flight Deck | Flight hours | Pick routes (short-haul, long-haul, cargo), simulator check, union, staff travel | Rosters, check ride, peak season | Crosswind landing | Travel (`world_data.dart`) at staff prices; incidents and investigations |
| **Vet** · Meadow | Practice standing | Clinic shifts, farm calls, emergency nights, open a practice | Spring lambing, summer, winter | Diagnose (match signs to cause) | **Your own pets** (`pets.dart`); the practice as a business (`business_kinds.dart`) |
| **Street hustler** · Market Day | Street rep | Pick a street (footfall, police, competition), busk, sell, perform, (scams if D2) | Market days, festival season, winter | Pitch (draw a crowd: timing) | Scams on the crime scale if D2; licences and fines; crews notice a good corner |
| **Police** · Blue Line | Closed cases | Already deep: move academy, casework, bribes and undercover onto the Hub screen | Already built | Already built (academy, Getaway) | Already built |
| *Astronaut* · *Orbit* (D1) | Mission readiness | Space academy tests, simulator, research, public outreach | Selection, training, mission, return | Docking (thrust and alignment) | Pilot licence and a STEM degree (`school.dart`); Echelon moonshots |
| *Fighter* · *Fight Night* (D1) | Street cred / ranking | Train, spar, cut weight, promote a fight, street fight | Camp, weigh-in, fight night, recovery | Fight (stamina, guard and strike timing) | Health and injuries; gambling; crews may fix fights (crime) |

### 6.3 Looks, deepened

Each look gets the same three things Yard Time and Gilded already have:

| Look | Motif decal (top of screen, like Gilded's seam) | Type accent (existing fonts) | Stamp on results |
|---|---|---|---|
| Marquee | A row of bulbs that chase slowly | Playfair Display | "CUT", "THAT'S A WRAP" |
| Backstage | VU meters that bounce with the result | Sora heavy | "SOLD OUT", "ENCORE" |
| Floodlights | A scoreboard strip with the season record | Stencil numbers | "FULL TIME", "INJURED" |
| Runway | Camera flashes along the edge | Playfair Display italic | "BOOKED", "ON THE COVER" |
| Chamber | A ballot ribbon and the approval number | Playfair Display | "PASSED", "DEFEATED" |
| Field Kit | Stencilled dog tags | Stardos Stencil | "MISSION COMPLETE", "MEDAL" |
| Mahogany | A wood-grain band and a gavel tap | Playfair Display | "SUSTAINED", "OVERRULED", "NOT GUILTY" |
| Night Shift | A heartbeat line that keeps time | Sora | "STABLE", "CODE BLUE" |
| Flight Deck | An artificial horizon that tilts with luck | Sora mono-style numbers | "LANDED", "DIVERTED" |
| Meadow | A hedgerow with a sun that tracks the season | Caveat | "ALL WELL", "CALLED OUT" |
| Market Day | A chalked price board | Caveat | "SOLD", "MOVED ON" |
| Blue Line | A light bar that flashes red and blue | Stardos Stencil | "CASE CLOSED", "NO FURTHER ACTION" |

Moments: the Curtain (built) on starting; a short **Curtain Call** on
promotion (the title card again, with the new rank); a **Final Bow** on
retirement that fades the look out. Reduce motion turns all three into a
fade; Settings › Career looks turns everything off.

### 6.4 Menu upgrades

| Where | Today | After |
|---|---|---|
| **Path › Career** | Status, ladder, job board; a badge card for police only | A **Hub card** for every special career: look swatch, meter, the season strip, the next step, "Open hub" |
| **Job board** | One list with filters | A **Special careers** tab: each career with its look as a preview, an **unlock checklist** (degree ✓, Looks 70 ✗, school team season ✓), a progress bar and "how to get there" |
| **Activities** | Work has 10 generic actions | The career's category at the top, in its look, grouped by place (like the Crime page): e.g. Chamber: *The floor · Your seat · The campaign · The press* |
| **Header** | Money and age | The signature meter as a small chip next to money while you work in a special career |
| **Results** | Plain or crime stamps | The look's stamp (6.3) |
| **Life Recap** | Career line | A career page: roles, albums, seasons, cases or bills, with the look as its card |

### 6.5 Work plan

| Step | Work | Done when |
|---|---|---|
| 1 | `career_hub.dart` and the Hub screen; police moved onto it as the reference | Police plays the same as today from the Hub; tests pass; render checks at 320×568 |
| 2 | Menu upgrades (6.4): Path Hub cards, the job board's Special careers tab with unlock checklists, Activities career category, header chip | Every special career shows its path and its Hub; fits small phones with large text |
| 3 | Wave 1 careers: Actor, Musician (on `music.dart`, D5), Athlete, Politician | Meter, activities, season, contacts and a mini-game each; fuzz runs show no stuck states |
| 4 | Look upgrades (6.3) and the Curtain Call / Final Bow | Render checks for all looks; Reduce motion versions |
| 5 | Wave 2 careers: Model, Armed forces, Lawyer/judge, Doctor, Pilot, Vet, Street hustler | Same bar as wave 1; pilot and vet no longer empty |
| 6 | Astronaut and Fighter (if D1) with their looks | Same bar, plus job-board entries and unlock paths |
| 7 | Full test run, release fuzz, changelog, ship | All tests pass; screenshots reviewed |

Rough size: larger than the Echelon update. Wave 1 (steps 1–4) is about
5–7 working sessions; wave 2 about the same again; each new career about
one more.

### 6.6 Progress

Built 13 Nov 2026 (`engine/career_hub.dart`, `ui/career_hub_screen.dart`),
with the recommended defaults for D3 (Gilded still wins), D4 (fictional
league) and D5 (the musician career runs on `music.dart`):

| Step | State |
|---|---|
| 1 Hub framework and screen, police on it | **Done** |
| 2 Menu upgrades | **Done:** Hub cards on Path, the Career category in Activities, the way-in checklists. **Not yet:** the meter chip in the header |
| 3 Wave 1 careers | **Done:** actor, musician, athlete, politician (meters, activities, seasons, scenes). **Not yet:** contacts as NPCs; career mini-games reuse existing game engines with career wording (rhythm, memory, whack, reps, timing, breath, reaction), not new designs |
| 4 Look upgrades | **Partly:** motifs on the Hub, the Curtain Call on promotion. **Not yet:** stamps, type accents, the Final Bow, motifs outside the Hub |
| 5–7 | Not started |

### 6.6 Rules carried over

- Every choice and mini-game shows its odds and what helps; Skip resolves
  at 0.6; screen readers and Reduce motion get turn-based versions.
- Prison pauses the Hub (as it pauses outside life); a conviction ends the
  careers in `career_law.dart` and plays the Final Bow before Lockdown.
- All special careers stay free.
- Original designs only: genre mechanics yes, no copies of BitLife's
  screens, names or mini-games.

## 7. Sources

- Repo research: `research_notes/BitLife complete feature guide/careers_money_crime.md`, `premium_packs_challenges.md`; `docs/phase-1/03 Player Research and Wishlist.md`; `research_notes/Life sim game phase 1/reddit_player_wishlist.md`; `docs/phase-2/02 Crime - Next Step.md`
- Careers and packs: [Careers/Occupation (Fandom wiki)](https://bitlife-life-simulator.fandom.com/wiki/Careers/Occupation), [Attack of the Fanboy: unlock special careers](https://attackofthefanboy.com/guides/how-to-unlock-special-careers-in-bitlife/), [Game Rant: best careers](https://gamerant.com/bitlife-best-jobs-paying-careers/)
- Actor: [Pro Game Guides](https://progameguides.com/bitlife/how-to-become-an-actor-movie-star-in-bitlife/), [Charlie Intel](https://charlieintel.com/how-to-become-an-actor-or-movie-star-in-bitlife/201379), [Prima Games: Rising Star](https://primagames.com/tips/how-to-complete-the-rising-star-challenge-in-bitlife)
- Musician: [Destructoid](https://www.destructoid.com/how-to-become-a-musician-in-bitlife/), [Gamer Journalist](https://gamerjournalist.com/how-to-become-a-famous-singer-in-bitlife/), [DoubleXP: genres](https://doublexp.com/guides/all-musical-genres-you-can-play-as-a-famous-musician-in-bitlife)
- Athlete: [Destructoid: baseball](https://www.destructoid.com/how-to-become-a-baseball-player-in-bitlife/)
- Astronaut: [Prima Games](https://primagames.com/tips/how-to-become-an-astronaut-in-bitlife), [Prima Games: Mars](https://primagames.com/tips/how-to-go-to-mars-in-bitlife), [Pro Game Guides: lunar exploration](https://progameguides.com/bitlife/how-to-go-on-lunar-exploration-in-bitlife/), [Pro Game Guides: spacewalk](https://progameguides.com/bitlife/how-to-go-on-a-spacewalk-in-bitlife/)
- Model: [Pro Game Guides](https://progameguides.com/bitlife/how-to-become-a-model-in-bitlife/), [Prima Games: supermodel](https://primagames.com/?p=225177)
- Street Hustler: [Pro Game Guides](https://progameguides.com/bitlife/bitlife-street-hustler-update-everything-you-need-to-know/), [Prima Games](https://primagames.com/tips/how-to-become-a-street-hustler-in-bitlife)
- Politics: [Pro Game Guides: President](https://progameguides.com/bitlife/bitlife-how-to-become-president/), [Destructoid](https://www.destructoid.com/how-to-become-president-in-bitlife/), [Pro Game Guides: Politics update v1.35](https://progameguides.com/bitlife/bitlife-politics-update-patch-notes-v1-35/)
- Secret Agent: [Pro Game Guides](https://progameguides.com/bitlife/how-to-complete-secret-agent-missions-in-bitlife/), [GameSkinny](https://www.gameskinny.com/tips/how-become-secret-agent-bitlife/)
- Ultimate Fighter: [Pro Game Guides](https://progameguides.com/bitlife/complete-bitlife-ultimate-fighter-mode-guide-leagues-move-set-stamina-more/)
- Player feedback: [Game Solver: BitLife player comments](https://game-solver.com/bitlife-life-simulator/), [App Store listing](https://apps.apple.com/US/app/id1374403536)
