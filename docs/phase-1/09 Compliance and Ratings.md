---
title: "09 Compliance and Ratings"
project: Relivable
phase: 1
tags: [relivable, phase-1, compliance, age-rating, privacy, coppa, gdpr, accessibility, ai-policy, ip]
updated: 2026-10-26
---

# 09 Compliance and Ratings

> [!danger] Not legal advice: verify with counsel
> This note is a **planning summary built from secondary sources** (law-firm alerts, press, vendor blogs) gathered by web search on 2026-10-25. Statutes, store policies and court rulings in this area changed several times in 2025–2026 and are still moving (Texas litigation, Utah/Louisiana amendments, the EU Digital Fairness Act, Google fee rate cards). **Before launch, qualified counsel in the US, EU/UK and Brazil must confirm every item.** Budget about **$15–50K** for legal and privacy counsel (estimate; see [[11 Roadmap Team and Budget]]).

Related: [[_Concept Brief]] · [[06 Monetization and Economy]] · [[08 Technical Architecture]] · [[12 Risks and KPIs]] · Source: `research_notes/Life sim game phase 1/tech_compliance_budget.md`, `monetization_retention.md`.

---

## 1. Position in one table

| Question | Relivable position |
|---|---|
| Who is it for? | A **general-audience, mature-themed** game for **16+** (store rating). It is **not directed to children** |
| Under-13s | **Blocked** through a neutral age screen plus platform age signals. No child mode in Phase 3/4 |
| 13–15 / 16–17 | Phase 3/4: under 16 blocked in regions where the store rating requires it. **Client decision needed:** a softened 13+ "Teen" content profile could be added in Phase 5 (see §3) |
| Ads for minors and unknown age | Contextual only. No ad ID, no personalised ads, no third-party data sharing |
| Paid randomness | **None.** No loot boxes, gacha or paid mystery rewards ([[06 Monetization and Economy]]) |
| AI | Optional and rewording-only, with moderation, a report button and consent ([[08 Technical Architecture]] §10) |
| Accessibility | WCAG 2.2 AA-equivalent for mobile, with EN 301 549 as the EAA reference (from knowledge, not researched). A release gate on every build |

---

## 2. Age rating plan

