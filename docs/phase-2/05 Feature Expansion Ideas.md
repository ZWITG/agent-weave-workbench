---
title: "05 Feature Expansion Ideas"
project: Relivable
phase: 2
status: "E3, C2, E5, L1, P2, M2 and N2 built (14 Nov 2026); rest proposed"
updated: 2026-11-14
tags: [relivable, phase-2, roadmap, ideas]
---

# 05 Feature Expansion Ideas

*Purpose:* a pass over every shipped system, top to bottom through the app's
own navigation ([[05 UX and Screen Map]] §2–3: Life, People, Path, Wealth,
Me, then the cross-cutting systems), proposing one layer of depth for each
rather than a new tab or screen. Each idea says what it adds, what it
touches in the engine, and a rough size next to comparable finished work
([[02 Crime - Next Step]], [[03 Special Careers - Next Update]]) so it can
be picked up and scoped on its own. Nothing here is built yet; this is the
backlog this update plans from.

How to read it: **Adds** is the player-facing idea in one line. **Touches**
names the real files it would extend. **Size** is relative to a shipped
update of comparable scope. Pick items independently — none depends on
another being built first, except where noted.

## Life Hub

| # | Adds | Touches | Size |
|---|---|---|---|
| L1 | ~~**Pinned watchlist**~~ — **Built 14 Nov.** Pins live in `life.marks` (`pin:npc:<id>`, `pin:release`, `pin:parole`; no save change) via `engine/watchlist.dart`. A Pinned strip on the Life tab shows each pin's status; `watchYear` (called from `engine.ageUp`) adds a `watch` feed line when it comes due, and drops pins that no longer point at anything. The game has no dated trials or weddings to pin, so deadlines are prison release (with the next parole hearing) and parole's end | `engine/watchlist.dart`, `engine/engine.dart`, `ui/hub_screen.dart` (`_Pinned`), `ui/people.dart` (pin button) | — |
| L2 | **Reactive suggestion cards**: a suggestion card type driven by relationship decay ("You haven't seen your mom in 3 years") rather than only canned/contextual content | `engine/social.dart` (bond decay is already tracked), the suggestion-card generator in the hub | Small–medium |

## People

| # | Adds | Touches | Size |
|---|---|---|---|
| P1 | **Bond history chart**: a real bond-over-time chart on the relationship detail screen, not just a sparkline; tapping a dip jumps to the Timeline entry that caused it | `ui/` relationship detail screen, `engine/social.dart` (bond deltas would need a lightweight history log per relationship), `engine/lifespan.dart` (Timeline linking already exists for "◆ Remembered" markers) | Medium — needs a bounded history log per NPC, not just the current bond number |
| P2 | ~~**Notable ancestors filter**~~ — **Built 14 Nov.** `notableAncestor` (`dynasty.dart`): upper echelon or a Rare/Legendary title. `heirLife` now records `rarity` and `echelon` per ancestor; older records look rarity up by title name. A "Notable ancestors" toggle on `FamilyTree` (`ui/me_screens.dart`) highlights them and says why | `engine/dynasty.dart`, `ui/me_screens.dart` | — |
| P3 | **Standing annual parties**: a recurring party (an annual birthday bash) that auto-invites by bond threshold and resolves as a yearly outcome instead of rebuilding the guest list every time | wherever the party planner lives today (`ui/` + a scene in `engine/`), `engine/social.dart` for the auto-invite threshold | Small–medium |
| P4 | **Exotic pet breeding/shows**: a small side economy for exotic pets, feeding into Wealth the way vehicles already do | pet system (`engine/` pets), `engine/wealth` equivalents (`realty.dart`/`possessions.dart` pattern) | Medium |

## Path (education and career)

