---
title: Concept Brief (source of truth for all Phase 1 notes)
project: Relivable (working title)
phase: 1 - Planning
status: draft
updated: 2026-10-26
tags: [relivable, phase-1, brief]
---

# Relivable — Concept Brief

> Every planning note in this vault must stay consistent with this brief. If a note needs to deviate, it says so and why.

## One-liner
A text-first mobile life simulator that keeps everything players love about BitLife (birth-to-death, "Age +1", wild choices, generations) but redesigns it around **memory, clarity, fairness and sharing**.

**Working title:** Relivable (needs trademark/App Store name check before any public use).

## Five pillars
1. **Every choice remembered**: a storylet engine with NPC memory, consequences that come back years later, life chapters, traits.
2. **One tap to anything**: redesigned UI. Thumb-zone hub, contextual action cards, a search/command bar ("What do you want to do?") instead of BitLife's nested Activities menus. No action fails silently: locked actions say why.
3. **Fair forever**: all careers and core systems free. One optional premium unlock, capped opt-in ads, no pay-per-use Time Machine, purchases tied to an account and restored on any device.
4. **Share your story**: Spotify-Wrapped-style Life Recap cards, family-tree dynasty view, shareable scenario seeds and weekly challenges.
5. **Accessible by default**: full VoiceOver/TalkBack, dynamic type, colour-blind safe, reduced motion. Built in from day 1 (BitLife's repeated screen-reader regressions are a known pain point).

## Parity + "better" scope
- **Parity (redesigned):** every BitLife system: stats (visible + hidden), life stages, school/university/grad school, jobs + special careers, business, investing, real estate, crime/heists/prison, relationships, marriage, children, adoption/IVF/surrogacy, fame/social media, pets, Activities, health/doctors, death/will/inheritance, generations, ribbons/achievements, weekly challenges, god/editor tools, time rewind.
- **Better / new (from player research):** relationship percentages, parents who divorce/remarry with effects on kids, siblings and twins/triplets, school electives and teacher interactions, parties with guest lists, religion system, lawsuits with retaliation, deeper homelessness and military/police academy paths, heists that explain failure, traits, life chapters, era/historical mode, family tree + Dynasty Ambitions, avatar that ages, home customisation, optional on-device AI flavour text (never decides outcomes), async social (visit friends' lives, shared challenges), Creator Mode/UGC scenarios (later phase).

## Locked Phase 1 decisions (recommendations to the client)
| Area | Decision | Why (see research) |
|---|---|---|
| Platforms | iOS + Android phones first; tablets supported | BitLife's audience is mobile |
| Client tech | **Flutter** (Dart) + Shorebird OTA; Unity 6 as the alternative | Best built-in screen reader support, UI-heavy text game, cheaper hiring; Unity if heavy 2D/animation is wanted |
| Content | Data-driven **storylets** (JSON/YAML events with conditions + weights), validator + life simulator bot, delivered remotely; Ink/Yarn only for long scenes | Ship content without app updates; Fallen London model |
| Backend | Firebase (Auth, Firestore cloud saves, Remote Config, Analytics, Crashlytics) + RevenueCat; server-side StoreKit 2 / Play verification | Lost purchases/saves are a top BitLife complaint |
| AI | Optional, on-device first (Apple Foundation Models), cloud small-model fallback; rewords text only; moderation + report button | Cost ~$0.27/user/month in cloud; inZOI backlash shows AI must be optional |
| Rating | Target Apple 16+ / Google Mature 17+ (crime, drugs, romance) with age signals APIs | BitLife is 17+; 2026 US app-store age laws |
| Monetisation | Free + opt-in rewarded ads only (4/session, 8/day, 90 s cooldown) + **Relivable Plus** one-time $9.99 (no ads with ad rewards auto-granted, up to 8 generations, Destiny Mode editor, unlimited Rewind) + **No Ads** $2.99 (upgrade to Plus $6.99) + optional cosmetic/story **Season Pass** $4.99 + small **Story Packs** ($2.99 / $3.99) that add storylines, never lock careers + cosmetic Welcome Pack $1.99 and sets $0.99–1.99 + $14.99 / $24.99 bundles (9 products, see [[06 Monetization and Economy]] §2). One earn-only soft currency (Sparks); no premium currency, no loot boxes, no per-use Rewind, no subscriptions at launch. Optional web shop where allowed. | Anti-paywall positioning; BitLife's 2019 subscription test backlash |
| Launch languages | English, then Spanish, Brazilian Portuguese, German, French | BitLife's separate ES/BR apps show demand |
| Soft launch | Philippines + Ireland/Netherlands (+ Canada if budget) | Cheaper than CA/AU; 2026 practice |

## Phases
- **Phase 1 – Planning (this vault):** research, app breakdown, UX direction, business model, tech plan, budget, pitch.
- **Phase 2 – Prototype (8 weeks):** core loop vertical slice (birth→age 30), storylet engine, 150 events, redesigned hub, playtests.
- **Phase 3 – MVP & Soft launch (≈5–6 months):** full life cycle, core careers, monetisation, analytics, 1,500+ events, soft launch.
- **Phase 4 – Global launch (≈9–14 months from start):** parity + "better" features, 5 languages, marketing push.
- **Phase 5 – LiveOps:** seasons, story packs, async social, Creator Mode.

## Budget headline (estimates, not quotes)
- Prototype: ~$25–60K.
- MVP: labour ~$60–210K (US-team reference ~$385K).
- Total to global launch: ≈ $505K (low) – $1.03M (high), or ≈ $1.43–1.62M with a US team, excl. user acquisition ([[11 Roadmap Team and Budget]]).
- Writing, not engineering, is the critical path.

## Resolved decisions (2026-10-26)
These resolve conflicts between the Phase 1 notes. Every note follows them.

1. **Action search bar** sits at the **bottom** of the Life hub, next to the Age +1 button (thumb zone).
2. **Store catalogue** is the 9 products in [[06 Monetization and Economy]] §2: Relivable Plus $9.99; No Ads $2.99 with a $6.99 Plus Upgrade; Story Packs $2.99 / $3.99; Season Pass $4.99 per season; Welcome Pack $1.99 (cosmetic); cosmetic sets $0.99–1.99; Founder's Bundle $14.99; Complete Collection $24.99.
3. **End-of-life awards** are called **Life Titles**.
4. **Currency:** one earn-only soft currency, **Sparks**, never purchasable; no premium or paid currency. **Legacy Points** are a separate dynasty score.
5. **Ads:** opt-in rewarded only. Caps: 4 per session, 8 per day, 90-second cooldown. None during the first life, none during stories or activities, none for 7 days after a purchase. Plus removes ad offers and grants their rewards.
6. **Generations:** every dynasty is capped at **8 generations**. Free players reach Generation 4 (founder + 3 heirs); Plus extends a dynasty to Generation 8. At the cap the dynasty is completed, saved and shown as a Dynasty Recap, and the player can start a new dynasty. There is no limit on the number of dynasties.
7. **Rewind:** 1 free per life + 1 per day via an opt-in rewarded ad; never sold per use; unlimited with Plus.
8. **Tech:** Flutter as chosen in this brief; Unity 6 stays the alternative, decided at the end of Phase 2.
9. **Timeline:** Phase 2 runs 9 Nov 2026 – 8 Jan 2027; soft launch 17 May 2027 (Philippines, then Ireland/Netherlands, Canada optional); global launch target 12 Oct 2027.
10. **Budgets (estimates):** prototype $25–60K; MVP labour $60–210K (US reference $385K); total to global launch excl. UA ≈ $505K (low) – $1.03M (high), US team ≈ $1.43–1.62M.
11. **Retention:** targets D1 40% / D7 13% / D30 5%; soft-launch gates 35% / 10% / 3.5%.

## Research sources
All research notes live in `research_notes/Life sim game phase 1/` and `research_notes/BitLife complete feature guide/`, plus the report `reports/BitLife complete feature guide.md`. Research came from web-search snippets (page fetching and Reddit were blocked), so figures must be shown as estimates with sources.
