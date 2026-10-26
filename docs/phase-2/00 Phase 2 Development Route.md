---
title: "00 Phase 2 Development Route"
project: Relivable
phase: 2
status: draft
updated: 2026-10-26
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
| 2. Android app file (APK) (from Sprint 3) | A real Android app you install from a download link, built automatically by GitHub on every push | Android | Allow "install from this source" once |
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

## Decisions needed now
1. **Design direction:** A Storybook, B Night Feed or C Clean Slate (see the design board).
2. **Your phone:** Android, iPhone or both (decides whether the APK or TestFlight comes next after the web build).
3. **Where the web build is hosted:** a private link (recommended for now) or GitHub Pages (needs a public repo or a paid GitHub plan).
