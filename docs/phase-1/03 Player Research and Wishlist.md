---
title: Player Research and Wishlist
project: EverLife
phase: 1
tags: [everlife, phase-1, player-research, personas, wishlist, pain-points]
updated: 2026-10-26
---

# Player Research and Wishlist

> [!warning] Method and limits (read first)
> - **Reddit was mostly blocked.** The search tool refuses reddit.com as a domain, and only one Redlib mirror snippet (June 2023 r/bitlife and r/BitLifeApp posts) got through. This is **not** a scrape of r/BitLife, and there are **no upvote counts**.
> - **Evidence base:** Google Play and App Store reviews, AppleVis forum threads (a blind and low-vision community with long BitLife threads, 2019–2024), the BitLife Fandom wiki, Change.org topic pages, ComplaintsBoard, Metacritic, GameFAQs, Common Sense Media and a few reviews. Content-farm and "unblocked" pages were excluded or flagged.
> - **Ranking method:** themes are ranked by **how often they appeared independently across sources**, not by votes or survey share. Treat ranks as directional.
> - **Sample skew:** AppleVis is over-represented, which inflates accessibility signals relative to the general audience.
> - **Next step:** a researcher with direct Reddit access (or the Reddit API) should pull top "Suggestion" posts from 2023–2026, and Phase 2 playtests should validate these rankings ([[11 Roadmap Team and Budget]]).

## 1. Demographics (proxy evidence)
No published BitLife age or gender breakdown was found. The best available signals:

