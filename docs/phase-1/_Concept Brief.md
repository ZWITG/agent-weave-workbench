---
title: "Concept Brief"
project: Relivable
phase: 1
status: review
updated: 2026-10-26
tags: [relivable, phase-1, brief]
---

# Concept Brief: Relivable

*Purpose:* The source of truth for Phase 1: the pillars, scope, locked and resolved decisions, phases and budget headline that every other note follows.

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
- **Better / new (from player research):** relationship percentages, parents who divorce/remarry with effects on kids, siblings and twins/triplets, school electives and teacher interactions, parties with guest lists, religion system, lawsuits with retaliation, deeper homelessness and military/police academy paths, heists that explain failure, traits, life chapters, era/historical mode, family tree + Dynasty Ambitions, avatar that ages, home customisation, optional on-device AI flavour text (never decides outcomes), async social (visit friends' lives, shared challenges), Creator Mode/UGC scenarios (later phase), world legacy and history (family name reputation, history-book mentions of notable ancestors, Echo events and bounded world effects).

## Locked Phase 1 decisions (recommendations to the client)
| Area | Decision | Why (see research) |
|---|---|---|
| Platforms | iOS + Android phones first; tablets supported | BitLife's audience is mobile |
| Client tech | **Flutter** (Dart) + Shorebird OTA; Unity 6 as the alternative | Best built-in screen reader support, UI-heavy text game, cheaper hiring; Unity if heavy 2D/animation is wanted |
| Content | Data-driven **storylets** (JSON/YAML events with conditions + weights), validator + life simulator bot, delivered remotely; Ink/Yarn only for long scenes | Ship content without app updates; Fallen London model |
| Backend | Firebase (Auth, Firestore cloud saves, Remote Config, Analytics, Crashlytics) + RevenueCat; server-side StoreKit 2 / Play verification | Lost purchases/saves are a top BitLife complaint |
| AI | Optional, on-device first (Apple Foundation Models), cloud small-model fallback; rewords text only; moderation + report button | Cost ~$0.27/user/month in cloud; inZOI backlash shows AI must be optional |
| Rating | Target Apple 16+ / Google Mature 17+ (crime, drugs, romance) with age signals APIs | BitLife is rated 18+ on the US App Store (17+ under Apple's old tiers); 2026 US app-store age laws |
| Monetisation | Free + opt-in rewarded ads only (4/session, 8/day, 90 s cooldown) + **Relivable Plus** one-time $9.99 (no ads with ad rewards auto-granted, up to 8 generations, Destiny Mode editor, unlimited Rewind) + **No Ads** $2.99 (upgrade to Plus $6.99) + optional cosmetic/story **Season Pass** $4.99 + small **Story Packs** ($2.99 / $3.99) that add storylines, never lock careers + cosmetic Welcome Pack $1.99 and sets $0.99–1.99 + $14.99 / $24.99 bundles (9 products, see [[06 Monetization and Economy]] §2). One earn-only soft currency (Sparks); no premium currency, no loot boxes, no per-use Rewind, no subscriptions at launch. Web shop at global launch (Phase 4) where store rules allow. | Anti-paywall positioning; BitLife's 2019 subscription test backlash |
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
12. **Save slots:** 3 for free players, 10 with Plus. Sparks never buy save slots.
13. **Seasons:** about 13 weeks each, 4 a year; Season Pass $4.99 per season, non-renewing.
14. **Inheritance:** trusts for heirs under 18 ship at MVP (no forced auctions).
15. **Twins:** a player-born-a-twin toggle ships at MVP; twin-specific storylines ship at Launch.
16. **Web shop:** launches with global launch (Phase 4), US first, where store rules allow.
17. **Dynasty goals:** no Dynasty Ambition needs more than 4 generations; no weekly challenge task needs more than 3.
18. **Phase 5 team:** 7.5–9.0 FTE (LiveOps run rate ≈ $66–99K/month, US reference ≈ $158K/month; [[11 Roadmap Team and Budget]] §4.6).
19. **Name and codes:** the working title is **Relivable** everywhere; scenario seed codes use the `#RL-` prefix.
20. **World legacy and history ("Echoes"):** past lives shape a persistent world. MVP ships family name reputation and history-book (Almanac) mentions; Launch adds the World Ledger, Echo events, bounded world effects, persistent companies and the World Timeline; LiveOps adds cross-dynasty Echoes and visiting friends' world histories. Always free. Spec: [[04 App Breakdown - Core Life Systems]] Module 11.

## Research sources
All research notes live in `research_notes/Life sim game phase 1/` and `research_notes/BitLife complete feature guide/`, plus the report `reports/BitLife complete feature guide.md`. Research was gathered through web search (full reports and Reddit could not be reviewed directly), so figures are shown as estimates with sources.

## Change log

**2026-10-26**
- **New feature: World Legacy and History ("Echoes").** Notable past lives (criminals, leaders, tycoons, philanthropists, icons) enter in-game history books, shape the family name's reputation, and leave decaying effects on the economy, policing and landmarks of their world. MVP: name reputation + history-book mentions; Launch: World Ledger, Echo events, world effects; LiveOps: cross-dynasty and shared histories. Added to both App Breakdown notes, the parity checklist and the feature matrix.
- **Renamed to Relivable** (working title, pending trademark and store-name clearance). Scenario seed codes now use the `#RL-` prefix.
- **Dynasty cap set to 8 generations** for every dynasty: free players reach Generation 4 (founder + 3 heirs), Plus extends to Generation 8, completed dynasties are saved and shown as a Dynasty Recap, and the number of dynasties is unlimited. No Dynasty Ambition needs more than 4 generations and no challenge task more than 3.
- **Settled details applied across all notes:** Plus save slots 10 (free 3; Sparks no longer buy save slots); seasons about 13 weeks; trusts for minors at MVP; player-born-a-twin toggle at MVP with twin storylines at Launch; web shop at global launch (Phase 4); Phase 5 team 7.5–9.0 FTE with the LiveOps run rate re-costed to ≈ $66–99K/month (US reference ≈ $158K/month); Story Packs about every two months; daily-goal rewards paid in Sparks (the only soft currency).
- **Fact-check corrections (checked 26 Oct 2026):**
  - Unity Pro is now $2,310 per seat per year ($210/month), up from $2,200 on 12 Jan 2026 ([Unity](https://unity.com/pricing-updates)).
  - Apple's EU single business model (from 1 Oct 2026): alternative payments and link-outs drop to 10% for programme members, and the old store-services fees are gone. The previously listed 15% small-business IAP rate could not be confirmed and was removed ([The Next Web](https://thenextweb.com/news/apple-eu-app-store-fees-dma-core-technology-commission)).
  - Google Play's post-settlement fees are clarified: about 20% standard and 10% on the first $1M and on subscriptions, a ~5% Play Billing fee, worldwide rollout by 30 Sep 2027, and final court approval still pending ([iClarified](https://www.iclarified.com/101291/google-opens-play-store-to-alternative-payments-under-epic-settlement)).
  - US Apple link-out: Apple's 13 Aug 2026 request for a 15% rate is pending; the commission is 0% until a rate is approved ([MacDailyNews](https://macdailynews.com/2026/08/14/u-s-supreme-court-clears-path-for-app-store-commission-showdown-as-apple-must-defend-its-rates-in-lower-court/)).
  - EU Digital Fairness Act: the proposal is now expected in November 2026, with tentative dates around 18 Nov ([MLex](https://www.mlex.com/mlex/articles/2529049)).
  - BitLife's US App Store rating is confirmed as 18+ (previously 17+). BitLife's Q3 2026 organic growth of -2% is confirmed against the 23 Oct 2026 Stillfront report ([Stillfront Q3 2026](https://www.inderes.fi/en/releases/stillfronts-interim-report-q3-2026-continued-key-franchise-growth-and-stable-organic-revenue)). The end of BitLife's Seasons pass in Aug 2026 could not be independently confirmed and is now marked "reportedly".
  - Verified with no change needed: The Sims Mobile closed on 20 Jan 2026; the amended COPPA rule's compliance date was 22 Apr 2026; Apple's 4+/9+/13+/16+/18+ tiers and the 31 Jan 2026 questionnaire deadline; Texas SB 2420 is enforceable after the Supreme Court declined to vacate the Fifth Circuit stay on 6 Jul 2026; the GameAnalytics 2026 retention medians (D1 ~22%, D7 ~4%, D30 ~0.7%; top 10% ~40% / 11–12% / ~4%); BitLife's US in-app prices ($7.99 / $9.99 / $15.99 / $20.99).
