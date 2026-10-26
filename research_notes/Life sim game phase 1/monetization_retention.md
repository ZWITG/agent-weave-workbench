# Monetization, Retention & LiveOps for a F2P Casual/Narrative Life Simulator (BitLife-style), 2025–2026

Research date: 2026-10-25. Method: web search only (page fetching was blocked by the proxy), so most figures come from search-result snippets and secondary summaries of reports (gamedevreports.substack, wnhub, gameindustrylibrary). Where a figure comes from a vendor blog or could not be checked against the primary report, that is flagged. Treat all benchmarks as ranges for client decks, not exact targets.

## 1. Hybrid monetization (IAP + rewarded ads + subscriptions/VIP + season pass): what works, revenue splits, ARPDAU/ARPU, eCPM, payer conversion

### Takeaway
Hybrid is now the default, and for a life sim it is the right model. There is no universal IAP/ad ratio. In the US and other Tier-1 markets, IAP usually brings in 77–90% of revenue, while ads lead in India, Indonesia and Brazil. Life Simulator is one of the top-earning hybrid-casual subgenres (US Android ARPU of roughly $11–15 in Appodeal's 2025 data). US rewarded video eCPMs are about $12–20, higher on iOS. Expect only about 2–3.5% of players to pay, so ads and low-friction subscriptions/unlocks carry the non-payers.

### Cited Findings
**Model mix and splits**
- Supersonic says the idea that hybrid-casual games need a 50/50 IAP/ad split is a misconception. Some succeed at about 60% IAP, others with ad-heavy models — [Supersonic](https://supersonic.com/learn/blog/the-dos-and-donts-of-hybrid-casual-monetization-how-to-create-a-profitable-hit/)
- Sensor Tower data, as summarized: the largest IAP-first hybrid games make about 4x the revenue of the largest IAA-first (ad-first) hybrid games. Hybrid splits into two distinct models — [Deconstructor of Fun on Sensor Tower](https://www.deconstructoroffun.com/blog/5-numbers-hiding-in-plain-sight-sensor-towers-ad-monetization-report); [Sensor Tower](https://sensortower.com/blog/gaming-deep-dive-ad-monetization-report)
- Geography: in growing markets (India, Indonesia, Brazil) ads bring in about 55–70% of revenue. In the US, Canada, South Korea and Japan, IAP is 77–90% — [Sensor Tower summary via gamedevreports](https://gamedevreports.substack.com/p/sensor-tower-mobile-game-ad-monetization)
- Jan–May 2026: ads were 70.3% of mobile game revenue in India and 22.1% in the US — [Sensor Tower via gamedevreports](https://gamedevreports.substack.com/p/sensor-tower-mobile-game-ad-monetization)
- 2025 mobile game ad revenue was about $12B across 19 countries (Sensor Tower). One blog estimates ads at about 23% of combined ad+IAP revenue in those markets (that is the blog's own estimate) — [wnhub](https://wnhub.io/news/analytics/item-51349); [Deconstructor of Fun](https://www.deconstructoroffun.com/blog/5-numbers-hiding-in-plain-sight-sensor-towers-ad-monetization-report)
- Feb–Apr 2026 ad revenue by type: casual 40%, hyper-casual 40%, hybrid 16%, mid-core 4%. Puzzle had a 53% genre share. AppLovin and AdMob took 65% of ad revenue (May 2026) — [Sensor Tower via gamedevreports](https://gamedevreports.substack.com/p/sensor-tower-mobile-game-ad-monetization)
- AppsFlyer: Android mid-core hybrid games reached 146% D90 ROAS, versus 93% for IAP-only and 58% for IAA-only. Hypercasual hybrid D90 ARPU was $0.60 versus $0.47 for IAA-only — [AppsFlyer](https://www.appsflyer.com/company/newsroom/pr/app-monetization-report/)
- Gamesforum/AdInMo survey: 72% of developers are adopting hybrid. 45% grew their IAP revenue share over the past year, against 17% for IAA — [AdInMo](https://www.adinmo.com/72-of-mobile-games-makers-adopting-hybrid-monetization-model)
- Sensor Tower 2025: global mobile game IAP was $81.75B (+1.3% YoY). Hybrid-casual IAP grew 20% to $4.2B. The top 1% of publishers took 92.5% of IAP revenue — [Sensor Tower State of Gaming 2026 via gamedevreports](https://gamedevreports.substack.com/p/sensor-tower-state-of-gaming-2026)
- Subscriptions inside games: in games that use all three models (IAP + ads + subs), subscription revenue grew from 4% of total in Jan 2025 to 7% in early 2026. Subscription revenue across the App Store and Google Play grew 105% YoY in Q1 2026 (AppsFlyer) — [gamedevreports weekly recap Jun 2026](https://gamedevreports.substack.com/p/weekly-gaming-reports-recap-june-e95)

**Life-sim-specific benchmarks**
- Appodeal Mobile Casual Benchmarks 2025 (US, Android, June 2024–Jan 2025, more than 10,000 games): Life Simulator, Merge 3 and Luck Battle are the top hybrid-casual subgenres, with ARPU of $11.08–$14.83. Plain hypercasual/simulation shows about 3% D30 and roughly $0.79 ARPU (another summary says $0.86 for hypercasual) — [gameindustrylibrary (Appodeal)](https://gameindustrylibrary.com/documents/mobile-casual-benchmarks-report-2025); [AppDeveloperMagazine](https://appdevelopermagazine.com/mobile-casual-benchmarks-report-2025/amp/)
- BitLife scale (Sensor Tower, US, all platforms): weekly revenue stayed above about $263K through Q1 2025, with about 85K weekly downloads on average. In Q2 2025, weekly revenue peaked around $497K (mid-June), weekly downloads peaked at 94K, and WAU was 1.0–1.4M. On US iOS, weekly revenue peaked at $414K in Q2 2025, so iOS is the large majority of US revenue — [Sensor Tower Q2 2025 US unified](https://sensortower.com/blog/2025-q2-unified-top-5-simulator%20games-revenue-us-60416e41241bc16eb8905c2f); [Sensor Tower Q1 2025 US unified units](https://sensortower.com/blog/2025-q1-unified-top-5-simulator%20games-units-us-60416e41241bc16eb8905c2f); [Sensor Tower Q2 2025 iOS US](https://sensortower.com/blog/2025-q2-ios-top-5-simulator%20games-units-us-60416e41241bc16eb8905c2f)
- BitLife on US Android, Q1 2025: weekly revenue fell from about $101K to $71–72K, and downloads fell from about 44K to 21K — [Sensor Tower Q1 2025 Android US](https://sensortower.com/blog/2025-q1-android-top-5-simulator%20games-revenue-us-60416e41241bc16eb8905c2f)
- BitLife's model: free-to-play with IAP plus ads ("Contains Advertising"). Current App Store prices: Bitizenship $7.99 (unlocks content and removes ads), God Mode $9.99 (character editor), Bitizenship + God Mode bundle $15.99, Boss Mode $20.99, Remove Ads $2.99, plus paid expansion packs — [App Store](https://apps.apple.com/app/bitlife/id1374403536)

**ARPDAU / ARPU / ARPPU**
- ARPDAU: casual ads-only about $0.01–0.05, hypercasual $0.03–0.08 (H1 2025), hybrid-casual (ads + IAP, 40–60% IAP share) $0.15–0.50. Vendor blog — [Juego Studio](https://www.juegostudio.com/blog/arpdau-benchmarks-by-game-genre)
- Blended ARPDAU: casual/hyper-casual $0.10–0.30, mid-core $0.50–2. Glossary, no methodology given — [MWM glossary](https://mwm.ai/glossary/arpdau)
- D90 IAP metrics (2026 report): casual D90 ARPPU $7.26 (casino $11.40, mid-core $9.80), casual D90 IAP ARPU about $1.34 — [gamedevreports weekly recap](https://gamedevreports.substack.com/p/weekly-gaming-reports-recap-june-e95)
- An older US benchmark: casual/puzzle ARPPU of $36.06 — [wnhub](https://wnhub.io/news/marketing/item-12861) (old, date unclear)

**Payer conversion**
- AppsFlyer: only 3.5% of mobile gamers spend on IAP — [PocketGamer.biz](https://www.pocketgamer.biz/comment-and-opinion/64530/best-practices-for-implementing-iap-starter-packs-in-free-to-play-games/entry/1/)
- AppsFlyer (2017, US): casual/puzzle payer conversion was 1.96% for organic and 2.38% for non-organic users — [wnhub](https://wnhub.io/news/marketing/item-12861)
- GameAnalytics (2019): even top projects rarely convert more than 1% of players — [wnhub](https://wnhub.io/news/analytics/item-2261)
- AppSamurai's glossary gives casual conversion of 5–8% and ARPPU of $10–25 with no cited data, which looks optimistic — [AppSamurai](https://appsamurai.com/glossary/arrpu/)

**Rewarded video eCPM**
- Appodeal Q4 2024, US rewarded video: $19.63 on iOS and $16.49 on Android. iOS was above Android in every month and every format — [Appodeal](https://appodeal.com/the-mobile-ecpm-report-updated-q4-2024-view); [PDF](https://appodeal.com/wp-content/uploads/2025/03/Quarterly_Mobile_eCPM_Report_-_Q4_2024.pdf)
- 2025 commentary: the average is about $12–15, with 5–10% YoY declines in saturated North America. A Tenjin 2025 benchmark is cited for iOS rewarded outperforming Android by about 25%. US iOS is about $12–16 — [Applixir](https://www.applixir.com/?p=3237); [Applixir](https://www.applixir.com/?p=3206)
- The same US rewarded placement ranges from about $13 to $30 depending on data source (Sept 2026) — [Playio](https://blog.playio.co/mobile-game-ecpm-benchmarks-2026)
- Rewarded video is still the leading casual ad format (eMarketer sentiment and completion data) — [Verve](https://verve.com/blog/hybrid-monetization-in-casual-games-how-beresnev-strikes-the-right-balance/)

**Season pass / VIP**
- In 2021, half of top-grossing titles globally used a season pass, and casual games such as Candy Crush and Gardenscapes were adding them — [Sensor Tower 2022](https://sensortower.com/blog/state-of-mobile-game-monetization-2022)
- Candy Crush Saga, Royal Match, Gossip Harbor and Gardenscapes are among the top season-pass earners (Android, Q1 2025, Ireland sample) — [Sensor Tower](https://sensortower.com/blog/2025-q1-android-top-5-season%20pass%20games-revenue-ie-61f318c0afb48b4f7181dbf0)
- Naavik describes VIP subscriptions as recurring monthly purchases with perks such as badges, faster progression, shop discounts and cashback, and as a cheap, quick-to-test alternative to battle passes — [Naavik](https://naavik.co/f2p-mobile/vip-subscriptions-recurring-revenue-revolution/)
- Omdia: Asia's mobile in-app game subscription revenue is $3.6B in 2025, projected to reach $5.8B by 2029 (12.7% CAGR). Subscriptions are increasingly combined with battle passes — [Silicon UK / Omdia](https://www.silicon.co.uk/press-release/omdia-asias-game-subscription-market-set-to-reach-9-4bn-by-2029)

### Inferences
- For a BitLife-style game, the best-supported structure is: (a) permanent premium unlocks/modes (the BitLife pattern), (b) opt-in rewarded ads for non-payers, (c) a low-price "remove ads + perks" subscription or one-time purchase, and (d) a light seasonal pass tied to content drops. Gacha/loot boxes are not needed and carry regulatory risk (see section 2).
- Base-case planning numbers for a Tier-1 hybrid narrative sim, to validate in soft launch: ARPDAU of $0.15–0.40, 2–4% payer conversion, US rewarded eCPM of $12–20, and US IAP at 70–85% of revenue.
- BitLife's iOS weighting suggests iOS will deliver most of the US revenue. UA and pricing tests should be run on iOS first.

### Gaps
- No published 2025 IAP/ad split, ARPDAU or payer conversion specifically for narrative or life-sim games. Appodeal gives only ARPU, and only for US Android.
- No 2025 data on season-pass adoption or revenue share in casual games, and no rewarded-only share of ad revenue. The Sensor Tower report is paywalled.
- No reliable BitLife annual revenue figure, only weekly Sensor Tower snapshots.

## 2. Ethical / player-friendly monetization, what backfires, and the 2025–2026 regulatory and platform landscape

### Takeaway
The regulatory trend favors transparent, non-random monetization. Belgium treats paid loot boxes as gambling. The EU's Digital Fairness Act (proposal expected around Q4 2026) may restrict loot boxes and require real-money prices next to virtual currency. The FTC's $20M Genshin settlement penalized opaque loot-box odds and sales to minors. Platform economics have also shifted. US iOS external purchase links currently carry 0% Apple commission pending a court-set rate (Apple has proposed 15%). Google is moving to 10–25% tiers with alternative billing. Apple's EU fees from Oct 1, 2026 are 26% IAP, 20% alternative payment processor and 15% link-out. Web shops (D2C) are about 15% of mobile IAP.

### Cited Findings
**Loot boxes and consumer law**
- Belgium: classified as gambling since 2018, and a 2025 Antwerp court decision is reported to make paid loot boxes unlawful. Enforcement is uneven — [Promise Legal](https://blog.promise.legal/loot-box-laws-by-jurisdiction-indie-game-studios/); [Siege.gg](https://siege.gg/news/several-eu-countries-have-introduced-stricter-regulations-on-loot-boxes-in-games-in-2025)
- Netherlands: a 2022 court ruling overturned the regulator's ban, and in Sept 2024 the government said it does not plan to reinstate it. Some sources still describe Dutch loot boxes as unlawful, so sources conflict. The Dutch minister Beljaarts is pushing for an EU-wide ban — [Promise Legal](https://blog.promise.legal/lootbox-laws-game-developers/); [GamblingNews](https://www.gamblingnews.com/news/dutch-minister-pushes-for-eu-wide-loot-box-ban-to-shield-consumers/)
- UK: loot boxes are not gambling under the Gambling Act 2005 (unchanged as of June 2026). Pressure comes through ASA enforcement against listings that fail to disclose loot boxes — [Everything Edinburgh](https://everythingedinburgh.com/games/gaming/loot-boxes-uk-gambling-law/); [Promise Legal 2026](https://blog.promise.legal/lootbox-regulation-2026-game-studios/)
- EU Digital Fairness Act: the Commission's 2026 work programme schedules a proposal for Q4 2026, reportedly a November draft (unconfirmed). Measures under discussion include showing the real-money value of virtual-currency items, possible restrictions or bans on paid loot boxes, and disabling some design features by default in children's games. The CPC Network says in-game currency transactions fall under EU consumer law — [Freshfields](https://technologyquotient.freshfields.com/post/102ltio/the-eus-proposed-digital-fairness-act-a-game-developers-guide-to-potential-imp); [Heuking](https://www.heuking.de/en/news-events/newsletter-articles/detail/digital-fairness-act-implementation-obligations-companies-need-to-prepare-for.html); [Sigma](https://sigma.world/news/virtual-currencies-video-games-eu-opens-debate/)
- The Commission's 2024 Fitness Check flagged loot boxes, pay-to-win, virtual currencies that obscure costs, opaque personalized offers, and design that maximizes playtime or spend, especially where minors are involved — [Slaughter and May](https://thelens.slaughterandmay.com/post/102kxp5/digital-fairness-act-european-commission-launches-consultation-and-call-for-evid)
- October 2026: the EU CPC network launched an action involving nine video game companies (headline only, details not retrieved) — [Lewis Silkin](https://www.lewissilkin.com/insights/2026/10/15/eu-consumer-protection-network-launches-action-involving-nine-video-games-compani-102o5do)
- US: in January 2025 the FTC reached a $20M settlement with Cognosphere (Genshin Impact) over misleading loot-box odds and costs, and COPPA violations. Terms include blocking under-16 purchases without parental consent and correcting disclosures of odds and prices — [VGC](https://www.videogameschronicle.com/news/genshin-impact-maker-fined-20m-over-deceptive-loot-boxes-and-child-privacy-violation); [BleepingComputer](https://www.bleepingcomputer.com/news/gaming/ftc-cracks-down-on-genshin-impact-gacha-loot-box-practices)
- Apple age ratings (2025): new 13+, 16+ and 18+ tiers replace 12+ and 17+. The questionnaire adds in-app controls, and loot boxes are listed under chance-based activities (appearing at 9+/13+). The deadline to answer was Jan 31, 2026. BitLife's current listing is 18+ — [Apple developer](https://developer.apple.com/help/app-store-connect/reference/age-ratings); [iPhone in Canada](https://www.iphoneincanada.ca/2025/07/25/updated-app-store-age-ratings); [App Store](https://apps.apple.com/app/bitlife/id1374403536)

**What backfires (BitLife evidence)**
- No news coverage was found of a broad "Boss Mode backlash." The evidence is anecdotal: a fan blog says more features have been put behind paywalls and the game is heavily ad-monetized, and a user complained of still seeing ads after buying the no-ads Bitizenship — [The Art Sherpa blog](https://theartsherpa.com/classroomelse/blog); [ComplaintsBoard](https://www.complaintsboard.com/bitlife-life-simulator-b150146)
- Boss Mode was listed at $15.99 (older listing) and is $20.99 now, and God Mode has risen from $7.99 to $9.99. This suggests price rises, but no dates were found — [App Store](https://apps.apple.com/app/bitlife/id1374403536); [AppleVis](https://www.applevis.com/comment/144996)
- In Feb 2023, Candywriter's agents sent a wrongful DMCA notice that removed AppleVis (a blind-community site) listings, which was called a betrayal of blind gamers. Candywriter reversed it the next day. This was a trust incident, not a monetization one — [AppleVis](https://applevis.com/comment/144257)
- Player sentiment: Tapjoy (2017) found 76% of US gamers prefer opt-in rewarded ads to mandatory ads, and 51% would watch 4 or more per day. Unity (2015) found 46% prefer rewarded video, against 5% for interstitials. Both are vendor surveys and dated — [MarketingDive](https://www.marketingdive.com/press-release/20170613-mobile-gamers-prefer-rewarded-ads-by-4-to-1-margin-tapjoy-research-finds/); [GamesBeat](https://gamesbeat.com/unity-the-majority-of-mobile-gamers-are-open-to-engaging-with-incentivized-video-ads/)

**Apple US (Epic v. Apple)**
- April 2025: the district court ordered Apple to allow external purchase links and buttons without a commission, and called Apple's 27% fee "a gross miscalculation" — [RevenueCat](https://www.revenuecat.com/blog/growth/apple-anti-steering-ruling-monetization-strategy); [VGC](https://videogameschronicle.com/news/epic-court-battle-ends-with-apple-ordered-to-relax-ios-payment-rules)
- December 2025: the Ninth Circuit upheld contempt but said Apple may eventually charge a fee tied to genuinely necessary costs (excluding security and privacy) — [Beancount guide](https://beancount.io/blog/2026/07/11/apple-app-store-external-purchase-links-accounting-guide)
- August 2026: Apple proposed 15% on linked-out purchases (10% for partner programs, 5% for Small Business Program members). The Supreme Court granted cert on July 2, 2026. As of mid-August 2026, US link-outs pay 0% until a rate is approved — [iClarified](https://www.iclarified.com/101778/apple-seeks-court-approval-for-15-commission-on-external-app-purchases); [iPhone in Canada](https://www.iphoneincanada.ca/2026/08/14/apple-proposes-15-cut-purchases-outside-app-store/); [Courthouse News](https://courthousenews.com/apples-fight-over-commissions-for-linked-out-app-store-purchases-continues-in-federal-court/)

**Apple EU (DMA)**
- From Oct 1, 2026: App Store IAP 26% (15% for small business), alternative payment processor 20%, link-out 15%, and a 5% Core Technology Commission (replacing the per-install fee) for alternative distribution. Epic calls these "junk fees" — [MacRumors](https://macrumors.com/2026/08/19/ec-epic-apple-app-store-changes); [mjtsai](https://mjtsai.com/blog/2026/08/18/new-eu-app-store-terms-to-comply-with-dma/); [Phiture](https://phiture.com/blog/apple-new-app-store-terms-2026/)

**Google Play (Epic settlement)**
- November 2025: Google agreed to Play changes in its settlement with Epic. From June 30, 2026 (US, UK, EEA), alternative billing and web link-outs are allowed alongside Play Billing, with Google still charging a service fee. Reported fees: 10% on the first $1M and on auto-renewing subscriptions, an overall range of 10–25% based on earnings, plus a billing fee for Play Billing. An earlier proposal had 9% for non-gameplay items, 20% for gameplay-affecting items, and a 5% billing fee. New rate cards were due Sept 30, 2026. Court approval and final rates are inconsistent across sources — [MacRumors Jun 2026](https://macrumors.com/2026/06/24/google-play-store-fee-change/); [MacRumors Nov 2025](https://www.macrumors.com/2025/11/05/google-epic-games-antitrust-settlement/); [iClarified](https://www.iclarified.com/101291/google-opens-play-store-to-alternative-payments-under-epic-settlement); [Neon](https://www.neonpay.com/blog/google-plays-new-u.s.-billing-linking-policies-what-game-developers-need-to-know)
- Google's "Games Level Up" program offers reduced rate cards for games that meet quality and engagement criteria — [Notebookcheck](https://www.notebookcheck.net/Google-cuts-Play-Store-fees-as-Epic-settlement-reshapes-Android-app-payments.1243278.0.html)

**Web shops / D2C**
- An Appcharge/GDC estimate puts mobile game D2C at $17B in 2025, about 15% of $113.3B in mobile IAP — [FoxData](https://foxdata.com/en/blogs/mobile-game-d2c-revenues-hit-17-billion-why-publishers-are-pushing-beyond-app-stores/)
- Xsolla Report Vol. 10 (2026): overall mobile game revenue grew 0.2% in 2025, while US D2C grew 26% and top-100 D2C grew 38%. Real net savings are typically 10–20 percentage points after payments, fraud, tax and overhead. Publisher D2C shares: Playtika targets 40%, SciPlay 25%, Stillfront about 39%, Huuuge more than 40%. This is vendor data — [Xsolla](https://xsolla.com/blog/the-xsolla-report-vol-10-2026-d2c-is-reshaping-monetization)

### Inferences
- A "fair" model that also holds up under regulation: no paid randomized rewards, clear one-time unlocks with an exact list of what is included, real-money price shown next to any virtual currency (ahead of the DFA), rewarded ads only (no forced interstitials mid-story), age gating and parental-consent paths for under-16s, and paid "no ads" that removes all ads (BitLife's complaint shows the trust cost when it doesn't).
- A BitLife-style "mature themes" game probably rates 16+/18+, which shrinks the minor-protection exposure but does not remove it.
- US web-shop link-outs are a margin lever (currently 0% Apple fee, possibly 15% later). They suit repeat purchasers and subscriptions more than impulse first purchases. Keep IAP as the default option.

### Gaps
- No primary evidence (reviews data, press) quantifying a BitLife monetization backlash. The "Boss Mode backlash" premise could not be verified.
- The final DFA text, final Google rates/court approval, and the outcome of the Supreme Court case were all pending as of Oct 2026.

## 3. Price anchoring: premium unlocks, starter packs, subscriptions

### Takeaway
The closest comparable (BitLife) prices permanent unlocks at $2.99–$20.99, with a bundle as the decoy/anchor. Starter packs are usually under $5–10, but Deconstructor of Fun warns that very low prices set a weak spending anchor. Game VIP subscriptions typically run $4.99–$9.99 per month. Weekly app subscriptions in the US average about $8 per week (all apps).

### Cited Findings
- BitLife ladder: Remove Ads $2.99 → Bitizenship $7.99 → God Mode $9.99 → Bitizenship + God Mode bundle $15.99 (saves $1.99 against buying separately) → Boss Mode $20.99, plus expansion packs — [App Store](https://apps.apple.com/app/bitlife/id1374403536). God Mode is sometimes discounted, from $11.99 to $7.99 (2022) — [AppleVis](https://applevis.com/comment/139723)
- Deconstructor of Fun survey: 96.3% of developers would price a starter pack under $10 and 59.2% under $5. The author argues this is often too low next to $99.99 promo packs, and that the first purchase shapes later spending — [Deconstructor of Fun](https://www.deconstructoroffun.com/blog/2024/4/8/free-to-play-starter-pack-pricing-when-conversion-is-king-we-may-price-too-low)
- PocketGamer.biz: the first spend is the hardest to get and the most valuable, and starter bundles need urgency — [PocketGamer.biz](https://www.pocketgamer.biz/comment-and-opinion/64530/best-practices-for-implementing-iap-starter-packs-in-free-to-play-games/entry/1/)
- Roblox guidance: offer the pack from the first spawn, with 2–5 items that get players into the fun. Gating it behind the tutorial reduces sales. Packs add about 2–10% revenue on average — [Roblox Creator Docs](https://create.roblox.com/docs/production/game-design/starter-pack-design)
- VIP pricing example: $4.99 per month, $9.99 per quarter, $19.99 per year (Blink: Link in the Clouds) — [App Store](https://apps.apple.com/ae/app/blink-link-in-the-clouds/id6744651986). VIP tiers are typically about $9.99 per month, rising to $29.99 — [Mapendo](https://mapendo.co/blog/subscription-mobile-games)
- VIP engagement: XFLAG reports VIP subscribers play 20% more daily. In Legendary: Game of Heroes, VIPs had a 95% daily login rate — [MAF](https://maf.ad/glossary/mobile-game-subscription/)
- Adapty 2025 (all apps, not games): the average weekly subscription is $8.1 in the US (+12.5%) and $8.3 in Europe (+12.2%). Weekly plans are about half of all subscriptions — [Adapty](https://adapty.io/reports/state-of-in-app-subscriptions-2025/)

### Inferences
- A suggested ladder for a life-sim client deck: $2.99 remove-ads/supporter → $4.99–7.99 core unlock (BitLife's Bitizenship equivalent) → $9.99 power-mode → a $14.99–19.99 bundle as the "best value" anchor → $19.99+ premium mode. Add a one-time $1.99–4.99 starter pack, and optionally a $4.99/month or $29.99/year VIP. Weekly game subs at about $8 are likely to be seen as predatory for a casual audience.

### Gaps
- No controlled public test of $0.99 versus $4.99 starter-pack conversion. No casual-game-specific subscription take-rate data.

## 4. Retention benchmarks and loop / FTUE / engagement design

### Takeaway
Market-wide retention is falling. GameAnalytics' 2026 benchmarks show a median D1 of about 22%, D7 just under 4% and D30 under 1%. The top 10% reach about 40% D1, 11–12% D7 and about 4% D30. For a sim, aim for top-quartile figures: D1 35–40%+, D7 10–15%, D30 4–6%. Habit mechanics (streaks with forgiveness, daily goals), opt-in push with clear value, and very fast time-to-fun in onboarding are the best-supported levers.

### Cited Findings
- GameAnalytics 2026 (2025 data): median D1 about 22% and top 10% about 40%. Median D7 just under 4%, top 10% about 11–12%, top 1% over 25%. Median D30 0.69–0.79%, top 10% about 4% — [gamedevreports](https://gamedevreports.substack.com/p/gameanalytics-mobile-and-pc-game); [PDF](https://investgame.net/wp-content/uploads/2026/01/2026-01-27-2026-mobile-pc-benchmarks_compressed.pdf)
- GameAnalytics 2025 (2024 data, 11,600 apps): top-quartile D1 about 26–28%, median D7 3.42–3.94%, and 75% of projects below 3% D28. Board, card, puzzle and casino retain best — [gamedevreports](https://gamedevreports.substack.com/p/gameanalytics-mobile-gaming-benchmarks); [PDF](https://investgame.net/wp-content/uploads/2025/02/2025-GameAnalytics-Mobile-Gaming-Benchmarks.pdf)
- Sensor Tower: D7 for top-25 games fell to 14.9% in December 2025 — [gamedevreports State of Gaming 2026](https://gamedevreports.substack.com/p/sensor-tower-state-of-gaming-2026)
- Appodeal 2025 (US Android): Management Sim and Coin Pusher exceed 50% D1. Hypercasual/simulation is about 3% D30 — [gameindustrylibrary](https://gameindustrylibrary.com/documents/mobile-casual-benchmarks-report-2025/read)
- A blog's simulation-genre ranges (D1 45–60%, D7 30–45%, D30 20–30%) are unsourced and far above other benchmarks, so do not use them — [Playio](https://blog.playio.co/retention-by-game-genre)
- Streaks: Duolingo found users who reach a 10-day streak churn less (correlational). Streak-saver notifications and relaxing the streak to "one lesson per day" improved retention. Streak notifications are a major DAU driver (17M DAU in June 2023) — [Business of Apps](https://www.businessofapps.com/news/duolingos-streak-feature-drives-record-17-million-daus); [Lenny/Shuttleworth summary](https://videohighlight.com/v/_CCwoQZH5hI)
- Losing a long streak can drive users away (anecdote), which argues for streak freezes and repairs — [Indie Hackers](https://www.indiehackers.com/post/a-streak-feature-increases-retention-ed65a9d3de)
- Push: opt-in is about 81% on Android and 51% on iOS (60% average). Many games ask too early without explaining the value. Opted-in users are about 2x more likely to be retained (correlational, vendor data) — [Pushwoosh](https://cdc.pushwoosh.com/blog/increase-push-notifications-opt-in); [Chartboost](https://www.chartboost.com/?p=5759); [ContextSDK](https://contextsdk.com/blogposts/gaming-push-strategy-overcoming-the-63-5-industry-opt-in-challenge)
- FTUE: let the player do something fun almost immediately, use guided tours only for complex mechanics, and track each tutorial step as a funnel — [GameAnalytics](https://gameanalytics.com/blog/tips-for-a-great-first-time-user-experience-ftue-in-f2p-games); [Unity](https://unity.com/how-to/10-first-time-user-experience-tips-games). Reach core gameplay in about 1 minute; delays past about 90 seconds lose many users (blog rule of thumb) — [Playio](https://blog.playio.co/mobile-game-onboarding-retention)

### Inferences
- Life-sim loops. Core loop: age up a year, get an event or choice, see the outcome and stat changes, decide. Meta loop: a collection of achievements, ribbons and "lives", generational/legacy play, and unlocked careers or scenarios. Weekly challenges ("live a life where…") give a reason to come back without being pay-gated. The first meaningful, funny narrative event should land within the first 60 seconds.
- Push permission should be requested after the first memorable life ends ("get notified of new challenges"), not at launch. Streaks should use "one life or one year per day" with a free weekly freeze.

### Gaps
- No credible published D1/D7/D30 for life-sim or narrative games specifically. Push frequency benchmarks for games are not available. No measured lift from daily login calendars in games.

## 5. LiveOps cadence and tooling

### Takeaway
Leading casual games run layered, overlapping events: several tournaments per month, short sprints, long collection chases, and weekend peaks. Tooling is typically Firebase Remote Config + A/B Testing (free, BigQuery export) or Unity Game Overrides, with Metaplay, Satori or Balancy used when calendar/cron scheduling and offer management are needed.

### Cited Findings
- Sensor Tower's analysis of the Royal Match calendar covered more than 5,500 tournament instances across 12 games. Sprint tournaments run about 9.4 per month per game. The suggested baseline is at least 2 standard tournaments plus 1 sprint format, layered with streak, co-op, milestone and merge events and a 2-month album chase, timed for weekends. Monopoly GO runs no sprint tournaments — [Sensor Tower](https://sensortower.com/blog/what-royal-matchs-calendar-teaches-about-live-ops-in-2026)
- Monopoly GO and Coin Master run 6–8 parallel events. Monopoly GO has 40 event slots against Coin Master's 9 (2024 AppMagic data) — [GamerBraves](https://gamerbraves.com/?p=183836)
- Roughly every second or third Royal Match reward is time-limited — [investgame LiveOps holiday deck](https://investgame.net/wp-content/uploads/2025/12/2025-12-16-LiveOpsfortheHolidaySeason.pdf). Some events last only one hour, to create urgency — [Liftoff podcast](https://liftoff.ai/?p=33129)
- The industry is shifting from "core-first" to "event-first" — [PocketGamer.biz](https://www.pocketgamer.biz/why-mobile-gaming-has-shifted-from-a-core-first-to-an-event-first-model/)
- Firebase Remote Config changes game values without a release and supports A/B tests with results exported to BigQuery. Unity runs live events through Remote Config/Game Overrides with no dedicated scheduler. Metaplay offers calendar + cron, and Satori offers time-based events — [Firebase](https://firebase.google.cn/learn/pathways/firebase-remote-config-unity-games); [Metaplay comparison](https://www.metaplay.io/comparisons/liveops-platforms-compared); [Lion Studios/Balancy](https://docs.lionstudios.cc/docs/features/remote-configs/balancy-adapter)

### Inferences
- A proposed cadence for a narrative sim: a weekly challenge scenario (every Monday), weekend limited-time events (for example "Celebrity Weekend"), monthly themed content or seasonal events with an optional pass, a quarterly content expansion (BitLife-style paid pack plus free content), and holiday tie-ins. Move offers, event dates, ad caps and prices into remote config from day one, and A/B test the price ladder and ad frequency.

### Gaps
- No public LiveOps cadence data for narrative or life-sim games (BitLife's own calendar was not found).

## 6. KPIs for clients: LTV, CPI by geo, ROAS targets, payback

### Takeaway
Casual-game UA is cheap on Android but costly on iOS. Liftoff/Singular report an average casual CPI of $1.41 on iOS and $0.14 on Android (global). Average casual D30 ROAS is only 47% on iOS and 15% on Android, so most hybrid/IAP casual titles pay back over 60–180 days. The client dashboard should show D1/D7/D30 retention, ARPDAU (IAP vs. ads), payer conversion, ARPPU, LTV (D30/D90/D180), CPI by geo, D7/D30 ROAS, and payback day.

### Cited Findings
- Liftoff & Singular 2025 Casual Gaming Apps Report (Feb 2024–Feb 2025, about 2.4–2.5B installs, $11.9B spend): casual CPI $1.41 on iOS and $0.14 on Android. Highest iOS CPI is casino at $21.03, highest Android is RPG at $4.29. Casual D30 ROAS is 47% on iOS and 15% on Android. Sports is highest on iOS (80%), RPG highest on Android (39%) — [Liftoff](https://liftoff.ai/?p=34267); [gamedevreports](https://gamedevreports.substack.com/p/liftoff-and-singular-casual-games); [Statista](https://www.statista.com/statistics/1241651/global-cpi-casual-gaming-apps-genre-platform)
- North America casual/puzzle CPI is about $3.00 on iOS and $2.00 on Android (secondary estimate) — [Segwise](https://segwise.ai/blog/cpi-ipm-roas-benchmarks-optimizing-ad-spend/)
- Older country data (Q4 2022, hypercasual): US CPI $0.65 on iOS and $0.58 on Android — [gamedevreports Tenjin/GA](https://gamedevreports.substack.com/p/tenjin-and-gameanalytics-hypercasual-6e4)
- Singular Q4 2025: retention "rules", CPIs surging, and TikTok dominating (headline only) — [Global Games Forum](https://www.globalgamesforum.com/news/singular-q4-2025-quarterly-trends-report-retention-rules-cpis-surge-tiktok-dominates)
- ROAS targets from vendor guides vary: hyper-casual D7 of 0.8–1.0x and mid-core IAP D7 of 0.3–0.5x (Linkrunner); casual D7 0.8–1.2x and D30 1.5–3.0x (Adapty, which looks optimistic next to Liftoff's measured 47% D30); F2P D7 of 15–25%, implying D90–D180 payback (MWM). Break-even ROAS = 1 / margin — [Linkrunner](https://deeplinks.linkrunner.io/glossary/what-is-return-on-ad-spend); [Adapty](https://adapty.io/blog/what-is-roas/); [MWM](https://mwm.ai/glossary/roas); [SplitMetrics](https://splitmetrics.com/blog/apple-ads-roas/)
- LTV methods: the naive method (ARPDAU × expected lifetime) pre-launch, and a retention-curve fit (D2/D7/D14/D30 + ARPDAU) in soft launch. Invest in segments where LTV > CPI — [Game Developer](https://www.gamedeveloper.com/business/calculating-ltv-for-a-mobile-game-methods-for-different-stages)
- Market concentration: fewer than 2% of 2025 mobile releases passed 500K downloads — [wnhub](https://wnhub.io/news/analytics/item-51906)

### Inferences
- Illustrative unit economics (an assumption, not sourced): US iOS CPI of about $2–3, ARPDAU of $0.25, and a D1/D7/D30 of 40/12/5% give roughly 8–10 lifetime days by D180, or about $2.00–2.50 LTV. That is marginal, so UA scaling depends on top-decile retention or a higher ARPDAU, and early soft launch should focus on organic and virality (BitLife-style shareable moments) plus cheaper geos.
- Suggested ROAS goals for a hybrid casual sim: D7 of 20–35%, D30 of 50–70%, payback at D90–D180. Calibrate against Liftoff's 47% iOS D30 average.

### Gaps
- No 2025 CPI-by-country table for casual games (the Liftoff full report was not accessible). No sourced LTV:CPI ratio target. AppsFlyer's own gaming ROAS benchmarks were not found.
