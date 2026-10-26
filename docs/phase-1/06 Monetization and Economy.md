---
title: Monetization and Economy
project: EverLife
phase: 1
status: draft
tags: [everlife, phase-1, monetization, economy, pricing, ads, revenue-model, regulation]
updated: 2026-10-26
---

# 06 Monetization and Economy

> [!summary] In one paragraph
> EverLife is **free to play with no paywalled systems**. Every career, life stage and core system is free. Revenue comes from four honest sources: (1) **EverLife Plus**, a one-time ~$9.99 unlock (no ads, unlimited generations, Destiny Mode editor, unlimited Rewind); (2) **Story Packs** at $2.99–3.99 that add storylines but never lock careers; (3) an optional **Season Pass** at $4.99 (cosmetics + story chapters); (4) **opt-in rewarded ads**, frequency-capped. Small cosmetic packs and an optional web shop round it out. There are **no loot boxes, no premium currency, no pay-per-use undo, no interstitials and no subscriptions at launch**. Our base-case estimate is blended ARPDAU of about **$0.066**, below the hybrid-casual benchmark of $0.15–0.50 ([Juego Studio](https://www.juegostudio.com/blog/arpdau-benchmarks-by-game-genre), vendor blog). That gap is deliberate: we trade short-term ARPDAU for retention, reviews and organic sharing. Soft launch must test whether that trade pays off. Source of truth: [[_Concept Brief]] pillar 3 and the locked monetisation decision.

Related: [[00 Home]] · [[05 UX and Screen Map]] (Shop S70, Plus S71, ad modal S72) · [[07 Retention and LiveOps]] (season cadence, A/B tests) · [[08 Technical Architecture]] (RevenueCat, server validation) · [[09 Compliance and Ratings]] · [[10 Go-to-Market]] (UA economics) · [[12 Risks and KPIs]].

> [!warning] All numbers here are estimates
> The benchmarks come from search-result snippets of vendor and industry reports (page fetching was blocked during research). Every revenue figure in §6 is a **planning estimate, not a forecast**. It must be re-based on soft-launch data ([[10 Go-to-Market]]).

---

## 1. Business model

| Layer | What | Who it serves | Share of revenue (base case est.) |
|---|---|---|---|
| **One-time premium** | EverLife Plus $9.99 (+ No-Ads $2.99 entry) | Committed players who want everything without ads | ~35% |
| **Content** | Story Packs $2.99–3.99, released about every 2 months | Players who want *more stories*, not more power | ~15% |
| **Seasonal** | Season Pass $4.99 per quarter (non-renewing) | Engaged weekly players | ~5% |
| **Cosmetic** | Avatar, home, recap themes $0.99–1.99, Welcome Pack $1.99 | Expressive players and sharers | ~2% |
| **Ads** | Opt-in rewarded video only, capped | Non-payers (~97% of players) | ~43% |

Why hybrid: it is now the default. 72% of developers are adopting it ([AdInMo](https://www.adinmo.com/72-of-mobile-games-makers-adopting-hybrid-monetization-model)). Life Simulator is one of the top hybrid-casual subgenres, with US Android ARPU of $11.08–14.83 ([Appodeal via gameindustrylibrary](https://gameindustrylibrary.com/documents/mobile-casual-benchmarks-report-2025)). Only about 2–3.5% of players pay ([PocketGamer.biz/AppsFlyer](https://www.pocketgamer.biz/comment-and-opinion/64530/best-practices-for-implementing-iap-starter-packs-in-free-to-play-games/entry/1/)), so ads have to carry the non-payers. BitLife itself made more than **62% of revenue from ads** in 2019 ([Stillfront PDF](https://www.stillfront.com/en/wp-content/uploads/sites/2/2020/04/stillfront-stillfront-group-acquires-candywriter-llc-and-discloses-updated-pro-forma-figures-for-2-200423.pdf)). We expect a lower ad share because our ads are opt-in only. In Tier-1 markets IAP is usually 77–90% of revenue ([Sensor Tower via gamedevreports](https://gamedevreports.substack.com/p/sensor-tower-mobile-game-ad-monetization)).

**Positioning promise (store copy):** *"Every career free. One-time unlock, no subscriptions. Ads only when you choose. Your lives and purchases follow you to any device."* Each clause answers a top BitLife complaint ([reddit_player_wishlist research](../../research_notes/Life%20sim%20game%20phase%201/reddit_player_wishlist.md)).

---

## 2. Product catalogue

| # | Item | Price (USD, tier) | Contents (shown to the player in full before purchase) | Type | Platform |
|---|---|---|---|---|---|
| P1 | **EverLife Plus** | **$9.99** | Removes **all** ads, including banners, ad-gated perks and future ad placements. Rewarded-ad perks are granted automatically. Unlimited generations (free tier: up to Generation 4 per dynasty, i.e. founder + 3 heirs; unlimited dynasties). **Destiny Mode** editor tools (edit your own and NPC stats and appearance any time, reveal hidden stats and facets). **Unlimited Rewind** (free: 1 per life + 1 per day via opt-in rewarded ad). 10 save slots (free: 3). Plus badge on the recap card. | Non-consumable | iOS, Android, web |
| P2 | **No Ads** | $2.99 | Removes all ads and auto-grants ad perks. Nothing else. | Non-consumable | iOS, Android, web |
| P3 | **Plus Upgrade** (shown only to No-Ads owners) | $6.99 | Everything else in Plus. Total paid = $9.98, never more than Plus | Non-consumable | iOS, Android, web |
| P4 | **Story Pack** (e.g. *Spotlight*: film and stage fame; *Night Shift*: hospital drama; *Old Money*: aristocratic family saga; *Frontier 1850*: era start; *The Uncanny*: light supernatural) | **$2.99** (small, ~60 storylets) / **$3.99** (large, ~120 storylets + 1 new scenario start) | New storylines, characters, scenario starts and Milestones. **Never** a career, a system, or a stat edge that free players lack. Careers referenced in packs exist in the base game | Non-consumable | iOS, Android, web |
| P5 | **Season Pass** | **$4.99** per season (≈13 weeks) | Premium track: ~30 cosmetic rewards (avatar outfits, home decor, recap themes, family crest parts) + 2 bonus story chapters. **Free track** for everyone: ~20 rewards + the main season storyline. The full reward list is shown up front. Completable with ~4 sessions/week. Items are kept forever | Non-consumable per season (non-renewing) | iOS, Android, web |
| P6 | **Welcome Pack** | $1.99 (once per account) | Avatar outfit set (5), 3 recap card themes, family crest starter. Cosmetic only | Non-consumable | iOS, Android |
| P7 | **Cosmetic sets** | $0.99–1.99 | One themed set (outfits, decor or recap theme) | Non-consumable | iOS, Android, web |
| P8 | **Founder's Bundle** (launch window, 60 days) | $14.99 | Plus + 2 large Story Packs (value $17.97) + exclusive founder crest | Non-consumable | iOS, Android, web |
| P9 | **Complete Collection** (evergreen anchor) | $24.99 | Plus + all currently released Story Packs (value shown) | Non-consumable bundle | iOS, Android, web |
| – | **Not sold:** careers, life stages, dark mode, accessibility, per-use Rewind, extra event rerolls, stat boosts, premium currency, random rewards, subscriptions (at launch) | – | – | – | – |

> [!note] Future option (not at launch): "EverLife Club"
> A $2.99/month or $19.99/year cosmetic-only membership (monthly cosmetic drop + Season Pass included) could be tested in year 2. Subscriptions inside games grew from 4% to 7% of revenue in three-model games, Jan 2025 to early 2026 ([gamedevreports](https://gamedevreports.substack.com/p/weekly-gaming-reports-recap-june-e95)). We will **not** gate gameplay behind it. Candywriter's 2019 test of a Bitizenship subscription in CA/AU drew a "nearly unanimously negative" reaction and was dropped ([BitLife Wiki](https://bitlife-life-simulator.fandom.com/wiki/Bitizenship)). The brief positions us as "no subscriptions" at launch.

**Regional pricing:** use the store price tiers with purchasing-power adjustment (e.g. Philippines Plus ≈ PHP 249, Brazil ≈ BRL 29.90). Prices are tested in soft launch through remote-config offerings (RevenueCat Offerings; see [[08 Technical Architecture]]).

**Entitlements:** every purchase is tied to the EverLife account (anonymous-first, linkable to Apple/Google/email) and validated server-side (StoreKit 2 JWS / Play Developer API through RevenueCat). Ownership syncs across iOS, Android and web. **Restore Purchases** is always visible in Shop and Settings. Lost purchases are a top BitLife complaint ([Google Play review](https://play.google.com/store/apps/eventdetails/4831791308351315470)).

---

## 3. Price ladder rationale

```
$0 ── free full game (all careers & systems), opt-in ads
$0.99–1.99 ── cosmetic sets / Welcome Pack  ← first-spend door, cosmetic only
$2.99 ── No Ads / small Story Pack          ← "supporter" price, matches BitLife Remove Ads $2.99
$3.99 ── large Story Pack
$4.99 ── Season Pass                         ← impulse, recurring per quarter
$9.99 ── EverLife Plus                       ← core unlock; under BitLife's $15.99 Bitizenship+God Mode bundle
$14.99 ── Founder's Bundle (launch)          ← decoy/anchor that makes Plus+packs feel complete
$24.99 ── Complete Collection                ← top anchor; still < BitLife "own everything" (≈$80+ est.)
```

| Decision | Rationale | Evidence |
|---|---|---|
| Plus at **$9.99** covers what BitLife splits into Bitizenship ($7.99) + God Mode ($9.99) + per-use Time Machine ($0.99/use) | "One fair unlock" is the core marketing claim. $9.99 sits inside the typical $4.99–9.99 core-unlock band and undercuts BitLife's $15.99 bundle | BitLife prices: [App Store](https://apps.apple.com/app/bitlife/id1374403536); ladder inference in [monetization research §3](../../research_notes/Life%20sim%20game%20phase%201/monetization_retention.md) |
| $2.99 No Ads + $6.99 upgrade | Low first-spend door with no "double-pay" penalty. The first purchase shapes later spending | [PocketGamer.biz](https://www.pocketgamer.biz/comment-and-opinion/64530/best-practices-for-implementing-iap-starter-packs-in-free-to-play-games/entry/1/) |
| Welcome Pack $1.99, not $0.99 | Deconstructor of Fun warns that very low starter prices set a weak spending anchor. 59.2% of developers price under $5 | [Deconstructor of Fun](https://www.deconstructoroffun.com/blog/2024/4/8/free-to-play-starter-pack-pricing-when-conversion-is-king-we-may-price-too-low) |
| Welcome Pack offered after the first life ends, not at first spawn | Roblox guidance says early is better (packs add 2–10% revenue), but we put FTUE trust first. **A/B test** against offering it at age 18 in life 1 | [Roblox Creator Docs](https://create.roblox.com/docs/production/game-design/starter-pack-design) |
| Story Packs $2.99/$3.99, below BitLife's $7.99 packs | More, smaller packs at a lower price lower the barrier, and storylines without career locks avoid the "paywall creep" backlash | BitLife pack prices: [BitLife feature guide](../../reports/BitLife%20complete%20feature%20guide.md); paywall complaints: [Art Sherpa](https://theartsherpa.com/classroomelse/blog) |
| $14.99 / $24.99 bundles | A bundle as "best value" anchor makes Plus look reasonable. BitLife uses a $15.99 bundle as a decoy | [App Store](https://apps.apple.com/app/bitlife/id1374403536) |
| No weekly or monthly subscription at launch | Weekly app subs average about $8.1 in the US (all apps), which casual players are likely to see as predatory | [Adapty](https://adapty.io/reports/state-of-in-app-subscriptions-2025/) |

---

## 4. Ad policy

> [!important] Rules (non-negotiable, enforced in code and remote config)
> 1. **Opt-in rewarded video only.** No interstitials, no app-open ads, no auto-playing video. **No banners at launch**; a single bottom banner on the Wealth tab only is a possible A/B test, and only if retention guardrails hold.
> 2. **Never after an action.** No ad plays as a consequence of tapping an action, finishing a year, dying or closing a card. Ads play only after the player taps a button labelled "▶ Watch ad: [exact reward]".
> 3. **Never after a purchase.** Any purchase (even $0.99) suppresses all ad *offers* for 7 days. No-Ads and Plus suppress them permanently and grant the perks automatically.
> 4. **Caps:** max **4 rewarded views per session**, **8 per day**, with a **90 s cooldown** between views. The remaining count is shown on every offer ("3 of 8 left today"). No ad offers appear inside a story (storylet, event card, death flow, recap) or an activity; they appear only on the hub between years or on reward screens.
> 5. **Equal-weight decline.** The "No thanks" button is the same size, in the thumb zone, and labelled for screen readers. There are no hidden close buttons; an academic paper documents games putting ad close controls in unreachable zones ([CMS Conferences](https://openaccess.cms-conferences.org/publications/book/978-1-964867-13-7/article/978-1-964867-13-7_13)).
> 6. **Content:** ad networks run with age-appropriate settings. No ads for under-16 or unknown-age users that use behavioural targeting (contextual only). Gambling, dating and alcohol ad categories are blocked. See [[09 Compliance and Ratings]].
> 7. **No ads in the FTUE:** none during the first life (no offers before the first death).

**Rewarded placements (what an ad can give):**

| Placement | Reward | Cap | Notes |
|---|---|---|---|
| Extra Rewind | +1 Rewind | 1/day | Free players get 1 Rewind per life without an ad. Rewind is never sold per use; Plus is unlimited |
| Second opinion | Reveal the odds band and hidden factors of one risky choice (heist, surgery, lawsuit) | 3/day | Information, not outcome manipulation |
| Lucky break | Retry one *failed* non-death minor action (e.g. job interview) | 2/day | Never undoes a death |
| Sparks bonus | +50 Sparks (soft currency, §5) | 3/day | – |
| Season boost | +1 tier of free Season track progress | 1/day | – |
| Daily goal reroll | Replace one daily goal | 1/day | – |

Why rewarded only: player surveys show 76% of US gamers prefer opt-in rewarded ads to mandatory ads (Tapjoy 2017), and 46% prefer rewarded video against 5% for interstitials (Unity 2015). Both are dated vendor surveys ([MarketingDive](https://www.marketingdive.com/press-release/20170613-mobile-gamers-prefer-rewarded-ads-by-4-to-1-margin-tapjoy-research-finds/), [GamesBeat](https://gamesbeat.com/unity-the-majority-of-mobile-gamers-are-open-to-engaging-with-incentivized-video-ads/)). Ad frequency is the top complaint against BitLife and 100 Years ([Google Play](https://play.google.com/store/apps/eventdetails/4831791308351315470), [Marlvel](https://marlvel.ai/api/llm/apps/games/100-years-life-simulator)).

**Stack:** AdMob or AppLovin MAX mediation (AppLovin and AdMob took 65% of ad revenue, May 2026, [Sensor Tower via gamedevreports](https://gamedevreports.substack.com/p/sensor-tower-mobile-game-ad-monetization)), with a consent management platform (CMP) for GDPR and US state privacy laws.

---

## 5. In-game soft currency: **Sparks** (earn-only)

> [!info] Design decision
> EverLife has **one soft currency, Sparks, which cannot be bought with real money** and has no premium currency. That keeps prices in real money (ahead of the EU Digital Fairness Act's expected virtual-currency price-display rules, [Freshfields](https://technologyquotient.freshfields.com/post/102ltio/the-eus-proposed-digital-fairness-act-a-game-developers-guide-to-potential-imp)) and removes any "buy currency → gamble/convert" path. In-life money (the character's $ cash) is a **simulation value only** and is never sold either.
>
> **Legacy Points (LP)** are a separate, dynasty-scoped progression track defined in [[04 App Breakdown - Social, Meta and Premium]] §4. LP are earned only and buy small dynasty perks. Sparks are account-wide and cosmetic. Neither can be bought, and they do not convert into each other.

| Sources (per active day, est.) | Sparks | Sinks | Cost (Sparks) |
|---|---|---|---|
| 3 daily goals | 3 × 20 = 60 | Unlock a past weekly challenge from the **Challenge Archive** (BitLife charges ~$4.99 for its vault) | 300 |
| Finish a life | 50 + 10 per Milestone earned | Cosmetic outfit (earnable rotation, 1 of 4 weekly) | 400–800 |
| Weekly challenge complete | 200 | Home decor item | 150–500 |
| Life Title (end-of-life title) first earn | 100 | Recap card theme | 250 |
| Streak milestones (7/30/100 days) | 100 / 300 / 1,000 | **Streak freeze** (bank up to 2) | 200 |
| Season free track | ~1,500 per season | Extra save slot (up to 5 for free players) | 1,000 |
| Rewarded ad (opt-in) | 50 (max 3/day) | Family crest parts | 100–300 |
| | | Heirloom rename / engrave | 50 |

**Economy targets (est., tuned through remote config):** a free daily player earns about 150–250 Sparks/day, so they can buy one cosmetic every 3–5 days and one archived challenge each week. Sink-to-source ratio is about 0.8–0.9, to avoid inflation, with seasonal cosmetics as the main sink. Sparks never buy story content, careers, Rewinds, stat edges or anything sold for real money (no "pay or grind" for the same item). Balance is reviewed monthly using an analytics dashboard of earn/spend per cohort ([[12 Risks and KPIs]]).

---

## 6. Revenue model (3 scenarios, estimates)

### 6.1 Formulas

```
Ad ARPDAU       = ad_engaged_share × views_per_engaged_user_per_day × eCPM / 1000
IAP gross / mo  = MAU × monthly_payer_conversion × monthly_ARPPU
IAP ARPDAU      = IAP gross / mo ÷ (DAU × 30)
Blended ARPDAU  = Ad ARPDAU + IAP ARPDAU
Gross / mo      = DAU × 30 × Blended ARPDAU
Net / mo        = Ad revenue (already net of network share) + IAP gross × (1 − blended_store_fee) − RevenueCat 1% of tracked revenue above $2.5K/mo
MAU             = DAU ÷ stickiness (DAU/MAU)
LTV (naive)     = Blended ARPDAU × expected lifetime active days
```
The naive LTV method is for pre-launch; a retention-curve fit replaces it in soft launch ([Game Developer](https://www.gamedeveloper.com/business/calculating-ltv-for-a-mobile-game-methods-for-different-stages)).

### 6.2 Inputs

| Input | Conservative | Base | Optimistic | Benchmark anchor |
|---|---|---|---|---|
| Average DAU (year 1 post global launch) | 30,000 | 120,000 | 400,000 | BitLife US WAU 1.0–1.4M (Q2 2025, [Sensor Tower](https://sensortower.com/blog/2025-q2-unified-top-5-simulator%20games-revenue-us-60416e41241bc16eb8905c2f)) |
| Stickiness DAU/MAU | 20% | 22% | 25% | assumption |
| MAU | 150,000 | ≈545,000 | 1,600,000 | derived |
| Share of DAU watching ≥1 rewarded ad | 40% | 50% | 60% | Tapjoy: 51% would watch 4+/day ([MarketingDive](https://www.marketingdive.com/press-release/20170613-mobile-gamers-prefer-rewarded-ads-by-4-to-1-margin-tapjoy-research-finds/)) |
| Views per engaged user per day (cap 8) | 3 | 4 | 5 | assumption under cap |
| Blended rewarded eCPM (geo mix) | $12 | $14 | $18 | US rewarded: iOS $19.63, Android $16.49 (Q4 2024, [Appodeal](https://appodeal.com/the-mobile-ecpm-report-updated-q4-2024-view)); about $12–15 average with 5–10% YoY decline ([Applixir](https://www.applixir.com/?p=3237)) |
| Monthly payer conversion (of MAU) | 1.5% | 2.5% | 4.0% | 3.5% of gamers spend ([AppsFlyer via PocketGamer.biz](https://www.pocketgamer.biz/comment-and-opinion/64530/best-practices-for-implementing-iap-starter-packs-in-free-to-play-games/entry/1/)); 1.96–2.38% casual ([wnhub](https://wnhub.io/news/marketing/item-12861)) |
| Monthly ARPPU | $8 | $10 | $14 | Casual D90 ARPPU $7.26 ([gamedevreports](https://gamedevreports.substack.com/p/weekly-gaming-reports-recap-june-e95)) |
| Blended store fee on IAP | 15% | 20% | 25% | §7 |

### 6.3 Outputs (estimates)

| Output | Conservative | Base | Optimistic |
|---|---|---|---|
| Ad ARPDAU | 0.40 × 3 × $12 / 1000 = **$0.0144** | 0.50 × 4 × $14 / 1000 = **$0.0280** | 0.60 × 5 × $18 / 1000 = **$0.0540** |
| IAP gross / month | 150,000 × 1.5% × $8 = **$18,000** | 545,000 × 2.5% × $10 = **$136,250** | 1,600,000 × 4% × $14 = **$896,000** |
| IAP ARPDAU | $18,000 ÷ 900,000 = **$0.0200** | $136,250 ÷ 3.6M = **$0.0378** | $896,000 ÷ 12M = **$0.0747** |
| **Blended ARPDAU** | **$0.034** | **$0.066** | **$0.129** |
| Ad revenue / month | $12,960 | $100,800 | $648,000 |
| Gross / month | $30,960 | $237,050 | $1,544,000 |
| IAP : Ads split | 58 : 42 | 57 : 43 | 58 : 42 |
| **Gross / year** | **≈ $0.37M** | **≈ $2.84M** | **≈ $18.5M** |
| Net / month (after store fees) | $12,960 + $15,300 = $28,260 | $100,800 + $109,000 = $209,800 | $648,000 + $672,000 = $1,320,000 |
| **Net / year (before RevenueCat 1%, tax, UA)** | **≈ $0.34M** | **≈ $2.52M** | **≈ $15.8M** |

> [!caution] Reading the scenarios
> - **Base ARPDAU ($0.066) is below the hybrid-casual range of $0.15–0.50** ([Juego Studio](https://www.juegostudio.com/blog/arpdau-benchmarks-by-game-genre), vendor) and the $0.15–0.40 planning range in our research. This is the cost of no interstitials, no consumables and a one-time unlock. Plus revenue is also **front-loaded**: ARPPU falls as long-tenure payers saturate, which is why packs and seasons matter.
> - The optimistic case (≈$18.5M/yr gross) is roughly BitLife-scale for the **US alone**. BitLife's US weekly revenue ran about $263K–497K in H1 2025 ([Sensor Tower](https://sensortower.com/blog/2025-q2-unified-top-5-simulator%20games-revenue-us-60416e41241bc16eb8905c2f)), or about $14–26M/yr annualised (est.).
> - **Naive LTV (base):** with D1/D7/D30 of 40/12/5% we estimate about 8–10 lifetime days by D180 (research inference), so LTV ≈ $0.066 × 9 ≈ **$0.60**. Casual CPI is $1.41 on iOS and $0.14 on Android globally ([Liftoff](https://liftoff.ai/?p=34267)), and about $2–3 for North American iOS ([Segwise](https://segwise.ai/blog/cpi-ipm-roas-benchmarks-optimizing-ad-spend/), secondary). **Paid UA in Tier-1 iOS does not pay back at base ARPDAU.** Growth must be organic and creator-led (Life Recap sharing, seeds, creators; see [[10 Go-to-Market]]), with paid UA only in cheap Android geos or for retargeting until soft-launch LTV beats CPI.
> - **Levers if soft launch underperforms** (each is A/B tested, never all at once): Plus price $9.99 vs $12.99; Welcome Pack timing; ad cap 8 vs 10/day; a 7-day Plus trial via rewarded ads; Story Pack cadence; the opt-in Wealth-tab banner test. Interstitials and consumable power items are **excluded** (§9).

---

## 7. Platform fees (status as of Oct 2026)

| Channel | Fee on digital goods | Notes / source |
|---|---|---|
| **Apple App Store IAP (worldwide default)** | 30%, or **15% under the Small Business Program** (< $1M prior-year proceeds) | Small Business Program terms from general knowledge; verify at contract time |
| **Apple US link-out to web shop** | **0%** for now (court order) — Apple proposed **15%** (10% partner, 5% small business) in Aug 2026; Supreme Court granted cert 2 Jul 2026 | [iClarified](https://www.iclarified.com/101778/apple-seeks-court-approval-for-15-commission-on-external-app-purchases); [iPhone in Canada](https://www.iphoneincanada.ca/2026/08/14/apple-proposes-15-cut-purchases-outside-app-store/); [Courthouse News](https://courthousenews.com/apples-fight-over-commissions-for-linked-out-app-store-purchases-continues-in-federal-court/) |
| **Apple EU (DMA terms from 1 Oct 2026)** | IAP **26%** (15% small business); alternative payment processor **20%**; link-out **15%**; Core Technology Commission **5%** for alternative distribution | [MacRumors](https://macrumors.com/2026/08/19/ec-epic-apple-app-store-changes); [Phiture](https://phiture.com/blog/apple-new-app-store-terms-2026/) |
| **Google Play Billing** | Historically 15% on the first $1M/yr, then 30% (general knowledge). Under the Epic settlement, from **30 Jun 2026** (US, UK, EEA): alternative billing and web link-outs allowed; reported **10% on the first $1M and on auto-renewing subs**, an overall **10–25%** range, plus a billing fee for Play Billing. Final rate cards were due 30 Sep 2026; sources are inconsistent | [MacRumors](https://macrumors.com/2026/06/24/google-play-store-fee-change/); [Neon](https://www.neonpay.com/blog/google-plays-new-u.s.-billing-linking-policies-what-game-developers-need-to-know) |
| Google "Games Level Up" | Reduced rate cards for games meeting quality and engagement criteria | [Notebookcheck](https://www.notebookcheck.net/Google-cuts-Play-Store-fees-as-Epic-settlement-reshapes-Android-app-payments.1243278.0.html) |
| **Web shop (D2C)** | Payment processing + merchant-of-record ≈ **5–10%** (est.); real net savings typically **10–20 percentage points** vs store after payments, fraud, tax and overhead | [Xsolla Report Vol. 10](https://xsolla.com/blog/the-xsolla-report-vol-10-2026-d2c-is-reshaping-monetization) (vendor); D2C ≈ 15% of mobile IAP in 2025 ([FoxData](https://foxdata.com/en/blogs/mobile-game-d2c-revenues-hit-17-billion-why-publishers-are-pushing-beyond-app-stores/)) |
| RevenueCat | Free to $2.5K monthly tracked revenue, then **1%** | [RevenueCat pricing](https://www-docs.revenuecat.com/pricing) |

**Web shop plan:** launch in **Phase 4** for the US (and the EU where link-out terms make sense). Web prices **match** store prices and add a small cosmetic bonus; we do not discount, so we avoid store-policy and fairness friction. The web shop sells Plus, packs and seasons only. Purchases grant entitlements to the same account. IAP stays the default button; the web shop is a secondary "Also available on the web" link in the US. It suits repeat buyers (seasons, packs) more than impulse first purchases ([monetization research §2](../../research_notes/Life%20sim%20game%20phase%201/monetization_retention.md)).

---

## 8. Regulation

| Topic | Status (Oct 2026) | Our position |
|---|---|---|
| **Loot boxes** | Belgium treats paid loot boxes as gambling ([Promise Legal](https://blog.promise.legal/loot-box-laws-by-jurisdiction-indie-game-studios/)). Brazil's ECA Digital bans loot-box sales to minors from ~March 2026, with fines up to 10% of revenue ([Programming Insider](https://programminginsider.com/loot-boxes-regulation-and-where-the-line-sits-in-2026/)). UK: not gambling, ASA disclosure enforcement ([Promise Legal 2026](https://blog.promise.legal/lootbox-regulation-2026-game-studios/)) | **We have none.** No paid randomised rewards of any kind. Season and pack contents are fixed and listed. In-life casino and lottery are **simulated with fictional money only, no cash-out, nothing purchasable**. This is declared as "simulated gambling" in ratings ([[09 Compliance and Ratings]]) |
| **EU Digital Fairness Act** | Proposal scheduled for **Q4 2026** (reportedly November, unconfirmed). Discussed: real-money price display for virtual currency, loot-box restrictions, child-protective defaults. The 2024 Fitness Check flagged pay-to-win, obscured-cost currencies, opaque personalised offers and engagement-maximising design ([Freshfields](https://technologyquotient.freshfields.com/post/102ltio/the-eus-proposed-digital-fairness-act-a-game-developers-guide-to-potential-imp), [Slaughter and May](https://thelens.slaughterandmay.com/post/102kxp5/digital-fairness-act-european-commission-launches-consultation-and-call-for-evid)). A loot-box ban is not expected before 2028 ([WN Hub](https://wnhub.io/news/legal/item-48938)). The CPC network launched an action against nine game companies in Oct 2026 ([Lewis Silkin](https://www.lewissilkin.com/insights/2026/10/15/eu-consumer-protection-network-launches-action-involving-nine-video-games-compani-102o5do)) | Already compliant by design: all prices in real money, no purchasable currency, no personalised dynamic pricing, no fake timers, no pay-to-win. We will track the draft and run a compliance review on publication |
| **FTC (US)** | Jan 2025: $20M Genshin Impact settlement over misleading loot-box odds and costs and COPPA violations; terms include blocking under-16 purchases without parental consent ([VGC](https://www.videogameschronicle.com/news/genshin-impact-maker-fined-20m-over-deceptive-loot-boxes-and-child-privacy-violation)) | Exact content lists, no odds needed (no randomness), honest "what's included / not included", no dark patterns in purchase or cancel flows. Use the store's parental-consent and age-signal APIs for minors |
| **COPPA (amended rule)** | Compliance date 22 Apr 2026: separate consent for third-party disclosure such as ads, plus a data-retention policy ([Federal Register](https://www.federalregister.gov/documents/2025/04/22/2025-05904/childrens-online-privacy-protection-rule)) | Under-13s are blocked at the age gate. No behavioural ads for unknown or under-16 users |
| **US app-store accountability laws** (TX, UT, LA) | Developers must age-rate apps **and IAPs** and use store age and consent signals ([Pillsbury](https://www.pillsburylaw.com/en/news-and-insights/app-store-accountability-act-texas.html), [Stoel Rives](https://www.stoel.com/insights/publications/utahs-app-store-accountability-act-goes-into-effect)) | Every SKU is rated in the catalogue; purchases by minor-band users require store parental consent |
| **Apple Guideline 2.5.19** (Oct 2026, secondary coverage) | Bans hidden, dormant or undocumented features that differ from the reviewed build ([letsdatascience](https://letsdatascience.com/news/apple-revises-app-review-guidelines-for-ai-deepfakes-and-hid-76fdff63)) | Remote-config offers and prices are documented in review notes. Storylet packs are content, not new features. Season mechanics ship in the reviewed binary |
| **European Accessibility Act** | Applies from 28 Jun 2025 to e-commerce services; one view is that IAPs bring an app into scope ([Travers Smith](https://www.traverssmith.com/knowledge/knowledge-container/a-new-milestone-for-accessibility-the-european-accessibility-act-now-applies/)) | The shop and purchase flows meet the accessibility spec in [[05 UX and Screen Map]] §8 |

---

## 9. Anti-patterns we refuse

| # | Anti-pattern | Who does it / evidence | Our rule |
|---|---|---|---|
| 1 | Interstitial or forced ads after actions | BitLife: "40 second ad" after gifts and music lessons ([Google Play](https://play.google.com/store/apps/eventdetails/4831791308351315470)) | Rewarded opt-in only (§4) |
| 2 | "Remove ads" that doesn't remove all ads | BitLife no-ads buyers still saw ads ([ComplaintsBoard](https://www.complaintsboard.com/bitlife-life-simulator-b150146)) | No-Ads/Plus remove every surface and auto-grant perks |
| 3 | Paywalled careers and systems ("paywall creep") | Boss Mode job packs, $7.99 expansion packs ([BitLife Zendesk](https://bitlife.zendesk.com/hc/en-us/articles/5165069804948-What-is-Boss-Mode)) | All careers and systems free forever. Packs add stories only |
| 4 | Pay-per-use undo | Time Machine $0.99/use ([BitLife feature guide](../../reports/BitLife%20complete%20feature%20guide.md)) | 1 free Rewind per life + 1 per day via opt-in rewarded ad; unlimited with one-time Plus; never sold per use |
| 5 | Paid dark mode or accessibility | Bitizenship includes dark mode ([Pro Game Guides](https://progameguides.com/bitlife/bitlife-bitizen/)) | Free |
| 6 | Paywalled generations with surprise caps | Non-Bitizens can continue only once ([BitLife Wiki](https://bitlife-life-simulator.fandom.com/wiki/Generations)) | Free tier runs to Generation 4 (founder + 3 heirs), with the cap shown on the Heir screen from generation 1; at the cap the dynasty is saved, never deleted |
| 7 | "Future content included" promises later broken | Boss Mode did not cover later packs and Modes ([Gnostalgic](https://www.gnostalgic.org/bitlife.php)) | We never sell "all future content". Plus lists exactly what it includes, and that list only grows |
| 8 | Loot boxes, gacha, random paid rewards | FTC Genshin settlement | None |
| 9 | Premium currency that hides real prices | DFA Fitness Check | No purchasable currency; real prices everywhere |
| 10 | Fake urgency, countdown offers, FOMO pop-ups | Common in casual LiveOps | Offers have real end dates only (season end), shown calmly, never as a modal |
| 11 | Personalised "whale" pricing or spend-based dynamic offers | DFA concern | Same price for everyone in a region |
| 12 | Hidden or unreachable ad and offer close buttons | [CMS Conferences paper](https://openaccess.cms-conferences.org/publications/book/978-1-964867-13-7/article/978-1-964867-13-7_13) | Equal-size decline in the thumb zone |
| 13 | Paid streak repair or paid energy | Common in casual games | No energy system. Streak freezes are earn-only (Sparks) |
| 14 | Purchases not restorable across devices or apps | BitLife language apps: saves and purchases don't transfer ([bitlifeapp.com](https://bitlifeapp.com/whats-new/one-app-every-language-your-life-choices-just-got-international)) | One global app, account-bound entitlements, all languages in one binary |
| 15 | Monetising minors' impulse buys | FTC / Texas SB 2420 | Store parental consent for minor bands, no purchase prompts in under-18 FTUE |
