---
title: "12 Risks and KPIs"
project: EverLife
phase: 1
tags: [everlife, phase-1, risks, kpis, stage-gates, metrics]
updated: 2026-10-26
---

# 12 Risks and KPIs

> [!summary]
> - **The top 3 risks:** content throughput (writing is the critical path), retention below top-decile (which makes paid UA uneconomic), and a rating or age-law squeeze on the teen audience.
> - **North Star:** **Weekly Story Players (WSP)**, the unique players who age a character **≥ 10 in-game years** in a week. It captures the core loop and correlates with both ad and IAP revenue.
> - **Status of all targets:** **targets** are hypotheses calibrated against public benchmarks, to be re-based on prototype and soft-launch data. They are not forecasts.

Related: [[_Concept Brief]] · [[01 Executive Summary]] · [[06 Monetization and Economy]] · [[07 Retention and LiveOps]] · [[08 Technical Architecture]] · [[09 Compliance and Ratings]] · [[10 Go-to-Market]] · [[11 Roadmap Team and Budget]].

---

## 1. Risk register

Scale: **L**ikelihood and **I**mpact are each 1 (low) to 3 (high). Score = L × I. 🔴 ≥ 6, 🟠 3–4, 🟢 ≤ 2.

| ID | Risk | L | I | Score | Mitigation | Owner | Early-warning trigger |
|---|---|---|---|---|---|---|---|
| R1 | **Content throughput below plan.** 1,500 events at MVP and 3,000+ at launch need about 8 net events/writer-day, and that throughput figure is unsourced ([[11 Roadmap Team and Budget]] §6) | 3 | 3 | 🔴 9 | Measure throughput in Phase 2. Templated storylet families. Validator + sim bot. A contract-writer pool of 6–10 people. A scope lever: launch with 2,500 events plus a monthly cadence | Narrative Lead | Throughput < 6/day for 2 consecutive weeks |
| R2 | **Retention below top-decile** (D1 < 35%, D30 < 3%). Then UA can't pay back: LTV about $2–2.50 against a US iOS CPI of about $2–3 ([monetization research §6](../../research_notes/Life%20sim%20game%20phase%201/monetization_retention.md)) | 2 | 3 | 🔴 6 | FTUE to first wild event in < 60 s. Callback arcs. Weekly challenges. Opt-in push after the first life ends. Soft-launch iteration window. Organic-first GTM | Product Owner | SL cohort D1 < 30% or D7 < 7% |
| R3 | **Repetition**: players see the same events. This is BitLife's main gameplay criticism ([Mechanics of Magic](https://mechanicsofmagic.com/?p=5062)) | 2 | 3 | 🔴 6 | Cooldowns, `maxPerLife`, salience tiers, memory-biased weights. Sim-bot gate: repeats < 5% per life | Narrative Lead | `storylet_shown` repeat rate > 5% |
| R4 | **Rating lands at 18+** or the teen audience is cut by the 16+ rating. That hurts virality | 2 | 3 | 🔴 6 | Implied-only sexual content. Gambling sim hidden for under-18. Questionnaire dry-run in Phase 2. Teen profile option in Phase 5 ([[09 Compliance and Ratings]] §2–3) | Producer | Dry-run result is 18+ |
| R5 | **US age-law non-compliance** (Texas enforceable, Utah private right of action from 31 Dec 2026, Louisiana has no safe harbor) ([Bass Berry](https://www.bassberry.com/news/apps-and-minors-new-compliance-frontiers-and-risks-in-louisiana-utah-and-texas/)) | 2 | 3 | 🔴 6 | Age-signal APIs, IAP ratings, significant-change notices, data deletion. Counsel's quarterly memo | Producer + Counsel | A new statute or ruling. Any store policy notice |
| R6 | **Flutter accessibility or ad-SDK gap.** Flame canvas + `Semantics` is unverified, and ad mediation plugins may lag | 2 | 2 | 🟠 4 | A Phase 2 spike with go/no-go switch criteria to Unity 6 ([[08 Technical Architecture]] §1.2) | Tech Lead | Spike fails, with a fix above 2 engineer-weeks |
| R7 | **Save or purchase loss incidents** destroy trust (a top BitLife complaint) ([Google Play review](https://play.google.com/store/apps/eventdetails/4831791308351315470)) | 2 | 3 | 🔴 6 | Offline-first + cloud sync. No silent overwrite. Migration tests. RevenueCat server verification. Restore on sign-in | Tech Lead | Any `save_conflict` data-loss report. Restore success < 99.9% |
| R8 | **Accessibility regression** ships (BitLife's history) ([AppleVis](https://www.applevis.com/comment/135452)) | 2 | 3 | 🔴 6 | CI guideline checks. A manual screen-reader release gate. Blind testers. External audit | QA Lead | Any P0 a11y bug in a release candidate |
| R9 | **IP or clone claim** from the incumbent (which showed DMCA aggressiveness in 2023) ([AppleVis](https://applevis.com/comment/144257)) | 2 | 3 | 🔴 6 | Original text and art, a banned-terms list, writer attestations, plagiarism checks, distinct trade dress. Counsel review of store assets | Producer + Counsel | Takedown notice or C&D |
| R10 | **Name unavailable**: "EverLife" is a working title | 2 | 2 | 🟠 4 | Clearance in Phase 2 with 3 backup names. Working-title handles | Client | Search finds conflicts |
| R11 | **Monetization too generous**: all careers free plus one ~$9.99 unlock gives ARPDAU < $0.12 | 2 | 3 | 🔴 6 | Season Pass + Story Packs + capped rewarded ads. Price-ladder A/B tests via Remote Config. Web shop margin. Pillar 3 stays non-negotiable | Product Owner | SL ARPDAU < $0.12 or payer conversion < 1.5% |
| R12 | **Paid UA dependence / rising CPIs**: Meta and TikTok CPI +15–20% YoY ([Admiral](https://admiral.media/mobile-game-marketing-benchmarks/)). BitLife fell 19% when it cut UA ([Stillfront](https://www.stillfront.com/en/stillfronts-interim-report-q2-2026-strengthened-profitability-and-continued-revenue-stability/)) | 3 | 2 | 🔴 6 | Organic-first: Life Recap, seeds, creators, Discord. Scale gate LTV ≥ 1.2× CPI ([[10 Go-to-Market]] §10) | UA Lead | Blended CPI > D90 LTV |
| R13 | **AI backlash or AI policy breach** (inZOI review-bombing; Apple 1.2 and 5.1.2(i); Google report button) | 2 | 2 | 🟠 4 | AI optional, off by default, rewording only. Moderation, report button, consent. Never in headline marketing | Tech Lead | Negative-review spike mentioning AI. Store rejection |
| R14 | **Remote content judged a "hidden feature"** under Apple 2.5.19 ([letsdatascience](https://letsdatascience.com/news/apple-revises-app-review-guidelines-for-ai-deepfakes-and-hid-76fdff63)) | 1 | 3 | 🟠 3 | Bundles stay inside reviewed systems. Review notes describe the model. New systems ship via store builds | Producer | Review rejection citing 2.5.19 |
| R15 | **Localisation cost and quality**: 1.2M words. Gendered grammar breaks variables | 2 | 2 | 🟠 4 | ICU from day 1. Pseudo-loc. Glossary. MT + post-edit for low-risk strings. LQA sampling. Per-word rates must be quoted (gap) | Loc Manager | Quote > $0.12/word. LQA fail rate > 3% |
| R16 | **Sensitive-content harm or PR incident** (suicide, abuse, mental health) | 1 | 3 | 🟠 3 | Not a player action. Content notes, helplines, sensitivity review, skip with no penalty ([[09 Compliance and Ratings]] §11) | Narrative Lead | Player reports. Press inquiry |
| R17 | **Platform fee and policy volatility** (US link-out 0% → proposed 15%; Google 10–25% tiers; EU DMA fees from Oct 2026) ([MacRumors](https://macrumors.com/2026/08/19/ec-epic-apple-app-store-changes)) | 3 | 1 | 🟠 3 | Model margins at standard store fees. Treat the web shop as upside only | Product Owner | Rate-card publications |
| R18 | **EU Digital Fairness Act / CPC action** on virtual currency and design ([Lewis Silkin](https://www.lewissilkin.com/insights/2026/10/15/eu-consumer-protection-network-launches-action-involving-nine-video-games-compani-102o5do)) | 1 | 2 | 🟢 2 | No premium currency, no paid randomness, real-money prices, no dark patterns | Counsel | DFA draft text |
| R19 | **Key-person risk** (tech lead or narrative lead) | 2 | 3 | 🔴 6 | Documented engine (pure Dart pkg), style bible, pairing, contract back-up writers | Producer | Resignation / extended absence |
| R20 | **Budget overrun** (scope creep from "parity + better") | 2 | 2 | 🟠 4 | Gates with scope levers (cut era mode or async social to Phase 5). 5–10% contingency. Monthly burn review | Producer | Burn > plan by 10% for 2 months |
| R21 | **Performance on low-end Android** (5,000-event tick, memory) | 1 | 2 | 🟢 2 | Precompiled condition indices. Budgets in CI ([[08 Technical Architecture]] §8) | Tech Lead | Tick > 120 ms p95 on the reference device |
| R22 | **UGC / Creator Mode moderation** (teen exposure, Apple 1.2) | 2 | 2 | 🟠 4 | Phase 5 only. Report/block, pre-moderation for featured scenarios, publishing limited to adults *(recommendation)* | Product + Counsel | Report volume above SLA |

---

## 2. KPI framework

> [!info] Benchmarks used
> - **GameAnalytics 2026** (2025 data): median D1 ≈ 22%, D7 < 4%, D30 0.69–0.79%; **top 10%** ≈ 40% / 11–12% / ≈ 4% ([GameDevReports](https://gamedevreports.substack.com/p/gameanalytics-mobile-and-pc-game)).
> - **Liftoff/Singular casual**: CPI iOS $1.41 / Android $0.14; D30 ROAS iOS 47% / Android 15% ([Liftoff](https://liftoff.ai/?p=34267)).
> - **Appodeal**: Life Simulator US Android ARPU **$11.08–14.83**, a top hybrid-casual subgenre ([gameindustrylibrary](https://gameindustrylibrary.com/documents/mobile-casual-benchmarks-report-2025)).
> - **Rewarded eCPM**: US iOS $19.63 / Android $16.49 (Q4 2024) ([Appodeal](https://appodeal.com/the-mobile-ecpm-report-updated-q4-2024-view)).
> - **Payer conversion**: ~2–3.5% ([PocketGamer.biz](https://www.pocketgamer.biz/comment-and-opinion/64530/best-practices-for-implementing-iap-starter-packs-in-free-to-play-games/entry/1/)).

### 2.1 North Star

| Metric | Definition | Target (Launch + 90 days) | Why |
|---|---|---|---|
| **Weekly Story Players (WSP)** | Unique users who age a character ≥ 10 in-game years in a calendar week | **Target:** WSP/MAU ≥ 45%. Absolute WSP target set after soft launch | Captures the core loop (choices → consequences). Leading indicator of retention, ad views and Plus conversion |
| Companion: **Callback-experienced rate** | % of completed lives where ≥ 3 memory callbacks fired | **Target:** ≥ 80% | Measures Pillar 1 directly |

### 2.2 Acquisition

| KPI | Target | Benchmark / note |
|---|---|---|
| Store page conversion (view → install) | **Target:** ≥ 30% (iOS) / ≥ 25% (Play) | Estimate. First 3 screenshots drive it ([AppTweak](https://www.apptweak.com/en/aso-blog/best-aso-practices-for-your-app-game-creatives?lang=en-US)) |
| Organic share of installs (launch + 90 d) | **Target:** ≥ 50% | Organic-first strategy |
| Blended CPI, US iOS / Android | **Target:** ≤ $2.50 / ≤ $1.20 | NA casual about $3 / $2 ([Segwise](https://segwise.ai/blog/cpi-ipm-roas-benchmarks-optimizing-ad-spend/)) |
| IPM (top creative) | **Target:** ≥ 2× account median. UGC creatives tested every week | UGC +152% IPM ([Liftoff](https://www.newswire.ca/news-releases/liftoff-s-2025-mobile-ad-creative-index-reveals-ugc-is-a-key-differentiator-for-top-apps-837345804.html)) |
| Pre-registrations by launch | **Target:** 50–150K (low confidence) | No conversion data found (gap) |
| **Virality:** recap share rate / seed open → install / K-factor | **Targets:** ≥ 8% / ≥ 15% / 0.15–0.30 | Wrapped precedent ([RouteNote](https://routenote.com/blog/spotify-wrapped-2025-record-breaking-launch/)) |

### 2.3 Engagement

| KPI | Target | Note |
|---|---|---|
| Sessions per DAU | **Target:** ≥ 2.5 | Estimate |
| Avg session length | **Target:** 8–14 min | Estimate. No life-sim session data found (gap) |
| In-game years aged per session | **Target:** ≥ 12 | Core-loop velocity |
| FTUE completion (step 8) | **Target:** ≥ 85%. First wild event in < 60 s | [Playio](https://blog.playio.co/mobile-game-onboarding-retention) |
| Lives completed per WAU per week | **Target:** ≥ 1.2 | Meta loop |
| Generation continue rate | **Target:** ≥ 40% of deaths with an heir | Dynasty pillar |
| Weekly challenge participation | **Target:** ≥ 25% of WAU | LiveOps ([[07 Retention and LiveOps]]) |
| Command bar usage / zero-result searches | **Targets:** ≥ 30% of actions via command bar or cards; zero-result < 5% | Pillar 2 |
| Event repeat rate within a life | **Target:** < 5% | R3 |

### 2.4 Retention

| KPI | Target (soft launch → launch) | Median | Top 10% |
|---|---|---|---|
| D1 | **Target: 38% → 40%** | ~22% | ~40% |
| D7 | **Target: 11% → 13%** | < 4% | 11–12% |
| D30 | **Target: 4% → 5%** | 0.69–0.79% | ~4% |
| D90 | **Target: ≥ 2%** | — | — |
| Push opt-in (prompt after first life) | **Target:** iOS ≥ 50%, Android ≥ 80% | iOS ~51%, Android ~81% ([Pushwoosh](https://cdc.pushwoosh.com/blog/increase-push-notifications-opt-in)) |

### 2.5 Monetization

| KPI | Target | Benchmark |
|---|---|---|
| ARPDAU (IAP + ads, Tier-1) | **Target:** $0.15–0.40 (base $0.25) | Hybrid-casual $0.15–0.50 (vendor) ([Juego](https://www.juegostudio.com/blog/arpdau-benchmarks-by-game-genre)) |
| Payer conversion (D30) | **Target:** 2.5–4% | ~2–3.5% |
| EverLife Plus attach (of payers) | **Target:** ≥ 60% | Design intent ([[06 Monetization and Economy]]) |
| ARPPU (D90) | **Target:** $9–14 | Casual D90 ARPPU $7.26 ([gamedevreports](https://gamedevreports.substack.com/p/weekly-gaming-reports-recap-june-e95)) |
| Rewarded ad opt-in (of non-payer DAU) | **Target:** 30–45%, ≤ cap per day | 76% of players prefer opt-in ads (2017 vendor survey) ([MarketingDive](https://www.marketingdive.com/press-release/20170613-mobile-gamers-prefer-rewarded-ads-by-4-to-1-margin-tapjoy-research-finds/)) |
| Rewarded eCPM (US) | **Planning value:** $12–20 | Appodeal Q4 2024 |
| IAP share of revenue (US) | **Planning value:** 70–85% | Tier-1 IAP 77–90% ([Sensor Tower](https://gamedevreports.substack.com/p/sensor-tower-mobile-game-ad-monetization)) |
| ROAS D7 / D30 / payback | **Targets:** 20–35% / 50–70% / D90–D180 | Casual iOS D30 47% ([Liftoff](https://liftoff.ai/?p=34267)) |
| LTV (D180) vs. CPI | **Target:** ≥ 1.2× in a geo before scaling UA | [Game Developer](https://www.gamedeveloper.com/business/calculating-ltv-for-a-mobile-game-methods-for-different-stages) |
| Refund rate | **Target:** < 2% of transactions | Estimate |

### 2.6 Quality and trust

| KPI | Target |
|---|---|
| Crash-free users | **Target:** ≥ 99.5% (release blocker < 99.0%) |
| ANR rate (Android) | **Target:** < 0.47% (verify the current Play threshold) |
| Cold start p90 | **Target:** ≤ 2.5 s ([[08 Technical Architecture]] §8) |
| Store rating | **Target:** ≥ 4.5★ (BitLife Play ≈ 4.4★ from ~1.3M reviews) ([Google Play](https://play.google.com/store/apps/eventdetails/4831791308351315470)) |
| Purchase restore success | **Target:** ≥ 99.9% |
| Save-loss incidents | **Target:** 0 confirmed per release |
| Accessibility P0/P1 bugs in release | **Target:** 0 / ≤ 2 |
| Screen-reader user retention (D7, aggregate) | **Target:** within 2 pp of the overall D7 |
| AI report rate (if enabled) | **Target:** < 0.1% of AI texts shown. 100% triaged within 48 h |
| Support first response | **Target:** < 24 h |

---

## 3. Stage-gate criteria between phases

Each gate is a **go / iterate / stop** decision by the client and the leads, using the evidence pack named below. "Iterate" means a time-boxed extension with a re-estimate.

### Gate 1: Planning → Prototype (Nov 2026)
| Criterion | Go if |
|---|---|
| Scope, pillars, stack, rating target | Approved in writing ([[_Concept Brief]]) |
| Budget envelope | Phase 2 funded. Phase 3 range acknowledged |
| Name | Clearance started, with backups |
| Team | Tech lead + narrative lead confirmed |

### Gate 2: Prototype → MVP (Jan 2027)
| Criterion | Go | Iterate | Stop / pivot |
|---|---|---|---|
| Playtest "want to keep playing" (5-pt) | ≥ 4.0 avg | 3.5–4.0 | < 3.5 |
| Players who notice a callback unprompted | ≥ 70% | 50–70% | < 50% |
| Task success: "find and do X" via hub or command bar | ≥ 90% in < 10 s | 75–90% | < 75% |
| Screen-reader spike (hub, card, avatar) | Pass | Fix ≤ 2 engineer-weeks | Fails → **switch to Unity 6** |
| Engine tick (5,000 events, reference Android) | ≤ 50 ms p95 | ≤ 120 ms | > 120 ms with no fix path |
| Writer throughput (net events/writer-day) | ≥ 6 | 4–6 (add writers, re-budget) | < 4 (re-scope content) |
| Rating dry-run | 16+ / Mature 17+ | 18+ with clear fixes | — |

### Gate 3: MVP → Soft launch (May 2027)
| Criterion | Go if |
|---|---|
| Content | ≥ 1,500 approved events. Sim bot: dead events < 2%, repeats < 5%, ≥ 3 callbacks per life |
| Stability (closed beta, ≥ 500 testers) | Crash-free ≥ 99.5%. No P0 bugs |
| FTUE | ≥ 85% completion. First wild event < 60 s median |
| Monetization | Purchase, restore and refund pass on both stores. Remove-ads removes all ads |
| Compliance | All Phase 3 items in [[09 Compliance and Ratings]] §12 complete (age signals, CMP, DPIA, privacy docs, deletion, IAP ratings) |
| Analytics | Taxonomy validated end-to-end in BigQuery |

### Gate 4: Soft launch → Global launch (end Aug 2027)
Uses the soft-launch gates in [[10 Go-to-Market]] §3.3 (Tier-1 cohorts):

| Criterion | Go | Iterate (4–8 wk) | Stop / rethink |
|---|---|---|---|
| D1 / D7 / D30 | ≥ 38% / ≥ 11% / ≥ 4% | 30–38% / 7–11% / 2.5–4% | < 30% / < 7% / < 2.5% |
| ARPDAU / payer conversion | ≥ $0.20 / ≥ 2.5% | $0.12–0.20 / 1.5–2.5% | < $0.12 / < 1.5% |
| Recap share rate | ≥ 8% | 4–8% | < 4% |
| Crash-free / rating | ≥ 99.5% / ≥ 4.5★ | 99.0–99.5% / 4.2–4.5★ | < 99.0% / < 4.2★ |
| Content + loc + a11y | 3,000+ events, 5 languages LQA-passed, external audit passed | Slip the language launch | — |

### Gate 5: Launch → LiveOps steady state (launch + 90 days, Jan 2028)
| Criterion | Go (continue investment) | Iterate | Wind-down review |
|---|---|---|---|
| D30 retention (blended) | ≥ 4% | 2.5–4% | < 2.5% |
| WSP/MAU | ≥ 45% | 35–45% | < 35% |
| LTV (D180 projection) / blended CPI | ≥ 1.2× → scale UA | 0.8–1.2× → organic + optimise | < 0.8× → cut UA, re-scope |
| Monthly revenue vs. LiveOps run rate ([[11 Roadmap Team and Budget]] §4.6) | ≥ 1.0× by month 6 | 0.6–1.0× | < 0.6× at month 6 |
| Content cadence | Weekly challenge + monthly event + quarterly pack on schedule | One slip | Repeated slips |