| Signal | Evidence | Source |
|---|---|---|
| Gender skew | Women are ~70% of family/farm-sim audiences (Quantic Foundry 2017). Ad-platform signals put female share of "online simulation gamers" at 51% (Texas) to 76% (Indonesia) | [Kotaku](https://kotaku.com/study-shows-which-video-game-genres-women-play-most-1791435415); [Start.io](https://www.start.io/audience/online-simulation-gamers-in-indonesia) |
| Teen reach | Rated 17+/18+ and PEGI 16, but with no age verification; Common Sense says 14+; parental guides target teens | [Hwb](https://hwb.gov.wales/keeping-safe-online/in-the-know/bitlife); [Common Sense Media](https://www.commonsensemedia.org/app-reviews/bitlife-life-simulator) |
| Geography | US is 43% of simulation-genre revenue; Stillfront calls BitLife a North American franchise; localised DE/BR/ES editions drove 72M lives in 12 months | [GameDevReports](https://gamedevreports.substack.com/p/sensor-tower-simulation-mobile-games); [Goodgame Studios](https://goodgamestudios.com/company/press/releases/72-million-virtual-lives-in-one-year-bitlife-impresses-internationally/) |
| Scale | US WAU peaked at 2.78M (Dec 2023); 1.0–1.4M in Q2 2025 | [Sensor Tower](https://sensortower.com/blog/2023-q4-unified-top-5-simulator%20games-units-us-60416e41241bc16eb8905c2f) |
| Creator culture | CallMeKevin's long-running BitLife series (from Dec 2019); a "chaotic playstyle" format | [TheTVDB](https://www.thetvdb.com/series/bitlife-callmekevin/seasons/official/1) |

**Working hypothesis *(inference)*:** the core audience is teens and young adults (roughly 16–30) in the US and other English-speaking markets, with a substantial female share and a strong creator-viewing habit. This must be validated with Sensor Tower or data.ai audience data and soft-launch analytics. It also interacts with the age-rating decision in [[09 Compliance and Ratings]].

## 2. Target personas
The personas are *hypotheses* built from recurring voices in the sources, not survey segments.

| | **Maya, "The Chaos Storyteller"** | **Jordan, "The Dynasty Builder"** | **Sam, "The Lapsed Veteran"** | **Alex, "The Screen-Reader Player"** |
|---|---|---|---|---|
| Profile | 17–22, plays in short bursts, watches life-sim YouTube/TikTok, shares screenshots | 22–35, long sessions, multi-generation runs, ribbon and achievement completionist | 24–34, played the genre since 2018, has paid before, quit in the last 1–2 years | Any age, blind or low-vision, VoiceOver/TalkBack user, active in accessibility communities |
| Goals | Outrageous moments, funny outcomes, something to post | A lasting family legacy; mastering systems; "beating" a life | The old magic without nickel-and-diming; fresh content | A full, independent experience; a game where nobody else has to read the buttons |
| Frustrations | 40-second ads for small actions; repetitive events; nothing to share but a tombstone | Unlimited generations paywalled; saves lost after updates or device change; opaque meters | Paywall creep; Boss Mode "future packs" promise not covering new packs; ads after buying no-ads | Unlabelled buttons; updates that break VoiceOver; minigames with no skip; hard-to-dismiss ads |
| Evidence | [Google Play](https://play.google.com/store/apps/eventdetails/4831791308351315470); [Metacritic](https://www.metacritic.com/game/bitlife-life-simulator/user-reviews/) | [BitLife Wiki: Generations](https://bitlife-life-simulator.fandom.com/wiki/Generations); [DroidWin](https://droidwin.com/bitlife-crashing-when-opening-menu-how-to-fix/) | [Change.org](https://www.change.org/p/stop-the-greed-of-bitlife-devs); [gnostalgic.org](https://www.gnostalgic.org/bitlife.php) | [AppleVis](https://applevis.com/comment/92141); [AppleVis](https://applevis.com/comment/94502) |
| EverLife hook | Life Recap cards, scenario seeds, storylets that surprise | Free generations, dynasty tree and goals, cloud saves, visible percentages | "Fair forever": one Plus unlock, all careers free, restore anywhere | Accessible by default; a11y QA is a release gate |
| Value to the business | Virality and installs | Retention and Plus conversion | Win-back and word of mouth | Loyal advocacy; EAA readiness; credibility |

## 3. Top complaints (ranked by frequency across sources)

| Rank | Pain point | Representative evidence |
|---|---|---|
| 1 | **Ad frequency and intrusiveness**, including ads that still play after buying ad removal | "Unplayable due to the excessive amount of ads" ([App Store](https://apps.apple.com/py/app/bitlife-life-simulator/id1374403536?l=en-GB)); "40 second ad" for gifts and music lessons ([Google Play](https://play.google.com/store/apps/eventdetails/4831791308351315470)); paid no-ads but still saw ads for the black market and praying ([ComplaintsBoard](https://www.complaintsboard.com/bitlife-life-simulator-b150146)) |
| 2 | **Paywall creep**: once-free features gated behind Bitizenship, God Mode, Boss Mode, packs, the Time Machine, even dark mode | "Now everything is locked behind a paywall" ([Chrome Web Store](https://chrome.google.com/webstore/detail/bitlife-life-simulator-un/hhjciojkfejbnacbiffmecpgppncglgj?hl=en)); "Why make people pay for dark mode?" ([Google Play](https://play.google.com/store/apps/eventdetails/4831791308351315470)); per-use Time Machine, "pay a dollar to undo death" ([AppleVis](https://www.applevis.com/comment/98823)) |
| 3 | **Lost purchases and saves** after a phone change, update or reinstall | 90% of packs gone and "Restore purchases" failed, rating cut from 5 stars to 1 ([Google Play](https://play.google.com/store/apps/eventdetails/4831791308351315470)); saves local only, no cloud sync ([DroidWin](https://droidwin.com/bitlife-crashing-when-opening-menu-how-to-fix/)) |
| 4 | **Repetitive, random, low-consequence play** | "Gets kinda repetitive" ([Metacritic](https://www.metacritic.com/game/bitlife-life-simulator/user-reviews/)); "passive decision-making" ([Blackscreen Gaming](https://blog.blackscreengaming.com/audio-games/bitlife-review/01/25/2019/)); "relies too heavily on random events" ([Mechanics of Magic](https://mechanicsofmagic.com/?p=5062)) |
| 5 | **Bugs, crashes and accessibility regressions** | Menu crash with no developer acknowledgement ([DroidWin](https://droidwin.com/bitlife-crashing-when-opening-menu-how-to-fix/)); VoiceOver broken, users warned others not to update ([AppleVis](https://applevis.com/comment/132456)) |
| 6 | **Hard-to-find actions and silent failures** in nested menus | "Too many nested elements" ([Mechanics of Magic](https://mechanicsofmagic.com/?p=5062)); activities silently fail when the character is too young ([AppleVis](https://applevis.com/comment/92232)) |
| 7 | **Opaque mechanics** | Relationship bars with no numbers ([AppleVis](https://www.applevis.com/comment/110061)); train robbery always "too early" ([Redlib mirror](https://redlib.belloworld.it/user/Alexio8008/submitted)) |
| 8 | **Challenges unfair to free players** | Weekly challenges "very hard for those who don't have expansion packs" ([AppleVis](https://applevis.com/comment/98850)) |

> [!note] Context
> Despite these complaints, BitLife holds 4.4 stars from about 1.29M Google Play reviews. Players love the core loop; their anger is about how it is monetised and maintained. That is EverLife's opening.

## 4. Top requested features (ranked by frequency across sources)

| Rank | Request cluster | Specific asks | Evidence |
|---|---|---|---|
| 1 | **Family and relationship depth** | Parents who divorce or remarry with lasting effects on the child; twins and triplets or siblings at birth; child support; relationship percentages; cars for kids who pass their test; generations not paywalled | [AppleVis](https://applevis.com/comment/98850); [AppleVis](https://mail.applevis.com/comment/99019); [Gameluster](https://gameluster.com/?p=32010) |
| 2 | **School depth** | Electives such as music and art that help admissions; teacher interactions; sports; school nurse | [AppleVis](https://mail.applevis.com/comment/99019); [AppleVis](https://mail.applevis.com/comment/99055) |
| 3 | **Home life** | Parties with a chosen guest list; clearer listings (pool?); road trips; a customisable stats bar | [AppleVis](https://www.applevis.com/comment/98871) |
| 4 | **New life systems and careers** | Religion (faith, services, family reaction, effects on marriage and politics); suing other characters with retaliation; homelessness; police academy | [Redlib mirror of r/bitlife](https://redlib.belloworld.it/user/Alexio8008/submitted); [AppleVis](https://applevis.com/comment/111030) |
| 5 | **Social, multiplayer and diversity** | Multiplayer mode; more inclusive character customisation (Change.org petitions) | [Change.org topic](https://www.change.org/topic/bitlife-en-us) |
| 6 | **Accessibility** | Restore and keep VoiceOver; option to skip maze minigames | [AppleVis](https://applevis.com/comment/134996); [AppleVis](https://applevis.com/comment/94502) |
| 7 | **Light versions of premium powers** | Mod APKs exist mainly to unlock God Mode and the Time Machine, which shows latent demand | [Gfinity](https://www.gfinityesports.com/article/mod) |
| 8 | **Fan concepts** | Eras from BCE to the future, traits, "no paywalls"; supernatural elements | [Gistly summary](https://gist.ly/youtube-summarizer/i-built-a-better-life-simulator-got-banned-by-bitlife); [itch.io](https://itch.io/post/8999680) |

> [!note] Pattern *(inference)*
> - Requests ask for **systemic consequence**, not just more content: a divorce that shapes the child, a lawsuit that brings retaliation, a faith that affects a marriage. That is pillar 1 (Every choice remembered).
> - BitLife already has a basic lawsuit activity ([Gamezebo](https://www.gamezebo.com/walkthroughs/bitlife-how-to-file-a-lawsuit-against-and-how-they-work/)), but it lacks the retaliation and long-tail consequence players describe.
> - Several requested areas (generations, house life, careers) have since been sold as paid packs, so players' wishes and the incumbent's paywalls overlap. Including them in the base game is a direct counter-position.

## 5. Features players love in rival games

| Rival | Loved feature | EverLife adoption |
|---|---|---|
| Alter Ego | Authored, multi-ending depth: "220,000 words" ([AppleVis](https://applevis.com/apps/ios/games/alter-ego)) | Storylet arcs and life chapters, with longer Ink/Yarn scenes where warranted |
| InstLife | Tabbed stats; make art or music and sell it; offline mode ([AppleVis](https://applevis.com/comment/97255)) | Skill-to-income loops; a tabbed stats sheet; offline-first single player |
| Another Life | Swipe micro-choices; game modes and challenges ([Dot Esports](https://dotesports.com/bitlife/news/best-games-like-bitlife)) | Swipe-to-choose on quick events (with button equivalents for accessibility) |
| The Sims Mobile | Avatars and home building ([GameSkinny](https://www.gameskinny.com/culture/top-10-best-games-like-bitlife-to-get-your-life-simulator-fix/)) | An avatar that ages; home customisation as cosmetics |
| Family Life | Idle multi-generation guidance ([Gameluster](https://gameluster.com/?p=32010)) | Dynasty Ambitions across generations |
| AI newcomers | NPCs that "remember and hold grudges" ([App Store](https://apps.apple.com/us/app/id6503607456)) | Deterministic NPC memory, with optional AI rewording only |

## 6. How EverLife answers each pain and request

| # | Pain / request | EverLife answer | Pillar | Detailed in |
|---|---|---|---|---|
| P1 | Intrusive ads; ads after paying | Opt-in rewarded ads only, frequency-capped, never mid-story; Plus removes **every** ad, with a QA test case for each placement | 3 | [[06 Monetization and Economy]] |
| P2 | Paywall creep | All careers and core systems free forever; one ~$9.99 Plus unlock; Story Packs add storylines and never lock careers; dark mode free | 3 | [[06 Monetization and Economy]] |
| P3 | Lost purchases and saves | Account-tied entitlements (RevenueCat, server-side StoreKit 2 / Play verification); Firestore cloud saves; restore on any device | 3 | [[08 Technical Architecture]] |
| P4 | Repetition and shallow randomness | Storylet engine with conditions, cooldowns and NPC memory; delayed consequences; life chapters and traits; simulator bot catches over-frequent events | 1 | [[04 App Breakdown - Core Life Systems]] |
| P5 | Bugs and accessibility regressions | Automated a11y checks plus manual VoiceOver/TalkBack pass as a release gate; Crashlytics; staged rollouts | 5 | [[08 Technical Architecture]], [[09 Compliance and Ratings]] |
| P6 | Nested menus, silent failures | Thumb-zone hub, contextual action cards, "What do you want to do?" search; locked actions greyed with a reason ("Unlocks at 18") | 2 | [[05 UX and Screen Map]] |
| P7 | Opaque mechanics | Relationship percentages; heists that explain why they failed; customisable stats bar | 2 | [[05 UX and Screen Map]] |
| P8 | Challenges unfair to free players | Every weekly challenge completable without purchases | 3, 4 | [[07 Retention and LiveOps]] |
| R1 | Family depth | Parents divorce or remarry with effects on kids; twins and triplets; siblings at birth; child support; free generations; dynasty family tree | 1, 4 | [[04 App Breakdown - Core Life Systems]] |
| R2 | School depth | Electives feeding admissions, teacher interactions, school sports | 1 | [[04 App Breakdown - Core Life Systems]] |
| R3 | Home life | Parties with guest lists, clearer listings, home customisation | 1 | [[04 App Breakdown - Core Life Systems]] |
| R4 | New systems | Religion; lawsuits with retaliation; deeper homelessness; military and police academy paths | 1 | [[04 App Breakdown - Core Life Systems]] |
| R5 | Social and diversity | Async social (visit friends' lives, shared challenges); inclusive avatar options; Creator Mode later | 4 | [[04 App Breakdown - Social, Meta and Premium]] |
| R6 | Accessibility | Full VoiceOver/TalkBack, dynamic type, colour-blind palettes, reduced motion, skippable or alternative minigames | 5 | [[05 UX and Screen Map]] |
| R7 | Premium powers | Destiny Mode (editor) and unlimited Rewind in Plus (one-time); free Rewind 1 per life + 1 per day via opt-in ad; never sold per use | 3 | [[06 Monetization and Economy]] |
| R8 | Eras, supernatural | Era/historical mode; optional themed scenario packs | 1 | [[07 Retention and LiveOps]] |
| — | Sharing (rival gap) | Life Recap cards, scenario seeds | 4 | [[10 Go-to-Market]] |

## 7. Evidence gaps
- No Reddit vote counts, Discord or X threads, or YouTube comment data.
- No 2025–2026 dated professional coverage of BitLife monetisation. The newest dated complaints are from 2024.
- No direct evidence for complaints about "AI-generated filler" in BitLife (searches returned nothing). We treat AI caution as a market-wide risk (inZOI), not a BitLife pain point.
- No player data on demand for offline play, achievements or caregiving for aging parents.

Related: [[02 Market and Competitors]] · [[12 Risks and KPIs]] · [[_Concept Brief]] · [[00 Home]]
