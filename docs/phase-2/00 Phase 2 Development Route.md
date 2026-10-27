---
title: "00 Phase 2 Development Route"
project: Relivable
phase: 2
status: in progress
updated: 2026-10-27
tags: [relivable, phase-2, roadmap]
---

# 00 Phase 2 Development Route

*Purpose:* How the Phase 2 prototype gets built, how you play it on your phone at every step, and how long each part takes. It follows the Phase 1 plan ([[_Concept Brief]], [[11 Roadmap Team and Budget]]).

## What Phase 2 must prove (from the plan)
- **Scope:** a vertical slice from birth to age 30, about 150 events, the storylet engine, the redesigned Life hub and action search, and real playtests ([[11 Roadmap Team and Budget]]).
- **Tech:** Flutter (Dart), data-driven storylets, offline-first saves. Unity 6 stays the fallback, decided at the end of Phase 2 ([[08 Technical Architecture]]).
- **Gate 2 (go / no-go):** fun and clarity in playtests, early retention signals, writer throughput measured ([[12 Risks and KPIs]]).

## How you play it on your phone
| Step | What you get | Works on | Needs from you |
|---|---|---|---|
| 1. Web build (from Sprint 1) | A link that opens the game in your phone's browser; "Add to Home Screen" makes it look like an app (full screen, own icon, works offline) | iPhone and Android | Nothing |
| 2. Android app file (APK) (live now) | A real Android app from a permanent link: [Relivable.apk](https://github.com/ZWITG/agent-weave-workbench/releases/download/relivable-latest/Relivable.apk). Rebuilt by GitHub on every push, and **installed copies update themselves**: on launch the app offers "Update now" and Android asks you to confirm the install | Android | Allow "install from this source" once. If you installed an APK from before 27 Oct 2026, uninstall it once first (older builds were signed with a different key) |
| 2b. Windows app (live now) | [RelivableSetup.exe](https://github.com/ZWITG/agent-weave-workbench/releases/download/relivable-latest/RelivableSetup.exe) or a portable zip from the same release | Windows | Nothing |
| 3. iPhone test app (TestFlight) (later in Phase 2 or Phase 3) | A real iPhone app installed through Apple's TestFlight | iPhone | An Apple Developer account ($99/year) and a Mac-based build step in GitHub Actions |

## Sprints (the route)
| Sprint | Build | Playable result |
|---|---|---|
| 0 · Setup | Flutter project in `game/`, chosen design as theme tokens, CI that builds web and Android | An empty app on your phone |
| 1 · Core loop | Character creation, four stats + hidden stats, Age +1, year feed, Life hub, event cards, save on device | Be born and age to 30 with placeholder events |
| 2 · Storylet engine | Event data files (conditions, weights, choices, outcomes), NPC memory and callbacks, validator, simulator bot | Events that remember earlier choices |
| 3 · Systems slice | Family and Bond %, school (grades, cliques, electives), first jobs, money, a little crime, health, action search | A full childhood-to-30 life |
| 4 · World legacy (MVP slice) | Family name reputation, history-book entries, "Your place in history" recap card, one world per player | Ancestors start to matter |
| 5 · Content + polish | Reach about 150 events, Life Recap share card, accessibility pass (screen reader, text size), sound and haptics | Ready for playtests |
| 6 · Playtests + Gate 2 | Analytics events, feedback form, playtest build, Gate 2 report | Real players test it |

## Progress (27 Oct 2026)
| Sprint | Status | What is built |
|---|---|---|
| 0 · Setup | Done | Flutter project in `game/`, Night Feed theme, CI building web, Android and Windows, auto-update release |
| 1 · Core loop | Done | Character creation, 4 stats + 6 hidden stats, Age +1, year feed, Life hub, event and outcome cards, on-device saves |
| 2 · Storylet engine | Done | Data-driven events with conditions, weights, flags and callbacks; NPC memory and grudges; validator; 500-life simulator test |
| 3 · Systems slice | Mostly done | Relationships with Bond facets and interactions; school routes; job board and career ladders; working economy (Wealth tab); 56 activities in 16 categories with 7 mini-games; a little crime; sound and haptics |
| 4 · World legacy (MVP slice) | Done early | One world per player, yearly world/national/local news, newspaper, bounded world effects, deeds in history, family-name reputation, Echo events, "Your world" card |
| 5 · Content + polish | In progress | 40 events with richer writing (target about 150); accessibility labels on new screens |
| 6 · Playtests + Gate 2 | Not started | |

**Changes the owner asked for during Phase 2** (all now in the plan; see [[_Concept Brief]] decisions 21–32): richer visuals with money always visible; Activities as a swipe-up panel instead of a tab, then decluttered; more activities; relationships exactly as planned; stronger event results; age-up audio; mini-games; options on the Path tab; results as pop-ups; a working Wealth tab; auto-update on phones; richer event writing; a living world with a newspaper and updates from people you know; keeping the plan updated.

## How long it takes
> [!note] Two different clocks
> **My build time** is how long the coding and first-draft writing take me. **Calendar time** includes things only people can do: choosing, reviewing, playtesting, accounts and approvals. I work in sessions when you ask, not continuously in the background.

| Part | My build time (estimate) | Calendar time (estimate) |
|---|---|---|
| Sprint 0–1: first playable on your phone | 1–2 working sessions | A few days |
| Sprints 2–5: full Phase 2 prototype | about 6–10 working sessions | 2–4 weeks, mostly your review of events and feel |
| Sprint 6: playtests and Gate 2 | 1–2 sessions to set up and report | 1–2 weeks with 10–20 real players |
| **Phase 2 total** | **about 8–14 sessions** | **about 4–7 weeks** (plan: 8 weeks with a team) |
| Phases 3–4: MVP, soft launch, global launch | Code can go much faster than the plan's team estimate | **about 6–9 months**, set by things that cannot be rushed: writing and editing 1,500–3,000+ events, art and avatars, store accounts and age ratings, legal review, and 3–4 months of soft-launch player data |

The plan's 11 months assumed a 7–10 person team. With me doing most of the coding and first-draft writing, the realistic target is **about 7–10 months to global launch**, provided you (or a small team) handle content review, art direction, store accounts, legal and playtesting.

## Decisions
1. **Design direction (decided 26 Oct 2026): B Night Feed with the Hub + event card.** The options were: pick a **look** (A Storybook, B Night Feed, C Clean Slate) and a **way to play** (Hub with event card, A2 Book pages, B2 Swipe cards, C2 Timeline + bottom sheet). Looks and ways to play can be mixed, for example the Storybook look with swipe cards. All six screens are on the design board.
2. **Your phone:** the Android app is live with auto-update; iPhone (TestFlight) is still open and needs an Apple Developer account.
3. **Where the web build is hosted:** a private link is in use. GitHub Pages remains an option later.
