---
title: Concept Brief (source of truth for all Phase 1 notes)
project: EverLife (working title)
phase: 1 - Planning
status: draft
updated: 2026-10-25
tags: [everlife, phase-1, brief]
---

# EverLife — Concept Brief

> Every planning note in this vault must stay consistent with this brief. If a note needs to deviate, it says so and why.

## One-liner
A text-first mobile life simulator that keeps everything players love about BitLife (birth-to-death, "Age +1", wild choices, generations) but redesigns it around **memory, clarity, fairness and sharing**.

**Working title:** EverLife (needs trademark/App Store name check before any public use).

## Five pillars
1. **Every choice remembered**: a storylet engine with NPC memory, consequences that come back years later, life chapters, traits.
2. **One tap to anything**: redesigned UI. Thumb-zone hub, contextual action cards, a search/command bar ("What do you want to do?") instead of BitLife's nested Activities menus. No action fails silently: locked actions say why.
3. **Fair forever**: all careers and core systems free. One optional premium unlock, capped opt-in ads, no pay-per-use Time Machine, purchases tied to an account and restored on any device.
4. **Share your story**: Spotify-Wrapped-style Life Recap cards, family-tree dynasty view, shareable scenario seeds and weekly challenges.
5. **Accessible by default**: full VoiceOver/TalkBack, dynamic type, colour-blind safe, reduced motion. Built in from day 1 (BitLife's repeated screen-reader regressions are a known pain point).

## Parity + "better" scope
- **Parity (redesigned):** every BitLife system: stats (visible + hidden), life stages, school/university/grad school, jobs + special careers, business, investing, real estate, crime/heists/prison, relationships, marriage, children, adoption/IVF/surrogacy, fame/social media, pets, Activities, health/doctors, death/will/inheritance, generations, ribbons/achievements, weekly challenges, god/editor tools, time rewind.
- **Better / new (from player research):** relationship percentages, parents who divorce/remarry with effects on kids, siblings and twins/triplets, school electives and teacher interactions, parties with guest lists, religion system, lawsuits with retaliation, deeper homelessness and military/police academy paths, heists that explain failure, traits, life chapters, era/historical mode, family tree + dynasty goals, avatar that ages, home customisation, optional on-device AI flavour text (never decides outcomes), async social (visit friends' lives, shared challenges), Creator Mode/UGC scenarios (later phase).

## Locked Phase 1 decisions (recommendations to the client)
| Area | Decision | Why (see research) |
|---|---|---|
| Platforms | iOS + Android phones first; tablets supported | BitLife's audience is mobile |
| Client tech | **Flutter** (Dart) + Shorebird OTA; Unity 6 as the alternative | Best built-in screen reader support, UI-heavy text game, cheaper hiring; Unity if heavy 2D/animation is wanted |
| Content | Data-driven **storylets** (JSON/YAML events with conditions + weights), validator + life simulator bot, delivered remotely; Ink/Yarn only for long scenes | Ship content without app updates; Fallen London model |
| Backend | Firebase (Auth, Firestore cloud saves, Remote Config, Analytics, Crashlytics) + RevenueCat; server-side StoreKit 2 / Play verification | Lost purchases/saves are a top BitLife complaint |
| AI | Optional, on-device first (Apple Foundation Models), cloud small-model fallback; rewords text only; moderation + report button | Cost ~$0.27/user/month in cloud; inZOI backlash shows AI must be optional |
| Rating | Target Apple 16+ / Google Mature 17+ (crime, drugs, romance) with age signals APIs | BitLife is 17+; 2026 US app-store age laws |
| Monetisation | Free + opt-in rewarded ads (frequency-capped) + **EverLife Plus** one-time ~$9.99 (no ads, unlimited generations, editor tools, rewind) + optional cosmetic/story **Season Pass** ~$4.99 + small **Story Packs** (~$2.99–3.99) that add storylines, never lock careers. Optional web shop where allowed. No loot boxes. | Anti-paywall positioning; BitLife's 2019 subscription test backlash |
| Launch languages | English, then Spanish, Brazilian Portuguese, German, French | BitLife's separate ES/BR apps show demand |
| Soft launch | Philippines + Ireland/Netherlands (+ Canada if budget) | Cheaper than CA/AU; 2026 practice |

## Phases
- **Phase 1 – Planning (this vault):** research, app breakdown, UX direction, business model, tech plan, budget, pitch.
- **Phase 2 – Prototype (6–8 weeks):** core loop vertical slice (birth→age 30), storylet engine, 150 events, redesigned hub, playtests.
- **Phase 3 – MVP & Soft launch (≈5–6 months):** full life cycle, core careers, monetisation, analytics, 1,500+ events, soft launch.
- **Phase 4 – Global launch (≈9–14 months from start):** parity + "better" features, 5 languages, marketing push.
- **Phase 5 – LiveOps:** seasons, story packs, async social, Creator Mode.

## Budget headline (estimates, not quotes)
- Prototype: ~$25–60K.
- MVP: ~$60–150K (hybrid team) up to ~$385K (US team).
- Full launch: ~$0.5–1.1M (EE/LatAm team) up to $1.2–2M (US team), excl. user acquisition.
- Writing, not engineering, is the critical path.

## Research sources
All research notes live in `research_notes/Life sim game phase 1/` and `research_notes/BitLife complete feature guide/`, plus the report `reports/BitLife complete feature guide.md`. Research came from web-search snippets (page fetching and Reddit were blocked), so figures must be shown as estimates with sources.
