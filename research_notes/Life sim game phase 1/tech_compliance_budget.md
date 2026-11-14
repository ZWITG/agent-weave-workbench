# Tech Stack, Content Pipeline, Backend, Compliance & Budget for a BitLife-style Mobile Life Simulator (2025–2026)

Research date: 2026-10-25. Method: WebSearch only (page fetching blocked), so findings come from search-result snippets and summaries. Most sources are secondary (vendor blogs, law-firm alerts, press). Verify anything load-bearing against the primary vendor or statute page before it goes into a client contract.

## 1. Engine/framework comparison for a UI-heavy narrative mobile game

### Takeaway
Unity is the lowest-risk choice for a commercial BitLife-style game. It has the deepest mobile hiring pool and the most mature ad/IAP SDKs, BitLife's own studio hires for it, and since Unity 6 it has an official mobile screen-reader API. Flutter is a credible lower-cost option for a mostly-UI game and has better built-in accessibility. Godot 4.5 is free, but its screen-reader support is desktop-only (unconfirmed on mobile), which is a red flag for a text game.

### Cited Findings
- **What BitLife uses.** No official technical statement was found. Candywriter (BitLife's developer, part of Stillfront) has posted "Senior Unity3D Developer" roles for the BitLife team, and its listings ask for Unity and C# for cross-platform mobile games. — [Stillfront job posting](https://stillfrontgroup.teamtailor.com/jobs/7180715-senior-unity3d-developer); [Stillfront job posting 2](https://stillfrontgroup.teamtailor.com/jobs/5818637-senior-unity-developer)
- An AppleVis user says Candywriter's sibling game LifePop "migrated over to Unity" and links BitLife's VoiceOver problems to a Unity plug-in bug. This is user commentary, not an official source. — [AppleVis comment](https://applevis.com/comment/210590)
- **Unity pricing (from 1 Jan 2025).** The Runtime Fee was cancelled. Unity Personal is free up to $200K revenue/funding in the last 12 months (doubled from $100K), and the splash screen is optional with Unity 6. Above that, Pro costs $2,200/seat/yr (or $200/month), and Enterprise is required above $25M. — [Unity pricing updates](https://unity.com/pricing-updates); [Unity plans](https://unity.com/products?c=unity+engine)
- **Unity accessibility.** Since 2023.2 and Unity 6, the Accessibility module (AssistiveSupport, AccessibilityHierarchy) exposes UI to VoiceOver and TalkBack on iOS 13+ and Android 8.0+. The hierarchy is separate from GameObjects, so developers must sync it with visual elements by hand (UI Toolkit VisualElements included). Unity 6.3 added desktop screen readers. — [Unity blog: mobile screen reader support](https://unity.com/en/blog/engine-platform/mobile-screen-reader-support-in-unity); [Unity 6 manual](https://docs.unity3d.com/Manual/mobile-accessibility.html); [Unity 6.4 accessibility module](https://docs.unity3d.com/Manual/accessibility/module-intro.html); [Unity discussions 6.3](https://discussions.unity.com/t/native-desktop-screen-reader-support-now-available-in-unity-6-3/1681788)
- **Comparison blogs (directional only, some have a stake).** Unity "dominates mobile game development in terms of raw market share" and has a mature ad/IAP SDK pipeline. Flutter with Flame suits "2D casual, UI-heavy, turn-based" games and offers hot reload, but has a small game ecosystem. Godot is free/MIT and strong for 2D, though mobile performance is rated below Unity. — [tech-insider Godot vs Unity 2026](https://tech-insider.org/godot-vs-unity-2026/); [Oceanview Games](https://oceanviewgames.co.uk/blog/posts/unity-vs-godot-vs-unreal-2026); [DEV: Flutter game dev 2026](https://dev.to/synfinity-dynamics-pvt-ltd/flutter-game-development-in-2026-can-you-build-real-games-with-flutter-peh); [itch.io engine showdown](https://itch.io/blog/1067028/game-engine-showdown-2025-unity-vs-godot-vs-unreal-which-should-you-choose)
- **Flutter accessibility.** Standard widgets generate an accessibility tree automatically, and a `Semantics` widget customizes it for VoiceOver and TalkBack. — [Flutter docs: assistive technologies](https://docs.flutter.dev/ui/accessibility/assistive-technologies); [Droids On Roids guide](https://www.thedroidsonroids.com/blog/flutter-accessibility-guide-part-2)
- **Godot 4.5 accessibility.** Godot 4.5 added experimental screen-reader support via AccessKit for Control nodes. The integration is described for macOS, Linux and Windows. A forum user on 4.5 stable reports it works on a Windows export but not with Android TalkBack. — [Godot 4.5 release](https://godotengine.org/releases/4.5/); [Can I Play That](https://caniplaythat.com/?p=15209); [Godot forum Android thread](https://forum.godotengine.org/t/question-about-accessibility-on-android/122578)
- **React Native/Expo.** Expo documents using React Native Skia and Reanimated for 2D game-style rendering (UI-thread animation, Matter.js physics). No notable 2025 text games built on RN were found. — [Expo blog: 2D physics with Skia](https://expo.dev/blog/build-2d-game-style-physics-with-matter-js-and-react-native-skia); [Expo blog: Callie](https://expo.dev/blog/making-ai-feel-human-in-a-mobile-app-with-expo-reanimated-and-skia)
- **OTA updates.**
  - Microsoft retired App Center, and with it hosted CodePush, on 31 March 2025.
  - Expo EAS Update covers JS and assets but not native code.
  - Shorebird is the Flutter code-push option (Dart patches, rollback, signing).
  - Stores allow interpreted-code or asset updates that stay within the reviewed app experience; native changes still need a store release.
  - These sources are vendor blogs. — [Bitrise CodePush alternatives](https://bitrise.io/blog/post/codepush-alternatives); [Capgo live updates comparison](https://capgo.app/blog/best-live-updates-system-for-mobile-app/); [flutter_ota_kit pub.dev](https://pub.dev/packages/flutter_ota_kit)
- Apple App Review Guideline 2.5.19 (Oct 2026 update, per secondary coverage) bans hidden, dormant or undocumented features that differ from the reviewed build. This matters for any OTA or remote-config content strategy. — [letsdatascience](https://letsdatascience.com/news/apple-revises-app-review-guidelines-for-ai-deepfakes-and-hid-76fdff63)

### Inferences
- In a BitLife-style game, almost all content lives in data files (event JSON, strings, art atlases). Any engine can then hot-update content via remote config or downloadable bundles (Unity Addressables, Flutter asset download) without code push. That makes OTA code-push less decisive than it looks.
- **Recommended default: Unity 6 LTS.** Use UI Toolkit (or uGUI) plus the Accessibility module, with C# event and data systems. Cost is free under $200K, then about $2.2K/seat/yr.
- **Credible alternative: Flutter.** Pick it if the team is app-developer-heavy, the budget is tight, and avatars are simple layered 2D sprites. Flutter gives the best default accessibility for a text game, plus Shorebird OTA.
- Godot is not recommended until mobile screen-reader support is confirmed. Capacitor/web is viable for text, but it has weaker IAP/ads SDK maturity and perceived quality.
- 2D avatar rendering (layered paper-doll sprites) is trivial in all four. The deciding factors are hiring pool, monetization SDKs and accessibility, not rendering performance.

### Gaps
- There are no head-to-head performance benchmarks for UI-heavy mobile games across engines.
- No authoritative hiring-pool sizes by engine were found.
- No official confirmation of BitLife's engine was found.
- How Flame canvas content interacts with Flutter Semantics was not verified.

## 2. Content and narrative pipeline

### Takeaway
A BitLife-style game is best modeled as a storylet (quality-based narrative) system: hundreds to thousands of small events, each gated by conditions on stats, age, job and flags, and drawn by weight. Author these as data (JSON/YAML or spreadsheets) with a validator. Use Ink or Yarn Spinner only for the longer branching scenes inside events. Localize via Crowdin or Lokalise, starting with English plus 5–8 languages.

### Cited Findings
- **Storylets.** Failbetter Games coined the term storylet for Fallen London (2009): "pieces of story like mosaic tiles, not pipes". A storylet is typically a paragraph or two plus a choice. Access is gated by "qualities", numeric variables covering everything from inventory to story progress. The structure lets many short stories slot together without a fixed order. — [Emily Short: Beyond branching](https://emshort.blog/2016/04/12/beyond-branching-quality-based-and-salience-based-narrative-structures/); [videlais: Sculpturals and Storylets](https://videlais.com/tag/storylets/page/7/)
- **Ink vs Yarn Spinner.** Ink (inkle) is a "narrative scripting language… primarily designed for professional game development" with compact syntax and testing hooks. Yarn Spinner offers an accessible dialogue flow and community examples. Both are text-first, so they diff and merge well in version control, unlike node-heavy assets. — [inkle Ink](https://inklestudios.com/ink/); [PulseGeek Unity dialogue comparison](https://pulsegeek.com/articles/unity-dialogue-systems-comparison-for-writers/); [Tom Martin blog on Ink+Unity](https://tommartin.myblog.arts.ac.uk/?p=172)
- **articy:draft X.** The Unity importer is free (Asset Store v1.3.1, March 2026), but the main app is a per-seat subscription with no perpetual option. No indie price was found. — [articy integrations](https://www.articy.com/help/Integrations_Overview.html); [Unity Asset Store articy importer](https://assetstore.unity.com/packages/tools/integration/articy-draft-x-importer-269542); [articy FAQ](https://www.articy.com/en/support/frequently-asked-questions/)
- **Event-system lessons.** A Ludum Dare postmortem found events repeated too often because the event pool was too small, and editor-based authoring was slow and fragile. A commercial Steam life sim advertises "2000+ random events". Real Lives uses yearly rounds with random events (disease, floods, accidents). — [Penguin March postmortem](https://ilprinni.itch.io/penguin-march/devlog/143863/ludum-dare-46-postmortem); [Real Lives Wikipedia](https://en.wikipedia.org/wiki/Real_Lives_(video_game)); [Construct forum on probability tables](https://construct.net/en/forum/construct-3/how-do-i-8/random-events-155083)
- **Localization tooling.**
  - Lokalise (Nov 2025) replaced its plans with Explorer at $144/mo, then Growth, Advanced at $999/mo and Enterprise. It now bills per processed word and dropped its free plan (14-day trial only).
  - Crowdin lists from $59/mo (a $0–$450/mo range) and claims a Unity plugin that Lokalise lacks. That claim is vendor-reported.
  - [Locize comparison](https://www.locize.com/compare/lokalise-alternatives); [Capterra](https://www.capterra.com/compare/162858-163509/Lokalise-vs-Crowdin); [CostBench](https://costbench.com/compare/crowdin-vs-lokalise/); [Crowdin vs Lokalise](https://crowdin.com/lokalise-alternative)
- **Languages and markets.** The top game-revenue countries in 2025 were the US, China, Japan, South Korea and Germany, and Western Europe grew fastest. — [AppMagic via GameDev Reports](https://gamedevreports.substack.com/p/appmagic-mobile-market-landscape). The UK, Indonesia, India, Brazil (~$1.41B) and Taiwan follow. — [Allcorrect market index 2025](https://allcorrectgames.com/insights/mobile-game-market-index-2025-top-30-markets-growth-trends-opportunities/). The classic first set is EFIGS + CJK, with Brazilian Portuguese a common addition. — [LocalizeDirect](https://localizedirect.com/posts/which-languages); [Game Developer](https://gamedeveloper.com/business/what-languages-to-localize-your-mobile-game-into)
- **Precedent: localization as a separate deal.** BitLife's German and other localized editions were published in partnership with Goodgame Studios (Stillfront) as separate apps (e.g., BitLife BR, BitLife Español). — [Goodgame Studios](https://goodgamestudios.com/?p=65014); [App Store BitLife Español](https://apps.apple.com/app/id1607840241)

### Inferences
- **Recommended pipeline.**
  - Writers author events in a Google Sheet or Airtable, or as YAML in git.
  - Each event has an id, eligibility conditions (age range, stats, flags, country), a weight or cooldown, choices, and effects.
  - CI runs a schema and condition validator, with a simulator that runs 10k lives to find dead or over-frequent events, then exports JSON bundles.
  - Bundles are delivered via remote content download, so new events ship without app updates.
  - String keys sync to Crowdin or Lokalise.
  - Ink is optional, for multi-beat scenes.
- Text-heavy games are very localization-sensitive: there is high word count, and gendered grammar and variable substitution (names, pronouns, currency) are hard. Use ICU MessageFormat or plural rules from day one.
- **Launch languages.** Launch in English, then add ES (LatAm), PT-BR, DE, FR, plus possibly IT, JA and KO post-launch. Simplified Chinese matters only if targeting China or Taiwan (Traditional), which have their own licensing hurdles. BitLife's precedent suggests Spanish and Portuguese are high-ROI for this genre. That is an inference; no BitLife revenue-by-language data was found.

### Gaps
- No dated, primary price for Lokalise or Crowdin game plans was found, nor for articy indie licensing.
- No source gave BitLife's event count or authoring tooling.
- No professional per-word translation rates were searched.

## 3. Generative AI (LLMs) for dynamic events and NPC dialogue

### Takeaway
LLM text is now cheap per call, but it adds latency, moderation and store-policy obligations, plus a moderation surface that is risky for a game with crime, drugs and sex themes. The pragmatic 2026 design is a hybrid: a curated storylet core, with optional LLM "flavor" (rewording, NPC chat) behind a cheap model plus a moderation filter. On-device models (Apple Foundation Models) can be a free premium tier on recent iPhones.

### Cited Findings
- **Token prices.** Gemini 2.5 Flash-Lite and GPT-4.1 nano both cost $0.10 per 1M input tokens and $0.40 per 1M output tokens. — [Simon Willison](https://www.simonwillison.net/2025/Jul/22/gemini-25-flash-lite); [anotherwrapper comparison](https://anotherwrapper.com/tools/llm-pricing/gemini-2.5-flash-lite/gpt-4.1-nano-2025-04-14)
- **Cost per user (anecdotal, mostly vendor or indie sources).**
  - $0.10–0.50 per user per day.
  - About $0.05 per player-hour.
  - Per-turn tiers of $0.0001–0.001 (small talk), $0.001–0.005 (standard) and $0.01–0.05 (high-stakes), with a recommendation to route most turns to cheap models.
  - [abratabia latency & cost](https://abratabia.com/llm-npcs/latency-and-cost.php); [Respan AI NPC system](https://www.respan.ai/resources/building-ai-npc-system); [Cinevva reality check](https://app.cinevva.com/guides/ai-npcs-dialogue)
- **Latency targets.** About 500 ms for text dialogue, with TTFT under 100 ms ideal; streaming masks latency. Voice pipelines run 2–5 s. — [Cinevva](https://app.cinevva.com/guides/ai-npcs-dialogue); [abratabia](https://abratabia.com/llm-npcs/latency-and-cost.php)
- **Apple Foundation Models framework (iOS 26).** On-device, offline, with "no inference costs". Supports guided generation and tool calling. Requires an Apple Intelligence device (iPhone 15 Pro or newer) and supports EN, FR, DE, IT, PT-BR, ES, zh-Hans, JA and KO. No game examples were cited; showcased apps are productivity and journaling. — [9to5Mac](https://9to5mac.com/2025/09/29/apple-intelligence-ios-26-models-developers/); [ADTmag](https://adtmag.com/articles/2025/06/10/apple-launches-ondevice-ai-framework-and-tools.aspx); [Cult of Mac](https://www.cultofmac.com/news/apple-foundation-models-framework)
- **On-device on Android/mobile CPU.** Arm demoed fine-tuned LLMs running fully on-device in Unreal on mobile CPUs (ONNX Runtime + KleidiAI). No latency numbers were in the snippet. — [Arm community blog](https://developer.arm.com/community/arm-community-blogs/b/mobile-graphics-and-gaming-blog/posts/space-bartender-using-llms-in-unreal-nne-on-mobile-cpu)
- **Life-sim example: inZOI (Krafton, PC Early Access, 28 March 2025).**
  - inZOI uses NVIDIA ACE "Smart Zoi": an on-device ~0.5B-parameter Mistral NeMo Minitron SLM.
  - NPCs plan, act and reflect, and adjust their schedules.
  - Players can read inner thoughts and steer them with free text.
  - It runs on 8 GB RTX GPUs.
  - [NVIDIA GeForce news](https://www.nvidia.com/en-gb/geforce/news/nvidia-ace-naraka-bladepoint-inzoi-launch-this-month/); [NVIDIA ACE](https://developer.nvidia.com/ace)
- **Mobile example: AI Dungeon (Latitude).** A mobile AI text RPG with Story Cards and Memory Banks; reviewers note it can produce inconsistent narratives. — [TouchArcade](https://toucharcade.com/games/ai-dungeon-rpg-story-maker); [AppFollow listing](https://apps.appfollow.io/ios/ai-dungeon/1491268416?country=lu)
- **Moderation.** OpenAI's omni-moderation-latest (GPT-4o-based, text plus image) is free to use and more accurate in non-English languages. — [OpenAI model page](https://developers.openai.com/api/docs/models/omni-moderation-latest.md); [OpenAI announcement](https://openai.com/index/upgrading-the-moderation-api-with-our-new-multimodal-moderation-model/)
- **Google Play AI-Generated Content policy.** Apps that generate content with AI must provide in-app reporting or flagging without leaving the app. Developers must prevent restricted content (e.g., CSAM, deceptive content), and later updates add safeguards against prompt manipulation. — [Google Play policy](https://support.google.com/googleplay/android-developer/answer/13985936?hl=en); [9to5Google](https://9to5google.com/2023/10/25/google-play-gen-ai-policy/)
- **Apple App Review (per secondary coverage).**
  - Oct 2026: Guideline 1.2 (user-generated content) now explicitly covers AI content-creation apps. It requires filtering, reporting with timely response, blocking, and published contact info. — [ithinkdiff](https://www.ithinkdiff.com/app-store-rules-ai-deepfakes-nudify-apps/)
  - Nov 2025: Guideline 5.1.2(i) requires disclosure and explicit permission before personal data is shared with third-party AI. — [TechCrunch](https://techcrunch.com/2025/11/13/apples-new-app-review-guidelines-clamp-down-on-apps-sharing-personal-data-with-third-party-ai)
  - Apple's 2025 age-rating questionnaire also asks about AI-powered features. — [9to5Mac](https://9to5mac.com/2025/07/24/apple-notifies-developers-of-new-app-store-age-rating-system/)

### Inferences
- **Example cost.** A cloud LLM "flavor" pass is roughly 300 input + 150 output tokens per event on a nano or Flash-Lite model, about $0.00009 per event. At 100 events per session and 1 session/day, that is roughly $0.27/user/month. This is my calculation from cited prices. It is affordable for payers but material against free-to-play ARPDAU, so gate it behind a premium tier and cache aggressively.
- **Recommended architecture.**
  - The LLM never decides game-state effects (keeps balance, saves and anti-cheat deterministic).
  - It only rewrites or embellishes text, or powers optional NPC chat.
  - Calls go through a server proxy (key protection, rate limits, per-user budgets).
  - Every output passes a moderation check, with a canned fallback.
  - Provide an in-app report button (Google requirement).
  - Show disclosure and consent for third-party AI (Apple 5.1.2(i)).
  - Offer an AI-off toggle.
- Free-text player input to an LLM, in a game with sex and drug themes, sharply raises age-rating and moderation risk. Constrained choices (LLM rephrases preset options) are safer.

### Gaps
- No 2025–26 mobile life-sim shipping with LLM events at scale was found.
- No Android Gemini Nano / ML Kit GenAI details were searched.
- Apple's exact AI-related age-rating questionnaire wording was not retrieved.

## 4. Backend and services

### Takeaway
For a mostly-offline single-player sim, a light backend is enough: auth plus cloud save, remote config/content, analytics, crash reporting, and server-side IAP validation. **Firebase** (free Analytics, Crashlytics, Remote Config) plus **RevenueCat** (free to $2.5K/month tracked revenue, then 1%) is the fastest, cheapest path. Supabase suits SQL/Postgres preferences. PlayFab and Nakama earn their cost only with live-ops, economies or multiplayer.

### Cited Findings
- **Firebase.**
  - Free Firestore quota: 1 GiB storage, 50K reads/day, 20K writes/day, 10 GiB egress/month.
  - Blaze keeps the free quotas and bills overage. Reads cost $0.03–0.06 per 100K; sources conflict, and $0.03 is the newer nam5 figure.
  - Crashlytics and FCM are no-cost.
  - Cloud Storage requires the Blaze plan since 3 Feb 2026.
  - [Verdent Firebase pricing](https://www.verdent.ai/guides/devtools/firebase-pricing); [DEV Spark vs Blaze](https://dev.to/androve2k/spark-vs-blaze-the-firebase-pricing-guide-i-wish-id-read-sooner-onb); [Lido](https://lido.app/firebase/firebase-pricing)
- **Supabase.** Pro is $25/month with 100K MAU auth (one source says 50K, likely an error), 8 GB DB, 100 GB storage and 250 GB bandwidth. Extra MAU costs about $0.00325, and compute is billed separately (the $10 credit covers a Micro instance). — [Jetadmin Supabase 2026](https://www.jetadmin.io/blog/supabase-pricing-2026-guide-to-plans-limits-and-real-world-costs/); [MakerKit](https://makerkit.dev/blog/saas/supabase-pricing); [Schematic](https://schematichq.com/blog/supabase-pricing)
- **PlayFab.** Free for the first 1,000 lifetime players, then MAU, storage and compute based. Older references cite a $99/month Standard and a $1,999/month Premium tier, possibly outdated. — [Supercraft pricing comparison](https://gsb.supercraft.host/blog/game-backend-pricing-models-comparison/) (a competing vendor); [Back4App](https://blog.back4app.com/?p=3650)
- **Nakama.** Open source and free to self-host. Managed Heroic Cloud is DAU-tiered, listed "from $600/mo". — [Toolradar Nakama vs PlayFab](https://toolradar.com/compare/nakama-vs-playfab); [Supercraft](https://gsb.supercraft.host/blog/game-backend-pricing-models-comparison/)
- **RevenueCat.** Free up to $2,500 monthly tracked revenue (including one-time purchases), then 1% of tracked revenue. Accounts drop back to free if revenue falls below the threshold. — [RevenueCat pricing](https://www-docs.revenuecat.com/pricing); [RevenueCat account management docs](https://www.revenuecat.com/docs/welcome/set-up-revenuecat/account-management)
- **Apple receipt validation.** verifyReceipt and Server Notifications v1 are deprecated (no new features; end-of-life to be announced). Apple recommends the App Store Server API plus Notifications v2. With StoreKit 2, send the signed JWS transaction to your server and verify it there, using Apple's App Store Server Library (Swift, Java, Node, Python). — [Apple Developer Forums 731550](https://developer.apple.com/forums/thread/731550); [Apple Forums 758472](https://developer.apple.com/forums/thread/758472); [Adapty guide](https://adapty.io/blog/markdown/validating-iap-with-app-store-server-api.md)
- **Analytics.** Firebase/GA4 core analytics are free and the default for mobile event tracking. GameAnalytics has a free basic tier with revenue-scaled pricing (users cite aggressive scaling). Amplitude is freemium and best for funnels and retention. Many studios pair Firebase or GameAnalytics with an attribution tool. — [Bruin 2026 guide](https://getbruin.com/blog/best-analytics-tools-mobile-gaming-2026/); [Toolradar GameAnalytics alternatives](https://toolradar.com/alternatives/gameanalytics); [Back4App Firebase vs Amplitude](https://blog.back4app.com/firebase-analytics-vs-amplitude/)

### Inferences
- **Recommended MVP stack.**
  - Firebase: Auth with Apple/Google/anonymous sign-in, Firestore for cloud save as a compressed JSON blob per life, Remote Config plus Cloud Storage for event bundles, Analytics, Crashlytics.
  - RevenueCat for IAP and subscriptions, with server-side validation and webhooks to grant entitlements.
  - Cloud Functions for the LLM proxy and leaderboards (or Game Center / Play Games leaderboards for free).
  - Expected cost at 100K MAU is likely tens to low hundreds of dollars a month, excluding LLM spend. That is an inference from free quotas, since saves are small and infrequent.
- **Anti-cheat.** In a single-player sim, the only cheating that matters financially is IAP spoofing and modded currency. Server-side receipt validation (RevenueCat or the App Store Server API / Play Developer API) plus server-authoritative premium entitlements is sufficient. Local stat tampering is low-stakes unless leaderboards exist.
- **Legal knock-ons.** Analytics or ad SDKs that share data with ad networks can be a CCPA "sale" (see section 5). They must be configured per age band, using child-directed or under-age flags.

### Gaps
- No Google Play Developer API purchase-verification details were retrieved.
- Official PlayFab, Heroic Cloud and Remote Config pricing pages were not verified.
- No GameAnalytics or Amplitude tier limits were found.

## 5. Compliance (age gating, ratings, privacy, state laws, accessibility, loot boxes)

### Takeaway
A life sim with crime, drugs and sex references will land at Apple 16+ or 18+ (BitLife is 17+ under the old system), Google "Mature 17+", and around PEGI 16. Treat it as a general-audience/teen game that is not directed to children: neutral age gate, block under-13s (or a strict child mode), and follow COPPA's amended rule (compliance date 22 Apr 2026).

2026 adds US app-store accountability laws:
- **Texas:** in force since a July 2026 SCOTUS order.
- **Utah:** developer duties from 6 May 2026.
- **Louisiana:** effective 1 July 2026, amended.

These require consuming Apple's Declared Age Range and Google's Play Age Signals APIs, and rating the app and its IAPs. Accessibility (EAA in the EU, plus VoiceOver/TalkBack expectations) and loot-box rules (Brazil minors ban, Belgium) shape design.

### Cited Findings
- **Comparable rating.**
  - Apple lists BitLife as 17+. Descriptors: mild alcohol/tobacco/drug references, profanity/crude humor, simulated gambling, cartoon violence, sexual content and nudity, frequent/intense mature themes. — [App Store BitLife](https://apps.apple.com/jp/app/bitlife-life-simulator/id1374403536?l=en-US)
  - Google Play shows "Mature 17+". — [Prima Games](https://primagames.com/tips/is-bitlife-for-kids-bitlife-kids-warning-guide)
  - A Welsh government guide says PEGI 16. — [Hwb Wales](https://hwb.gov.wales/keeping-safe-online/in-the-know/bitlife)
  - Candywriter's terms say the service is not directed to under-16s. — [Qustodio](https://www.qustodio.com/blog/is-bitlife-safe-for-kids/)
- **Apple 2025 age ratings.**
  - New tiers are 4+, 9+, 13+, 16+ and 18+; 12+ and 17+ were removed.
  - Ratings are per region.
  - The new questionnaire covers violence, IAP, AI features, wellness and interactive elements.
  - Developers had to answer it by 31 Jan 2026 or be blocked from updates.
  - [9to5Mac](https://9to5mac.com/2025/07/24/apple-notifies-developers-of-new-app-store-age-rating-system/); [iPhone in Canada](https://www.iphoneincanada.ca/2025/07/25/updated-app-store-age-ratings); [Business Today](https://www.businesstoday.in/amp/technology/news/story/apple-overhauls-app-store-age-ratings-adds-new-13-16-and-18-categories-486587-2025-07-28)
- **Google Play / IARC.** One questionnaire in Play Console yields ratings from multiple authorities (ESRB, PEGI, USK and others). Misrepresenting content can lead to removal, and authorities can override ratings. — [Google Play Help](https://support.google.com/googleplay/android-developer/answer/9898843?hl=en); [Digital Turbine guide](https://www.digitalturbine.com/blog/how-age-ratings)
- **COPPA amended rule.** Effective 23 June 2025, with compliance by 22 April 2026 (some provisions excepted). Changes:
  - Expanded personal-information definition, including biometrics.
  - Separate consent for third-party disclosure (e.g., ads).
  - A written data-retention policy posted in the privacy notice.
  - Tighter security duties.
  - Separately, a Feb 2026 FTC policy statement eases enforcement when children's data is used only for age verification. — [Federal Register](https://www.federalregister.gov/documents/2025/04/22/2025-05904/childrens-online-privacy-protection-rule); [BBB Programs](https://bbbprograms.org/media/insights/blog/coppa-amended); [Davis Polk](https://www.davispolk.com/index%2ephp/print/pdf/node/116375); [Bass Berry](https://bassberry.com/news/amendments-to-the-coppa-rule-now-in-effect/)
- **Texas SB 2420 (App Store Accountability Act).**
  - Signed 27 May 2025, effective 1 Jan 2026.
  - Developers must assign age ratings to apps and IAPs, use store-provided age category and parental-consent signals, and limit and delete verification data.
  - Exposure includes AG enforcement and civil penalties (one guide: up to $10K per violation).
  - "Developer" is undefined.
  - [Pillsbury](https://www.pillsburylaw.com/en/news-and-insights/app-store-accountability-act-texas.html); [Reed Smith](https://www.reedsmith.com/our-insights/blogs/viewpoints/102kddh/texas-law-requires-age-verification-for-app-stores-and-developers/); [Texas House bill analysis](https://lrl.texas.gov/scanned/srcBillAnalyses/89-0/SB2420RPT.PDF); [CompliancHub guide](https://compliancehub.wiki/texas-sb2420-complete-compliance-guide-for-app-stores-and-developers/)
- **Texas litigation.** A preliminary injunction issued 23 Dec 2025 (First Amendment). The Fifth Circuit stayed it (May–June 2026), and on 6 July 2026 the Supreme Court declined to vacate the stay, so the law is enforceable pending appeal. — [JURIST](https://www.jurist.org/news/2025/12/us-federal-court-blocks-texas-app-store-age-verification-law/); [CCIA](https://ccianet.org/news/2026/05/appeals-court-pauses-injunction-on-texas-app-store-law-that-likely-violates-first-amendment/); [Wikipedia CCIA v. Paxton](https://en.wikipedia.org/wiki/Computer_%26_Communications_Industry_Association_v._Paxton); [WLF](https://www.wlf.org/case/computer-communications-industry-assn-v-paxton/)
- **Utah SB 142, amended by HB 498 (2026).** Store and developer duties from 6 May 2026; private right of action from 31 Dec 2026. Developers must age-rate, notify stores of significant changes, and use store age/consent signals for Utah users. — [Stoel Rives](https://www.stoel.com/insights/publications/utahs-app-store-accountability-act-goes-into-effect); [Utah HB 498](https://le.utah.gov/Session/2026/bills/introduced/HB0498S02.pdf)
- **Louisiana HB 570.** Effective 1 July 2026, amended by HB 977 (2026). It explicitly rejects a developer good-faith safe harbor. — [Bass Berry](https://www.bassberry.com/news/apps-and-minors-new-compliance-frontiers-and-risks-in-louisiana-utah-and-texas/); [FPF comparison chart](https://fpf.org/wp-content/uploads/2026/06/FPF-Legislation-TX-UT-LA-App-Store-Accountability-Act-Comparison-Chart.pdf); [Wiley alert](https://www.wiley.law/alert-State-App-Store-Accountability-Acts-Introduce-New-Obligations-for-App-Developers)
- **Platform age APIs.**
  - Apple's Declared Age Range API requires iOS 26+.
  - Google Play Age Signals returns bands 0–12, 13–15, 16–17 and 18+. It was in beta, returns real data only where laws apply, and is expanding to all markets by end of 2026 (Australia and Canada from mid-Aug 2026).
  - [Appbot guide](https://appbot.co/blog/age-verification-apis-for-apps-google-apple/); [pub.dev age_range_signals](https://pub.dev/documentation/age_range_signals/latest/); [BetaNews](https://betanews.com/article/google-play-age-signals-api-global-rollout/); [DEV Age Signals guide](https://dev.to/mr_manushukla/google-play-age-signals-api-a-2026-android-integration-guide-for-age-ranges-without-collecting-ids-5cde)
- **GDPR and UK Children's Code.**
  - The default digital-consent age is 16; member states may lower it to 13. Examples: 13 in DK, SE, PT and the UK; 14 in ES; 15 in FR and GR; 16 in DE and RO (2021 survey).
  - The UK Age Appropriate Design Code applies to services likely accessed by under-18s. It has 15 standards: best-interests default, geolocation off, no nudge techniques.
  - The ICO issued games guidance in Feb 2023: do a risk assessment and establish age with reasonable certainty.
  - [Library of Congress](https://blogs.loc.gov/law/2021/06/new-report-on-childrens-online-privacy-and-data-protection-published/); [Bird & Bird](https://twobirds.com/insights/2020/uk/icos-publishes-age-appropriate-design-code); [Inside Privacy](https://www.insideprivacy.com/?p=14337)
- **CCPA/CPRA.** With actual knowledge (including willful disregard) that a user is under 16, selling or sharing their data requires opt-in: from the user if 13–15, from a parent if under 13. Sharing with third-party ad providers can count as a "sale". — [IAPP](https://iapp.org/news/a/can-organizations-sell-data-of-children-under-16-under-the-ccpa); [Perkins Coie](https://perkinscoie.com/insights/blog/california-attorney-general-approves-new-regulations-governing-california-consumer); [CPPA AB 1949 memo](https://www.cppa.ca.gov/meetings/materials/20240510_item3_ab1949_memo.pdf)
- **European Accessibility Act (applies from 28 June 2025).** It covers e-commerce services, including via mobile apps. One law firm argues in-app purchases can bring an app into scope (an interpretation, not official). Service microenterprises (fewer than 10 staff and ≤€2M turnover or balance sheet) are exempt; sources differ on how broad that is. — [Travers Smith](https://www.traverssmith.com/knowledge/knowledge-container/a-new-milestone-for-accessibility-the-european-accessibility-act-now-applies/); [Herzog EAA PDF](https://herzoglaw.co.il/wp-content/uploads/2025/06/The-European-Accessibility-Act.pdf); [Irish CCPC microenterprise guidance](https://www.ccpc.ie/business/enforcement/accessibility/european-accessibility-act-guidelines-for-microenterprises/); [accessible.org](https://accessible.org/top-10-eaa-questions/)
- **BitLife accessibility history (AppleVis).** Fully accessible circa v3.8 (2020). A 2022 update re-added VoiceOver support, though it was clunky. A later report says VoiceOver reads nothing (a regression, attributed by a user to a Unity plug-in), and users recommended LifePOP instead. — [AppleVis BitLife](https://www.applevis.com/comment/92772); [AppleVis release notes thread](https://applevis.com/comment/135435); [AppleVis later comment](https://applevis.com/comment/210590)
- **Loot boxes.**
  - Brazil's ECA Digital (signed Sept 2025, effective around March 2026) bans loot-box sales to minors, defined by mechanics. Fines reach 10% of revenue. A June 2026 court ordered Riot to pay damages and required probability disclosure.
  - Belgium treats loot boxes as gambling (up to €800K and 5 years in prison, doubled if minors are involved).
  - Poland has a draft licensing rule.
  - An EU Digital Fairness Act ban is not expected before 2028.
  - [Programming Insider](https://programminginsider.com/loot-boxes-regulation-and-where-the-line-sits-in-2026/); [Sheep Esports](https://www.sheepesports.com/articles/brazil-court-orders-riot-games-to-pay-eur2-5m-over-league-of-legends-loot-boxes/en); [WN Hub](https://wnhub.io/news/legal/item-48938)
- **Simulated gambling.** BitLife's Apple descriptors include "simulated gambling" (casino, lottery). — [App Store BitLife](https://apps.apple.com/jp/app/bitlife-life-simulator/id1374403536?l=en-US)

### Inferences
- **Compliance checklist for the plan.**
  1. Answer the Apple questionnaire (expect 16+ or 18+) and IARC on Play (expect Mature 17+, PEGI 16/18). Rate IAPs separately for Texas and Utah.
  2. Neutral age screen at first launch, plus Declared Age Range / Play Age Signals where available. Block under-13s, or route them to a no-ads, no-AI, no-data-sharing mode. Under-13s should simply be blocked given the content.
  3. COPPA: since the game is not child-directed, actual knowledge triggers duties. Run no behavioral ads and no third-party sharing for unknown or under-age users, and publish a retention policy.
  4. GDPR/UK: consent management (CMP) for ad SDKs, a DPIA, UK Children's Code defaults for under-18s (no nudges, high-privacy defaults), and data-subject rights flows (account deletion is also required by Apple and Google).
  5. CCPA: "Do Not Sell/Share" handling and opt-in for under-16s.
  6. Respect state laws' handling of parental-consent revocation and significant-change notification.
  7. Loot boxes: avoid paid random rewards, or geo-disable them in Belgium and for Brazilian minors, and disclose odds everywhere. Keep in-game gambling purely simulated with no cash-out.
  8. AI: Google in-app report button, Apple 1.2 safeguards and 5.1.2(i) consent, moderation, and AI disclosure in the rating questionnaire.
  9. Accessibility: target WCAG 2.2 AA-equivalent for mobile (EN 301 549 is the EAA harmonized standard; this is from my knowledge, not searched). Cover VoiceOver/TalkBack labels, dynamic type, contrast, no time-pressure, and colorblind-safe stats. Make accessibility QA a release gate, since BitLife's regressions show it breaks silently.
- Teen exposure is the crux. A 16+/18+ rating cuts the teen audience that drives BitLife-style virality, while a 13+ "softened" mode adds content-variant cost. Raise this as a client decision.

### Gaps
- Apple's 16+ vs 18+ thresholds for "frequent mature themes" and "sexual content" were not retrieved from primary docs.
- The status of California AB 1043 (Digital Age Assurance Act, 2027) was not found.
- No ESRB rating for BitLife was found.
- Whether Apple extended the 31 Jan 2026 questionnaire deadline was not verified.
- Effective-date shifts from the Utah HB 498 and Louisiana HB 977 amendments need statutory confirmation.
- No PEGI "paid random items" descriptor details were found.

## 6. Team size, timeline and budget (MVP and full launch)

### Takeaway
No source benchmarks text-life-sims specifically. General indie data plus regional rates suggests:
- **MVP:** a lean 3–5 person team for 4–6 months, roughly $60K–$250K depending on region.
- **Polished launch:** 6–10 people for 9–14 months, roughly $250K–$900K, with content writing and localization as the dominant variable costs.

### Cited Findings
- **Indie budgets.** From $10K (solo 2D mobile) to $2M+ (polished 3D). Most indie projects run $10K–$500K. — [Juego Studio](https://juegostudio.com/blog/indie-game-development-cost); [Pixune 2026 breakdown](https://pixune.com/blog/how-much-does-it-cost-to-make-a-game/)
- **Timelines.** 6–24 months for indie; a 2–3 person mid-scope game takes 6–12 months. — [StudioKrew](https://studiokrew.com/blog/indie-vs-aa-vs-aaa-games-budgets-teams-technology-differences/); [Oceanview timeline estimator](https://oceanviewgames.co.uk/resources/game-development-timeline-estimator)
- **Hourly rates (2025–26, vendor sources, wide variance).**
  - US: game freelancers ~$85–135/hr (Flexiple says $60–100); mid-level mobile $120–160/hr; agencies $150–250+.
  - Eastern Europe: ~$50–80/hr for games; $45–70/hr for mobile.
  - LatAm: ~$30–70/hr.
  - India/South Asia: ~$19–50/hr.
  - Effective cost adds PM, reviews and rework.
  - [SecondTalent](https://www.secondtalent.com/cost-to-hire/game-developer/); [Flexiple](https://flexiple.com/cost-to-hire/game-developer); [LowCode Agency](https://www.lowcode.agency/blog/mobile-app-developer-hourly-rates); [Whimsy Games outsourcing guide](https://whimsygames.co/blog/complete-guide-to-game-development-outsourcing-costs/)
- **Comparable outcome (BitLife).**
  - 2019 revenue ~$26M with a 59% EBIT margin; ~1.2M DAU and 7.8M MAU; 42M downloads; a top-5 iOS download in 2019.
  - Stillfront paid ~$74.4M upfront plus up to $120.6M earn-out (total ≤$195M).
  - Founded 2006 by Kevin O'Neil and Nadir Khan.
  - [Stillfront press release](https://www.stillfront.com/en/stillfront-group-acquires-candywriter-llc-and-discloses-updated-pro-forma-figures-for-2019/); [PocketGamer.biz](https://www.pocketgamer.biz/news/73190/stillfront-group-acquires-bitlife-developer-candywriter/)
- **Tool costs.**
  - Unity: free under $200K, then $2,200/seat/yr. — [Unity](https://unity.com/pricing-updates)
  - RevenueCat: 1% over $2.5K MTR. — [RevenueCat](https://www-docs.revenuecat.com/pricing)
  - Supabase Pro: $25/month. — [Jetadmin](https://www.jetadmin.io/blog/supabase-pricing-2026-guide-to-plans-limits-and-real-world-costs/)
  - Lokalise: $144–999/month; Crowdin: from $59/month. — [Locize](https://www.locize.com/compare/lokalise-alternatives); [Capterra](https://www.capterra.com/compare/162858-163509/Lokalise-vs-Crowdin)

### Inferences
These ranges are my estimates, built from the cited rates. They are not sourced benchmarks; label them as such in the client plan.

**MVP** (English only, ~500–800 events, core loop of age-up, stats, jobs, relationships, crime, a few activities, simple layered avatars, ads plus 1–3 IAPs, cloud save, analytics). The team is about 4.5 FTE for 5 months (~22 person-months):
- 1 lead/gameplay engineer
- 1 UI/mobile engineer
- 1 writer/narrative designer, plus 1 contract writer
- 0.5 2D artist/UI designer
- 0.5 QA
- 0.5 producer/designer

| Region | Blended rate | Labor cost (~3,500 h) |
|---|---|---|
| US | ~$110/h | ~$385K |
| Eastern Europe | ~$60/h | ~$210K |
| LatAm | ~$50/h | ~$175K |
| India | ~$30/h | ~$105K |

A founder-led or hybrid team with an offshore engineer could plausibly land at $60–150K.

**Full launch** (2,000–4,000+ events, 5–8 languages, accessibility audit, legal, live-ops tooling, optional AI tier). The team is 6–10 FTE for 9–14 months (~70–110 person-months):
- Eastern Europe or LatAm: roughly $500K–$1.1M.
- US: $1.2–2M.

Also budget for:
- Localization at roughly 150–300K words × 5–8 languages. Per-word rates were not searched, so this is a gap.
- Legal and privacy counsel, roughly $15–50K. My estimate, not sourced.
- Ongoing UA spend, which often exceeds dev cost for mobile.

**Phasing recommendation.**
1. A 6–8 week prototype to validate the event engine and simulator.
2. A soft launch in 1–2 English markets (e.g., Canada, Australia, Philippines) to tune D1/D7 retention.
3. Content scale-up and localization.
4. Global launch.

Writing throughput, not engineering, is the critical path in this genre. Plan for 10–30 polished events per writer-day, with a validator. This throughput figure is an inference and unsourced.

### Gaps
- No team-size or budget benchmarks specific to text-based life sims, or BitLife's headcount history, were found.
- No per-word game translation rates were found.
- No UA/CPI benchmarks for the simulation genre were searched.
- Candywriter's current headcount and 2024 revenue were not found.