| # | Adds | Touches | Size |
|---|---|---|---|
| E1 | **Authored unlock paths**: school clubs/electives that lower a special career's entry bar (drama club → easier Actor entry) instead of only a flat stat gate | `engine/school.dart` (electives), `engine/careers.dart` (entry rules) | Small — mostly data: electives already exist, this wires them into entry-rule checks |
| E2 | **Mentor/protégé**: once senior in a career, take on a junior coworker; investing in them becomes an ally later, mirroring the Calling hubs' existing rival/ally pattern | `engine/jobs.dart`, `engine/career_hub_people.dart` (the existing cast/ally/rival pattern is the template) | Medium — reuses a proven pattern from the Calling update |
| E3 | ~~**Third acts**~~ — **Built 14 Nov.** `thirdActs` in `career_hub_second.dart`, keyed by second-act title; `leaveJob` (`jobs.dart`) queues it when a second-act job ends. One third act per second act, no fourth | `engine/career_hub_second.dart`, `engine/career_hub.dart` (dispatcher), `engine/jobs.dart` | — |
| E4 | **Franchise businesses**: multi-location businesses once a single business crosses a wealth threshold, with a manager-hire mechanic instead of micromanaging every site | business system (`engine/` business, wherever S33 lives) | Large — closest in shape to a new system, not an extension |
| E5 | ~~**Six more business industries**~~ — **Built 14 Nov.** Real estate agency, law firm, clinic, farm, car dealership, pet care, each with 3 perks, a signature move and 2 trade events (`business_kinds.dart`), registered in `industries` (`finance.dart`). The plan's list still has clinic/dental as a split, brewery, logistics, fashion label, beauty brand, security firm, travel agency, zoo, film studio, record label — same shape of work, pick up any time | `engine/business_kinds.dart`, `engine/finance.dart` | — |

## Wealth

| # | Adds | Touches | Size |
|---|---|---|---|
| W1 | **News-linked market cycles**: booms/crashes in investing tied to the newspaper's World section, so a headline actually moves the portfolio instead of running on independent RNG | `engine/world.dart` (newspaper/world events), investing (wherever S42 lives) | Medium — needs a shared event bus between the two systems, which don't talk today |
| W2 | **Short-term rental income**: a passive-income path for real estate distinct from flipping, with seasonal demand by city type | `engine/realty.dart` | Small–medium |
| W3 | **Echelon-hosted galas**: Echelon-tier homes can host the Echelon's own social events directly from the home screen | `engine/echelon.dart`, `ui/property_hub.dart` / home customisation | Small — mostly a new entry point into an existing Echelon event type |

## Me (stats, health, meta)

| # | Adds | Touches | Size |
|---|---|---|---|
| M1 | **Health ties into career stakes**: chronic conditions that interact with special careers directly — a pilot loses their medical, a boxer fails a pre-fight physical | `engine/health.dart`, `engine/career_hub*.dart` (per-career check, same shape as the existing doping/malpractice/investigation hooks from Calling: Encore) | Medium — one hook per affected career, reusing the Encore pattern |
| M2 | ~~**Timeline "turning points" filter**~~ — **Built 14 Nov.** There is no separate Timeline: the Life feed is it, and "◆ Remembered" is `life.flags`. `turningPoints` (`lifespan.dart`) merges milestone feed entries with every remembered moment for the whole life; it is the "Turning points" chip on the Life tab, uncapped (the other filters stop at 60 lines) | `engine/lifespan.dart`, `ui/hub_screen.dart` | — |
| M3 | **Per-career title tracks**: career-specific Life Titles ("The Champion", "The Auteur") alongside the universal ones, now that every special career has a Recap page | `engine/lifespan.dart` (titles), `engine/career_hub.dart` (Recap pages) | Medium — one title set per career, 13 careers |
| M4 | **Challenges seeded from shipped content**: weekly challenges built from real updates ("play the Calling: Encore update") to drive discovery post-launch | challenges hub (`engine/` or `ui/` wherever S59 lives) | Small — a content/ops task more than an engine task |
| M5 | **Dynasty family trade bonus**: a small, visible bonus for the next heir who picks a special career that 3+ prior generations worked | `engine/family.dart` / dynasty tracking, `engine/career_hub.dart` (entry rules, as a bonus not a requirement) | Small–medium |

## Crime, prison and the underworld

| # | Adds | Touches | Size |
|---|---|---|---|
| C1 | **Crews remember botched jobs**: a crew member burned by a failed heist refuses to work with you again, pushing toward recruiting new ones or repairing trust | `engine/heists.dart`, `engine/underworld.dart` (crew/loyalty state) | Small–medium — crew and loyalty state already exist; this adds a grudge flag per member |
| C2 | ~~**Parole persuasion beat**~~ — **Built 14 Nov.** A "Restorative justice meeting" prison course (adults only; youth units keep their own) opens a scene whose outcome sets `restorativeBonus`/`restorativeReason`, read by the parole hearing's chance and shown reasons alongside behaviour, programmes and family support | `engine/prison_life.dart` (course + scene), `engine/justice.dart` (parole case), `engine/scenes.dart` (dispatch) | — |
| C3 | **Going-legit arc**: a retirement path for career criminals, where an old heat level keeps haunting background checks for years after you stop | `engine/underworld.dart` (heat), `engine/jobs.dart` (background checks on hiring) | Medium |

