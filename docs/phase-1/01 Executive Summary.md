---
title: Executive Summary
project: Relivable
phase: 1
tags: [relivable, phase-1, executive-summary, client]
updated: 2026-10-26
---

# Relivable — Executive Summary

> [!note] Status and scope
> One-page client summary of the Phase 1 plan. Source of truth: [[_Concept Brief]]. Details sit in the linked notes. **Relivable** is a working title and needs a trademark and App Store name check before public use. Relivable is an original game *inspired by the text life-sim genre*. It is not affiliated with, endorsed by or derived from BitLife or Candywriter, and it will ship with no copied text, names, UI or assets.

## The opportunity
Text life sims are a proven, profitable mobile niche, and the category leader has no real challenger. BitLife launched in 2018. It has 50M+ Google Play installs and about 1.3M reviews averaging 4.4 ([Google Play](https://play.google.com/store/apps/eventdetails/4830152244864270285)). It brought Candywriter about $26M of revenue at a 59% EBIT margin in 2019 ([PocketGamer.biz](https://www.pocketgamer.biz/news/73190/stillfront-group-acquires-bitlife-developer-candywriter/)). Today it earns roughly SEK 95–110M (about US$9–11M) per quarter for Stillfront ([Stillfront Q2 2026](https://www.stillfront.com/en/stillfronts-interim-report-q2-2026-strengthened-profitability-and-continued-revenue-stability/)).

The leader is also mature and losing goodwill:
- Revenue fell 19% organically in each of Q1 and Q2 2026 when paid user acquisition was tightened, then stabilised at about -2% in Q3 2026 ([Yahoo Finance Q3 call](https://finance.yahoo.com/quote/SFS.XC/earnings/SFS.XC-Q3-2026-earnings_call-537398.html)).
- Since 2023, new systems arrive mainly as paid packs and Modes. The full catalogue now runs from a $20.99 Boss Mode down to a $0.99-per-use Time Machine ([App Store](https://apps.apple.com/app/1374403536)).
- Players' top complaints are intrusive ads, paywall creep, lost purchases and saves, repetitive events, and accessibility regressions ([[03 Player Research and Wishlist]]).

At the same time, the two big visual competitors have left. The Sims Mobile closed in January 2026, and Life by You was cancelled in 2024 ([SimsCommunity](https://simscommunity.info/2025/10/20/the-sims-mobile-shutting-down/)). See [[02 Market and Competitors]].

## The product
Relivable is a text-first life simulator for iOS and Android phones (tablets supported). It keeps everything players love about the genre: birth to death, a one-tap year, wild choices and generations. It is rebuilt around **memory, clarity, fairness and sharing**, and it reaches parity with every system players expect from a modern life sim, then adds the features they keep asking for. See [[04 App Breakdown - Core Life Systems]] and [[04 App Breakdown - Social, Meta and Premium]].

| Pillar | What the player feels | Proof point it answers |
|---|---|---|
| **1. Every choice remembered** | NPCs remember; consequences return years later; life chapters and traits | "Repetitive", "relies too heavily on random events" ([Mechanics of Magic](https://mechanicsofmagic.com/?p=5062)) |
| **2. One tap to anything** | Thumb-zone hub, contextual action cards, "What do you want to do?" search; locked actions explain why | Activities hidden across menus and failing silently ([AppleVis](https://applevis.com/comment/92232)) |
| **3. Fair forever** | All careers and core systems free; capped opt-in ads; no pay-per-use rewind; purchases restored on any device | Ads after paying for no-ads; lost packs after a phone change ([ComplaintsBoard](https://www.complaintsboard.com/bitlife-life-simulator-b150146)) |
| **4. Share your story** | Wrapped-style Life Recap cards, dynasty family tree, scenario seeds, weekly challenges | Spotify Wrapped 2025: 500M+ shares on day one ([RouteNote](https://routenote.com/blog/spotify-wrapped-2025-record-breaking-launch/)) |
| **5. Accessible by default** | Full VoiceOver/TalkBack, dynamic type, colour-blind safe, reduced motion | BitLife VoiceOver regressions and a 2022 player petition ([AppleVis](https://applevis.com/comment/134996)) |

## Why now
1. **The incumbent is exposed.** BitLife's growth depends on paid UA, and goodwill is low (petitions, a 2019 subscription test reversed after a "nearly unanimously negative" reaction ([Fandom wiki](https://bitlife-life-simulator.fandom.com/wiki/Bitizenship))).
2. **The visual players have gone.** The Sims Mobile and Life by You are gone, and EA's next title has no firm date.
3. **The technology is cheaper.** Data-driven storylets ship content without app updates. On-device AI (Apple Foundation Models) can add optional flavour text at no inference cost ([9to5Mac](https://9to5mac.com/2025/09/29/apple-intelligence-ios-26-models-developers/)).
4. **The platforms are cheaper.** US iOS external purchase links currently carry 0% Apple commission pending a court-set rate, and Google allows alternative billing from June 2026 ([iPhone in Canada](https://www.iphoneincanada.ca/2026/08/14/apple-proposes-15-cut-purchases-outside-app-store/); [MacRumors](https://macrumors.com/2026/06/24/google-play-store-fee-change/)).
5. **Regulation rewards fair design.** Loot-box rules (Belgium, Brazil, the coming EU Digital Fairness Act) and US app-store age laws favour transparent, non-random monetisation. See [[09 Compliance and Ratings]].

## Business model (headline)
Relivable is free to play, with no loot boxes and no pay-per-use undo. Revenue comes from:
- **Opt-in rewarded ads**, capped (4 per session, 8 per day, 90-second cooldown), never forced mid-story, none in the first life or for 7 days after a purchase.
- **Relivable Plus**, a one-time ~$9.99 unlock: no ads (ad rewards auto-granted), up to 8 generations (free: founder + 3 heirs), Destiny Mode editor, unlimited Rewind (free: 1 per life + 1 per day via ad). A $2.99 No Ads option upgrades to Plus for $6.99.
- An optional cosmetic and story **Season Pass**, ~$4.99.
- Small **Story Packs**, ~$2.99–3.99, that add storylines and never lock careers.
- Cosmetics ($1.99 Welcome Pack, $0.99–1.99 sets) and two bundles ($14.99 Founder's Bundle, $24.99 Complete Collection). The only soft currency, **Sparks**, is earn-only and never sold.

Life Simulator is among the top-earning hybrid-casual subgenres, with US Android ARPU of about $11–15 in Appodeal's 2025 benchmark ([gameindustrylibrary](https://gameindustrylibrary.com/documents/mobile-casual-benchmarks-report-2025)). See [[06 Monetization and Economy]].

## Budget and timeline (headline, *estimates, not quotes*)

| Phase | Duration | Budget estimate | Exit criterion |
|---|---|---|---|
| 2 – Prototype | 8 weeks (9 Nov 2026 – 8 Jan 2027) | ~$25–60K | Vertical slice (birth to age 30), 150 events, redesigned hub, playtests |
| 3 – MVP and soft launch | ~5 months; soft launch from 17 May 2027 (Philippines, then Ireland/Netherlands, Canada optional) | MVP labour ~$60–210K (US-team reference ~$385K) | 1,500+ events, monetisation and analytics live, soft-launch KPIs read |
| 4 – Global launch | Target 12 Oct 2027 (~11 months from start; range 9–14) | Total to global launch ≈ $505K (low) – $1.03M (high); US team ≈ $1.43–1.62M | Parity plus "better" features, 5 languages |
| 5 – LiveOps | Ongoing | Run-rate, set at launch | Seasons, Story Packs, async social, Creator Mode |

> [!warning] Not included
> These figures exclude user-acquisition spend, which for mobile often exceeds development cost. **Writing, not engineering, is the critical path.** See [[11 Roadmap Team and Budget]].

## The ask
1. **Approve Phase 2.** A 8-week prototype for ~$25–60K (estimate), with go/no-go playtest gates.
2. **Confirm three decisions.**
   - Age-rating stance: target Apple 16+ / Google Mature 17+, or fund a softened teen mode.
   - Team model: hybrid/offshore or US.
   - Start the trademark and name search for "Relivable".
3. **Open community channels now.** An official Discord and a creator shortlist ahead of soft launch. See [[10 Go-to-Market]].

## Key KPI targets (*targets and estimates, to validate in soft launch*)

| KPI | Target | Benchmark reference |
|---|---|---|
| D1 / D7 / D30 retention | 40% / 13% / 5% (soft-launch gates 35% / 10% / 3.5%) | GameAnalytics 2026: median 22% / ~4% / <1%; top 10% ~40% / 11–12% / ~4% ([gamedevreports](https://gamedevreports.substack.com/p/gameanalytics-mobile-and-pc-game)) |
| ARPDAU | ~$0.07 blended global base case; ≥ $0.20 Tier-1 | Hybrid-casual range ([Juego Studio](https://www.juegostudio.com/blog/arpdau-benchmarks-by-game-genre), vendor) |
| Payer conversion | 2–4% | ~3.5% of mobile gamers spend ([PocketGamer.biz / AppsFlyer](https://www.pocketgamer.biz/comment-and-opinion/64530/best-practices-for-implementing-iap-starter-packs-in-free-to-play-games/entry/1/)) |
| D30 ROAS / payback | 50–70% / D90–D180 | Casual iOS D30 ROAS average 47% ([Liftoff](https://liftoff.ai/?p=34267)) |
| Accessibility | 100% of interactive elements screen-reader labelled; a11y QA as a release gate | Internal target |
| Trust | Zero "paid but still saw ads" defects; purchase restore on any device | Internal target |

Full KPI tree and risk register: [[12 Risks and KPIs]]. Pitch talk track and client FAQ: [[13 Client Pitch Script and FAQ]]. Vault index: [[00 Home]].