### 2.1 Comparable: BitLife
- **Apple:** listed **17+** under the old system, with descriptors for mild alcohol/tobacco/drug references, profanity/crude humour, **simulated gambling**, cartoon violence, sexual content and nudity, and frequent/intense mature themes ([App Store](https://apps.apple.com/jp/app/bitlife-life-simulator/id1374403536?l=en-US)). Its current listing reportedly shows **18+** under the new tiers ([App Store](https://apps.apple.com/app/bitlife/id1374403536)).
- **Google Play:** Mature 17+ ([Prima Games](https://primagames.com/tips/is-bitlife-for-kids-bitlife-kids-warning-guide)). **PEGI 16** per the Welsh government ([Hwb](https://hwb.gov.wales/keeping-safe-online/in-the-know/bitlife)). Common Sense Media says 14+ ([CSM](https://www.commonsensemedia.org/app-reviews/bitlife-life-simulator)). Candywriter's terms say the game is not directed to under-16s ([Qustodio](https://www.qustodio.com/blog/is-bitlife-safe-for-kids/)).

### 2.2 Target ratings

| Store / system | Mechanism | Target | Design levers to hold the target |
|---|---|---|---|
| **Apple (2025 tiers 4+/9+/13+/16+/18+)** | New questionnaire covering violence, IAP, **AI features**, wellness and interactive elements. Ratings can vary by region. Developers had to answer by **31 Jan 2026** or be blocked from updates ([9to5Mac](https://9to5mac.com/2025/07/24/apple-notifies-developers-of-new-app-store-age-rating-system/); [Apple](https://developer.apple.com/help/app-store-connect/reference/age-ratings)) | **16+** | Sexual content is **implied only** (fade-to-black, no nudity, no explicit text). Drug use is referenced and has consequences, never instructional. Violence is described, not graphic. Gambling is **simulated with no real-money cash-out**. AI is constrained (no free-text). The exact 16+/18+ thresholds were not retrieved (gap), so do a **questionnaire dry-run in Phase 2** |
| **Google Play / IARC** | One Play Console questionnaire gives ESRB, PEGI, USK and other ratings. Misrepresenting content risks removal, and authorities can override ([Google](https://support.google.com/googleplay/android-developer/answer/9898843?hl=en)) | **Mature 17+** (ESRB-equivalent M) / **PEGI 16** / USK 16 | Same as above. Answer truthfully about simulated gambling and sexual references |
| **IAPs (Texas, Utah)** | State laws require developers to **age-rate the app and its IAPs** ([Pillsbury](https://www.pillsburylaw.com/en/news-and-insights/app-store-accountability-act-texas.html)) | Each SKU carries the app rating. Story Packs with heavier themes (e.g. a crime-family pack) are flagged as 16+ content | A rating field in the IAP catalogue and storylet `minRating` |

> [!question] Client decision: teen reach vs. rating
> A 16+/18+ rating cuts the teen audience that drives BitLife-style virality, even though teens play BitLife despite its 17+ rating ([Hwb](https://hwb.gov.wales/keeping-safe-online/in-the-know/bitlife); [Protect Young Eyes](https://www.protectyoungeyes.com/apps/bitlife-parental-controls)). A **13+ "Teen" content profile** (filtered by `contentFlags`) is technically cheap because every storylet already carries flags. It adds **content-variant cost**, though: replacement events for filtered beats, and separate QA. **Recommendation:** launch at 16+, measure, and decide in Phase 5.

---

## 3. Content toggles (player-facing) and content profiles (system-level)

| Toggle / profile | Default | Effect | Implementation |
|---|---|---|---|
| **Romance detail** | "Implied" (only option at 16+) | Relationship events fade to black | `contentFlags: romance_*`. There is no explicit tier at all |
| **Substances** | On | Off removes drug and alcohol storylets and replaces them with neutral events | `substances` flag |
| **Crime & violence detail** | Standard | "Low" softens descriptions. The crime career stays but outcomes are summarised | Text variants via `textKey.low` |
| **Simulated gambling** | On (18+ users) / **Off for under-18 and unknown** | Casino and lottery actions are hidden, with a locked reason ("Not available in your region/age") | `gambling_sim` flag. Also geo-disable where local rules require it |
| **Sensitive themes** (illness, grief, abuse, mental health) | On, with **content notes** before heavy events | The player can skip any flagged event with no stat penalty | See §11 |
| **Profanity filter** | On for under-18, optional for 18+ | Masks strong language in text and AI output | ICU select on `profanity` param |
| **AI flavour text** | **Off** until opted in | See §8 | Settings + first-use consent |
| **Teen profile (Phase 5 option)** | — | A 13+ ruleset that excludes `minRating > 13` | Bundler builds the filtered pool |

All toggles live in Settings, are screen-reader labelled ([[05 UX and Screen Map]]), and are **never sold**. A content preference is not a monetization lever.

---

## 4. US 2026 app-store age laws and age-signal APIs

| Law | Status (per research, Oct 2026) | Developer duties (summary) | Exposure |
|---|---|---|---|
| **Texas SB 2420** (App Store Accountability Act) | Signed 27 May 2025, effective 1 Jan 2026. A preliminary injunction (23 Dec 2025) was **stayed by the Fifth Circuit**, and on **6 Jul 2026 SCOTUS declined to vacate the stay**, so it is **enforceable pending appeal** ([JURIST](https://www.jurist.org/news/2025/12/us-federal-court-blocks-texas-app-store-age-verification-law/); [CCIA](https://ccianet.org/news/2026/05/appeals-court-pauses-injunction-on-texas-app-store-law-that-likely-violates-first-amendment/); [Wikipedia](https://en.wikipedia.org/wiki/Computer_%26_Communications_Industry_Association_v._Paxton)) | Assign age ratings to the app **and IAPs**. Use the store's age category and parental-consent signals. Limit and delete verification data | AG enforcement. One guide cites up to **$10K per violation** ([Reed Smith](https://www.reedsmith.com/our-insights/blogs/viewpoints/102kddh/texas-law-requires-age-verification-for-app-stores-and-developers/)). "Developer" is undefined |
| **Utah SB 142, amended by HB 498 (2026)** | Store and developer duties from **6 May 2026**. **Private right of action from 31 Dec 2026** ([Stoel Rives](https://www.stoel.com/insights/publications/utahs-app-store-accountability-act-goes-into-effect); [HB 498](https://le.utah.gov/Session/2026/bills/introduced/HB0498S02.pdf)) | Age-rate. **Notify stores of significant changes**. Use store age and consent signals for Utah users | Private lawsuits from 2027 |
| **Louisiana HB 570, amended by HB 977 (2026)** | Effective **1 Jul 2026**. **Explicitly rejects a developer good-faith safe harbor** ([Bass Berry](https://www.bassberry.com/news/apps-and-minors-new-compliance-frontiers-and-risks-in-louisiana-utah-and-texas/); [FPF chart](https://fpf.org/wp-content/uploads/2026/06/FPF-Legislation-TX-UT-LA-App-Store-Accountability-Act-Comparison-Chart.pdf)) | Similar to Texas and Utah | Stricter, with no good-faith defence |
| California AB 1043 (Digital Age Assurance Act, 2027) | **Status not found (gap)** | — | Monitor |

**Implementation** (see [[08 Technical Architecture]]):

| Platform | API | Notes |
|---|---|---|
| iOS | **Declared Age Range API** (iOS 26+) ([Appbot](https://appbot.co/blog/age-verification-apis-for-apps-google-apple/)) | Older iOS falls back to a neutral age screen |
| Android | **Play Age Signals API**: bands **0–12, 13–15, 16–17, 18+**. Real data only where laws apply. Expanding to all markets by end of 2026 (AU/CA from mid-Aug 2026) ([BetaNews](https://betanews.com/article/google-play-age-signals-api-global-rollout/); [DEV](https://dev.to/mr_manushukla/google-play-age-signals-api-a-2026-android-integration-guide-for-age-ranges-without-collecting-ids-5cde)) | Flutter wrapper exists: `age_range_signals` ([pub.dev](https://pub.dev/documentation/age_range_signals/latest/)) |
| Both | **Neutral age screen** at first launch (year of birth picker with no default and no hint at the "right" answer) | Store the **band only** and discard the birth year. Re-check when a platform signal arrives |
| Significant-change notices | Release checklist item: if an update changes content or rating, notify the stores (Utah) | Owner: Producer |
| Consent revocation | Handle parental-consent revocation signals: lock the account and stop processing | State-law requirement per research |

---

## 5. COPPA (amended rule)

- **Effective 23 Jun 2025. Compliance deadline 22 Apr 2026** (some provisions excepted) ([Federal Register](https://www.federalregister.gov/documents/2025/04/22/2025-05904/childrens-online-privacy-protection-rule)). Changes:
  - An expanded personal-information definition, including biometrics.
  - **Separate verifiable consent for third-party disclosure** (e.g. ads).
  - A **written data-retention policy** posted in the privacy notice.
  - Tighter security-programme duties ([BBB Programs](https://bbbprograms.org/media/insights/blog/coppa-amended); [Davis Polk](https://www.davispolk.com/index%2ephp/print/pdf/node/116375)).
- A Feb 2026 FTC policy statement eases enforcement where children's data is used **only for age verification** ([Bass Berry](https://bassberry.com/news/amendments-to-the-coppa-rule-now-in-effect/)).
- **Our exposure:** the game is not child-directed, so duties attach on **actual knowledge** of an under-13 user. Mitigations:
  - Block under-13s.
  - Delete the age-screen data of blocked users.
  - No behavioural ads for unknown or under-age users.
  - Publish a retention policy anyway (good practice and an EU requirement).
  - Avoid child-appealing marketing (no cartoon-mascot kids' ads, no placement on kids' channels).
- **Precedent:** the FTC's **$20M Genshin Impact settlement** (Jan 2025) combined COPPA violations with misleading loot-box odds. Terms included blocking under-16 purchases without parental consent ([VGC](https://www.videogameschronicle.com/news/genshin-impact-maker-fined-20m-over-deceptive-loot-boxes-and-child-privacy-violation)).

---

## 6. GDPR, UK Children's Code and CCPA/CPRA

| Regime | Key rule | Relivable action |
|---|---|---|
| **GDPR** | Digital consent age defaults to **16**. Member states may lower it to 13. Examples: **13** in DK, SE, PT and the UK; **14** in ES; **15** in FR and GR; **16** in DE and RO (2021 survey) ([Library of Congress](https://blogs.loc.gov/law/2021/06/new-report-on-childrens-online-privacy-and-data-protection-published/)) | Use a per-country consent-age table in Remote Config. A **CMP** (IAB TCF v2.2) gates ad and analytics SDKs. **DPIA** before soft launch. Data-subject rights: export and deletion in-app. Use an EU data region where possible |
| **UK Age Appropriate Design Code** | Applies to services *likely to be accessed* by under-18s. Its 15 standards include best-interests default, **geolocation off**, and **no nudge techniques**. ICO games guidance (Feb 2023): risk assessment, age established with reasonable certainty ([Bird & Bird](https://twobirds.com/insights/2020/uk/icos-publishes-age-appropriate-design-code); [Inside Privacy](https://www.insideprivacy.com/?p=14337)) | **High-privacy defaults for all under-18s**. No streak-loss guilt notifications, no countdown pressure offers, no dark-pattern paywalls ([[07 Retention and LiveOps]]: forgiving streaks, opt-in push) |
| **CCPA/CPRA** | With actual knowledge (including willful disregard) that a user is under 16, selling or sharing their data requires **opt-in**: from the user if 13–15, from a parent if under 13. Ad-network sharing can count as a "sale" ([IAPP](https://iapp.org/news/a/can-organizations-sell-data-of-children-under-16-under-the-ccpa)) | "Do Not Sell or Share" link in Settings and on the web. Honour Global Privacy Control on the web shop. No sharing for under-16s (we don't seek opt-in) |
| **Store privacy labels** | Apple Privacy Nutrition Label, Google Data Safety | Generated from the SDK inventory. Reviewed each release |
| **Account deletion** | Required by Apple and Google | In-app deletion flow ([[08 Technical Architecture]] §5) |

---

## 7. European Accessibility Act (EAA)

- In force **28 Jun 2025** for e-commerce services, including via mobile apps. One law firm argues **in-app purchases can bring an app into scope**. That is an interpretation, not official guidance ([Travers Smith](https://www.traverssmith.com/knowledge/knowledge-container/a-new-milestone-for-accessibility-the-european-accessibility-act-now-applies/)).
- **Microenterprise exemption:** service providers with fewer than 10 staff and ≤ €2M turnover or balance sheet ([CCPC](https://www.ccpc.ie/business/enforcement/accessibility/european-accessibility-act-guidelines-for-microenterprises/)). Relivable's team may qualify early on, but **we comply anyway**, because accessibility is Pillar 5 and a marketing differentiator.
- **Target:** WCAG 2.2 AA-equivalent and EN 301 549 for the **purchase flow, paywall, settings, account and support** at minimum, and the whole game in practice. Publish an accessibility statement.
- **Proof:** an external accessibility audit in Phase 4 (budgeted in [[11 Roadmap Team and Budget]]), plus the manual VoiceOver/TalkBack release gate ([[08 Technical Architecture]] §9). BitLife's regressions show accessibility breaks silently ([AppleVis](https://www.applevis.com/comment/135452)).

---

## 8. Loot boxes, simulated gambling and pricing transparency

| Jurisdiction | Rule (per research) | Relivable |
|---|---|---|
| **Belgium** | Paid loot boxes are treated as gambling (up to **€800K and 5 years**, doubled where minors are involved). A 2025 Antwerp ruling is reported ([Promise Legal](https://blog.promise.legal/loot-box-laws-by-jurisdiction-indie-game-studios/)) | No paid randomness, so not affected |
| **Brazil, ECA Digital** | Signed Sep 2025, effective ~Mar 2026. **Bans loot-box sales to minors**, defined by mechanics. Fines up to **10% of revenue**. A June 2026 court ordered Riot to pay damages and disclose probabilities ([Programming Insider](https://programminginsider.com/loot-boxes-regulation-and-where-the-line-sits-in-2026/); [Sheep Esports](https://www.sheepesports.com/articles/brazil-court-orders-riot-games-to-pay-eur2-5m-over-league-of-legends-loot-boxes/en)) | PT-BR is a launch language, so **no paid random items anywhere** |
| **Netherlands** | The 2022 court ruling overturned the ban, but sources conflict. The minister is pushing for an EU-wide ban ([GamblingNews](https://www.gamblingnews.com/news/dutch-minister-pushes-for-eu-wide-loot-box-ban-to-shield-consumers/)) | Soft-launch market. Not affected |
| **UK** | Not gambling under the 2005 Act. ASA enforces loot-box disclosure in ads ([Promise Legal 2026](https://blog.promise.legal/lootbox-regulation-2026-game-studios/)) | Ads must not imply random paid rewards |
| **EU Digital Fairness Act** | Proposal scheduled for **Q4 2026**. Under discussion: real-money price shown next to virtual currency, loot-box limits, and child-protective defaults. The CPC network says virtual-currency transactions fall under consumer law, and launched an action against nine games companies in Oct 2026 ([Freshfields](https://technologyquotient.freshfields.com/post/102ltio/the-eus-proposed-digital-fairness-act-a-game-developers-guide-to-potential-imp); [Lewis Silkin](https://www.lewissilkin.com/insights/2026/10/15/eu-consumer-protection-network-launches-action-involving-nine-video-games-compani-102o5do)) | **Already compliant by design:** no premium currency, prices shown in real money, exact contents listed for every SKU |
| **Simulated gambling** (casino, lottery in-game) | Drives the rating descriptor | In-game money only. **No purchase of in-game cash** (removes the "pay to gamble" vector). Hidden for under-18 and unknown users |

---

## 9. AI content rules

| Rule | Requirement | Relivable control |
|---|---|---|
| **Apple Guideline 1.2** (UGC; per Oct 2026 coverage, it explicitly covers AI content-creation apps) | Filtering, reporting with timely response, blocking, published contact info ([ithinkdiff](https://www.ithinkdiff.com/app-store-rules-ai-deepfakes-nudify-apps/)) | Moderation on every cloud output. **Report button** on AI text. Support email and in-app contact. A 48 h response SLA *(target)* |
| **Apple Guideline 5.1.2(i)** (Nov 2025) | Disclose and get **explicit permission** before sharing personal data with third-party AI ([TechCrunch](https://techcrunch.com/2025/11/13/apples-new-app-review-guidelines-clamp-down-on-apps-sharing-personal-data-with-third-party-ai)) | A first-use consent sheet naming the provider. On-device mode needs no third-party sharing. No PII in prompts (in-game names only) |
| **Apple age questionnaire** | Asks about AI-powered features ([9to5Mac](https://9to5mac.com/2025/07/24/apple-notifies-developers-of-new-app-store-age-rating-system/)) | Declare it truthfully. AI respects the same content flags |
| **Apple 2.5.19** (Oct 2026, secondary coverage) | No hidden or dormant features that differ from the reviewed build ([letsdatascience](https://letsdatascience.com/news/apple-revises-app-review-guidelines-for-ai-deepfakes-and-hid-76fdff63)) | The AI feature is present and described at review, not remotely enabled later |
| **Google Play AI-Generated Content policy** | **In-app reporting or flagging without leaving the app**. Prevent restricted content. Safeguards against prompt manipulation ([Google](https://support.google.com/googleplay/android-developer/answer/13985936?hl=en)) | Report button. Fixed server-side prompt templates. No free-text input to the model in Phase 3/4 |
| **Reputation** | inZOI's generative-AI announcement drew negative reviews (May 2025) ([Wikipedia](https://en.wikipedia.org/wiki/InZOI)) | AI is **optional, labelled, off by default**, and never in store headline copy ([[10 Go-to-Market]]) |

---

## 10. IP and clone risk

> [!info] Principle
> **Genre ideas and game mechanics are generally free to use.** A birth-to-death life sim, yearly "age up", stats bars, careers and generations are not ownable as ideas. **Expression is protected:** text, art, UI layout and look-and-feel (trade dress), names, logos and trademarks. *General principle, so confirm with counsel.* Candywriter has shown it will enforce: its agents sent a wrongful DMCA notice to AppleVis in Feb 2023, reversed the next day ([AppleVis](https://applevis.com/comment/144257)).

| Area | Do | Don't |
|---|---|---|
| Name | Clear "Relivable" (or the final name) through USPTO/EUIPO/WIPO trademark and App Store / Play name searches **before any public use** ([[_Concept Brief]]) | Use "Bit-" prefixes or "-Life" constructions confusingly close to BitLife's family (BitLife, DogLife, CatLife) without clearance |
| Product terms | Original names: e.g. *Relivable Plus*, *Destiny Mode*, *Rewind*, *Life Timeline*, *Bond %*, *Life Titles*, *Life Recap*, *Story Packs*, *Season Pass*, *Dynasty Ambitions*, *Wellbeing*, *Sparks* | Use **Bitizenship, God Mode, Boss Mode, Time Machine, Ribbons, Bitizen** or BitLife's pack names |
| Text | Write every storylet from scratch, with **writer originality attestations** and plagiarism spot-checks (n-gram similarity against public BitLife text, wikis and guides) | Copy, paraphrase or "reword with AI" BitLife event text, death messages or ribbon descriptions |
| Visual / trade dress | A distinct palette, typography, iconography, card layout, illustrated avatars and an icon that doesn't echo BitLife's | Mimic BitLife's stat-bar colours and layout, emoji-style icon, or screen composition |
| Store metadata | Generic sub-genre keywords ("life simulator", "life sim", "choices", "story game") | Use competitor trademarks in the keyword field, title or ads (store policy prohibits it; verify the current rule) |
| Marketing | Comparative claims that are true and substantiated ("every career free") | Use BitLife screenshots, logos or "BitLife 2" phrasing |
| Real-world | Fictional celebrities, brands and companies. Fictionalised countries' laws where needed | Use real people's names or likenesses, or real brands in negative scenarios |
| Era / historical mode | Sensitivity-reviewed historical content | — |

---

## 11. Mental-health and sensitive-content handling

| Theme | Approach |
|---|---|
| **Suicide and self-harm** | **Not a selectable player action.** If the narrative touches it (e.g. an NPC's death), use non-graphic language, no method detail, and a content note. Show a "Need to talk?" link to regional helplines (localised list maintained in Remote Config). *Recommendation for client approval* |
| Depression, anxiety, addiction | Shown as conditions with treatment paths (doctor, therapy, support group) and recovery arcs. Never played for laughs, never "solved" by a purchase |
| Eating disorders, body image | No weight-loss-as-reward loops. The "Looks" stat is tied to style and confidence, not body size *(design recommendation)* |
| Abuse, assault | Not depicted on-screen. Off-screen only, with a content note and support links. No player-perpetrated sexual violence of any kind |
| Illness, death, grief | Core to the genre. Handled with respect, with content notes for heavy beats and an optional "skip" with no penalty |
| Discrimination | NPCs may hold views, but the game never rewards hate. Inclusive character creation (a Change.org petition asks for this in BitLife) ([Change.org](https://www.change.org/topic/bitlife-en-us)) |
| Process | Every storylet tagged `sensitive_*` goes through **sensitivity review** (an external reader for mental-health and identity topics, budgeted) before approval. The simulation bot reports the frequency of sensitive events per life (cap: e.g. ≤ 3 heavy beats per decade *(target)*) |

---

## 12. Compliance checklist

| # | Item | Owner | Phase | Status |
|---|---|---|---|---|
| 1 | Trademark and store-name clearance for "Relivable" (or alternatives) | Client + IP counsel | **2** | ☐ |
| 2 | IP policy: writer originality attestation, banned-terms list, plagiarism check in CI | Narrative Lead | 2 | ☐ |
| 3 | Apple age questionnaire dry-run + IARC dry-run on the prototype content set | Producer | 2 | ☐ |
| 4 | Content flag taxonomy + toggles spec + sensitivity guidelines | Narrative Lead + UX | 2 | ☐ |
| 5 | Privacy policy, terms, **data-retention policy** (COPPA), cookie/CMP config | Privacy counsel + Producer | 3 | ☐ |
| 6 | Neutral age screen + Declared Age Range + Play Age Signals integration | Lead Engineer | 3 | ☐ |
| 7 | Age-band SDK gating (no ad ID or third-party sharing for under-18/unknown) | Lead Engineer | 3 | ☐ |
| 8 | DPIA (GDPR) + UK Children's Code risk assessment | Privacy counsel | 3 (before soft launch) | ☐ |
| 9 | CCPA "Do Not Sell/Share" + GPC on the web | Engineer + counsel | 3 | ☐ |
| 10 | Account deletion + data export in-app | Engineer | 3 | ☐ |
| 11 | Store privacy labels / Data Safety from the SDK inventory | Producer | 3, each release | ☐ |
| 12 | IAP catalogue age ratings (Texas, Utah) + significant-change notification step in the release checklist | Producer | 3 | ☐ |
| 13 | Monetization review: no paid randomness, real-money prices, exact SKU contents, "remove ads" removes all ads | Product Owner | 3 | ☐ |
| 14 | AI: consent sheet (5.1.2(i)), report button (Google), moderation, logging, questionnaire disclosure | Engineer + Producer | 3 (if AI ships in MVP) / 4 | ☐ |
| 15 | Accessibility: automated checks in CI + manual VoiceOver/TalkBack release gate | QA Lead | 2 → every release | ☐ |
| 16 | **External accessibility audit** (WCAG 2.2 AA / EN 301 549) + accessibility statement | QA Lead + vendor | 4 | ☐ |
| 17 | Localised legal texts (ES, PT-BR, DE, FR) + per-country consent-age table | Loc Manager + counsel | 4 | ☐ |
| 18 | Brazil review (ECA Digital, LGPD) before PT-BR launch | Counsel (BR) | 4 | ☐ |
| 19 | Web shop: tax/VAT, consumer-law disclosures, refund policy, link-out rules per region | Counsel + Producer | 4–5 | ☐ |
| 20 | Monitor: Texas appeal, Utah PRA (31 Dec 2026), Louisiana amendments, CA AB 1043, EU DFA draft, Google rate cards | Counsel (quarterly memo) | Ongoing | ☐ |
| 21 | UGC / Creator Mode moderation plan (Apple 1.2, report/block, teen exposure) | Product + counsel | 5 | ☐ |
| 22 | Helpline list localised and reviewed | Narrative Lead | 3 | ☐ |

See [[12 Risks and KPIs]] for the associated risks and [[11 Roadmap Team and Budget]] for the counsel and audit budget.