## The Echelon

> [!note] Why this section exists
> The Echelon is built and named as a pillar in the investor memo, but has
> the thinnest spec of any shipped system in these docs. These three give
> it the kind of depth the career Hubs and prison already have.

| # | Adds | Touches | Size |
|---|---|---|---|
| EC1 | **Invite-only board seats**: a status ladder inside the Echelon separate from money — seats on boards/committees that must be invited into | `engine/echelon.dart` | Medium |
| EC2 | **Philanthropy as a second currency**: giving tracked separately from net worth, unlocking Echelon status the way money alone can't | `engine/echelon.dart`, `engine/wealth`-equivalent for tracking donations | Small–medium |
| EC3 | **Exposure-scaled scandal risk**: scandal probability scales with how visible your Echelon profile is, tying into Fame/paparazzi instead of rolling independently | `engine/echelon.dart`, `engine/celebrity.dart` | Small — mostly a weighting change plus a shared "exposure" number |

## Newspaper and the living world

| # | Adds | Touches | Size |
|---|---|---|---|
| N1 | **Player choices become headlines beyond crime/politics**: a business going public, an Echelon scandal, a championship win — feeding the newspaper from more systems than just crime and politics | `engine/world.dart` (newspaper generation), hooks from `engine/career_hub*.dart`, `engine/echelon.dart` | Medium — the newspaper pipeline exists; this is wiring more systems into it |
| N2 | ~~**Archive search**~~ — **Built 14 Nov.** `World.backIssueYears` lists every printed year in the world (ancestors' too); the newspaper has a Back issues button with a year/word search, opens any year as a back issue, and "From the archive" headlines open their year | `engine/world.dart`, `ui/newspaper.dart` | — |

## Features that existed but had no real content (14 Nov audit)

A different kind of gap from the rest of this doc: not "deepen a working
system" but "this is a tab in the Activities panel with almost nothing
behind it." Found by counting `GameAction`s per real player-facing
category (`lib/ui/activities.dart`'s category list, not internal
lowercase tags) across the whole engine:

| Category | Actions | Verdict |
|---|---|---|
| **Faith** | 2 | **Thin, confirmed.** No file of its own, no scenes, no state on `Life`, no tie to any other system. Two generic flavour actions ("Pray or reflect", "Join a community gathering") and nothing else. **Built out 14 Nov** — see the changelog and `engine/faith.dart`: a formative scene at 14 (`faithPath` on `Life`, four paths, non-denominational throughout), family reactions reusing `identity.dart`'s `outlookOf`, a revisit action, and a tie into People (a community gathering can introduce a friend) |
| Identity | 2 | Looks thin by count alone, but `identity.dart` carries real depth via scenes (`coming_out`, `name_change`) not counted here — not actually thin |
| Pets | 3 | `engine/pets.dart` is 854 lines with its own scene system — not thin, just few top-level menu actions |
| Social media | 3 | Backed by `celebrity.dart` (611 lines) and `social.dart` (675 lines) — not thin |
| Law | 3 | Backed by `career_law.dart` and the `sue`/`sue_lawyer` scenes — not thin |
| Licences | 3 | A licence is meant to be a small gate (driving, flying), not a content hub — correctly minimal, not a gap |

If another category starts to look suspiciously thin later, run the same
check first (`grep -rh "category: '<Name>'" lib/engine/*.dart | wc -l`,
then check for a scene system behind it) before assuming it needs work —
most low counts here turned out to be backed by real systems elsewhere.

## Suggested order

Cheapest and most self-contained first, since none of these blocks another:
~~**E3**~~ (reuses Second Acts directly) and ~~**C2**~~ (reuses the youth
unit directly) are built (14 Nov), and so are ~~**L1, P2, M2, N2**~~
(14 Nov) — next: **EC2/EC3** (gives the Echelon real depth
cheaply) → the Medium items → **E4** (business franchising) last, since
it's the one item here closer to a new system than an extension.
