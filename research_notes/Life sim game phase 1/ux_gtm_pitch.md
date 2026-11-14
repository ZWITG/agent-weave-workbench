# UX/UI Design, Go-to-Market, and Pitching for a Redesigned BitLife-Style Mobile Life Simulator (2025–2026)

Method note: page fetching was blocked by the proxy, so these notes come from ~19 WebSearch queries and the search engine's snippet summaries. Each claim links to the result URL it came from. Many sources are vendor blogs, so "vendor claim" flags figures that aren't independently verified. Where the search summary named an underlying source (e.g., GameAnalytics, Liftoff, Chartboost) but the URL holding it is uncertain, I say so.

## 1. Mobile game UX best practices for text/menu-heavy games (thumb zone, hierarchy, cards, typography, haptics, dark mode, FTUE, menu depth, accessibility)

### Takeaway
Put the main action ("Age Up"), navigation and choice buttons in the bottom thumb zone. Replace deep nested menus with fewer, labeled, context-aware cards. Respect OS accessibility settings (Dynamic Type, Reduce Motion, screen readers, color-independent cues). Use haptics sparingly. Get players into a first life within about 60 seconds, with features unlocking as the character ages. BitLife's own accessibility feedback (unlabeled buttons, activities hidden across several menus) shows exactly where a redesign can improve.

### Cited Findings
**Thumb zone / one-handed use**
- Steven Hoober coined "thumb zone" (*Designing Mobile Interfaces*): the screen area a thumb reaches easily when the phone is held in one hand. — [Fluid UI blog](https://blog.fluidui.com/the-thumb-zone/)
- Hoober's field research found users frequently change grip based on comfort and situation, so designers should test real grips rather than assume one. The widely quoted "49% of users hold phones one-handed" figure is attributed to Hoober, but the original data wasn't verified. — [Smashing Magazine](https://smashingmagazine.com/2020/02/design-mobile-apps-one-hand-usage/)
- Put navigation and essential controls at the bottom. Avoid primary buttons in top corners (thumb stretch). Small or tightly packed targets cause mis-taps. — [GeeksforGeeks](https://www.geeksforgeeks.org/?p=1222363); [BrightHR engineering](https://engineering.brighthr.com/blog-post/designing-for-thumbs)
- An academic paper on mobile game input reachability documents games deliberately putting mute/close/skip controls for ads and IAP offers in unreachable zones. It frames this as an ethics and thumb-health issue. — [CMS Conferences paper](https://openaccess.cms-conferences.org/publications/book/978-1-964867-13-7/article/978-1-964867-13-7_13)
- In a small study, 8 of 10 participants preferred bottom-to-top swipes over top-to-bottom; top-down swipes were harder to reach on large phones. — [52 weeks of interaction design (UX Collective Bootcamp)](https://bootcamp.uxdesign.cc/52-weeks-of-interaction-design-f09e9fb145d7)

**Card-based UI / swipe decisions**
- Cards suit screens that show many content types without overwhelming the user. — [UX Design Institute](https://www.uxdesigninstitute.com/blog/wp-json/wp/v2/posts/10413)
- Swipe-left/right decisions were popularized by Tinder and feel like flipping through an endless deck (the lineage of Reigns-style choice cards). — [UX Design Institute / CareerFoundry search results](https://careerfoundry.com/en/wp-json/wp/v2/posts/5118)
- Touch interactions work best when they show "physical verisimilitude" (they behave like the physical object they imitate). — [Glide community](https://community.glideapps.com/t/swipe-layout-is-now-in-production/21474/81)

**BitLife-specific pain points (evidence for the redesign)**
- Blind players on AppleVis say activities are spread across the School, Relationships and "More" buttons and unlock with age. Activities silently fail to open when the character is too young. — [AppleVis BitLife page](https://www.applevis.com/apps/ios/games/bitlife); [AppleVis comment](https://applevis.com/comment/92232)
- A VoiceOver user couldn't use the School screen because its buttons had no labels. Another user had to explain them ("study harder", one that does nothing, "drop out"). — [AppleVis comment](https://applevis.com/comment/92141); [AppleVis comment](https://applevis.com/comment/92143)
- An app-audit site says complaints that aggressive monetization / pay-to-win gate core features are common in BitLife reviews. Treat this as secondary, AI-generated analysis. — [Marlvel BitLife intel report](https://marlvel.ai/intel-report/games/bitlife-life-simulator)

**Accessibility**
- The Game Accessibility Guidelines name colorblindness, remapping, text size and subtitles as the most complained-about issues. They also recommend large, well-spaced touch controls, adjustable game speed, and operating the UI with the same input as gameplay. — [Game Accessibility Guidelines (basic)](https://gameaccessibilityguidelines.com/basic/)
- Cover red-green and blue-yellow deficiencies, and never use color as the only carrier of information. — [Games for Change accessibility tips (PDF)](https://gamesforchange.org/studentchallenge/wp-content/uploads/2022/01/Tips_Resources_for-Considering-the-Needs-of-Disabled-Gamers-in-Design.pdf)
- Pair every color cue with a shape, pattern or text label, and offer a dedicated colorblind palette. This is a commercial site. — [Abratabia](https://abratabia.com/game-accessibility/visual-accessibility.php)
- Apple (WWDC19 "Visual Design and Accessibility"): apps should check Reduce Motion and adapt or stop auto-playing animation. Text should scale with Dynamic Type without truncation, and icons should scale with it. — [WWDC Notes](https://wwdcnotes.com/documentation/wwdc19-244-visual-design-and-accessibility/)
- Roblox exposes a reduced-motion property that developers read to shorten or remove UI tweens, an example of honoring the setting in-game. — [Roblox docs](https://create.roblox.com/docs/production/publishing/accessibility.md)
- A University of Dundee study found few developers knew the W3C accessibility guidelines as applied to mobile games. — [Dundee](https://discovery.dundee.ac.uk/en/publications/w3c-accessibility-guidelines-for-mobile-games/)

**Haptics**
- Apple's HIG: haptics add touch to apps and games. The system may pair them with visual and audio feedback, and standard controls (switches, sliders, pickers) already produce haptics on supported iPhones. — [Apple HIG – Playing haptics](https://developer.apple.com/design/human-interface-guidelines/playing-haptics.md)
- Use the standard success/error/selection patterns purposefully and match intensity to the animation. — [Uxcel Apple HIG course](https://app.uxcel.com/courses/apple-hig/accessibility-inclusion-standards-812/audio-and-haptic-feedback-0671)
- FanDuel's design system warns that a haptic on every tap or navigation is excessive. — [FanDuel design – haptics](https://fanduel.design/formation/guidelines/haptics)

**Onboarding / FTUE**
- Roblox: the FTUE is the first few minutes and is measured by D1 retention. Good onboarding teaches the essentials, gets to the fun quickly, and leaves players wanting more. — [Roblox onboarding docs](https://create.roblox.com/docs/production/game-design/onboarding)
- Unity: most players never return after their first session, so surface the best features early. — [Unity retention guide](https://unity.com/how-to/improve-retention-every-stage-player-lifecycle)
- Introduce one mechanic at a time and unlock features gradually. — [Adrian Crook](https://adriancrook.com/?p=8055)
- Get players into core gameplay within about 60 seconds, before tutorials, settings or account creation. "Optimized onboarding lifts retention up to 50%" is a vendor claim. — [Playio](https://blog.playio.co/mobile-game-onboarding-retention)
- Don't push social prompts at first launch, but build reasons to return (goals, rewards). — [PocketGamer.biz PGC Digital](https://www.pocketgamer.biz/news/77289/pgc-digital-how-to-enhance-the-first-time-user-experience/)
- Metacore talk on perfecting FTUE (PlaytestCloud write-up): test with real players. — [PlaytestCloud](https://start.playtestcloud.com/blog/perfecting-the-first-time-user-experience-in-mobile-games)

### Inferences
- An age-gated progressive unlock already fits the life-sim fantasy: a baby has few actions, an adult many. A redesign can turn BitLife's hidden "More > Activities > sub-menu" into one contextual action sheet that shows locked actions greyed out with a reason ("Unlocks at 18"), instead of failing silently as AppleVis users report.
- Thumb-zone layout: bottom tab bar (Life / Assets / Relationships / Activities), a large central "Age Up" button in the natural arc, and event choice buttons stacked in the lower half of the card.
- For accessibility, every icon-only button needs a text label for VoiceOver/TalkBack. Stats bars (Happiness/Health/Smarts/Looks) should show numbers and icons alongside color.
- Dark mode and typography: no game-specific sources found. Apple's Dynamic Type guidance applies directly, since the game is mostly text.

### Gaps
- No public BitLife UX case study or Candywriter design write-up exists in the results.
- No game-specific data on dark-mode adoption or typography sizes for text-heavy games.
- No Reigns postmortem or GDC talk surfaced in the search.
- No Android/TalkBack-specific game guidance surfaced. Google's Material accessibility docs would be the next source.

## 2. Visual design trends in casual mobile games 2025–2026 and how competitors present life stories

### Takeaway
Trend coverage is thin and mostly generic: flat, minimal and cartoon styles stay dominant in casual games because they read well on small screens and are cheap to produce, and micro-animations are a general UI trend. Life-sim competitors are mostly text-first, with weak monetization and ad complaints, which leaves room for an illustrated, polished entrant.

### Cited Findings
- Flat art (clean 2D shapes, bold colors) thrives on mobile because it runs efficiently and reads well on small screens (e.g., Crossy Road). Minimalism uses limited palettes and simple geometry. — [Boorghani reprint of 2024 guide](https://rss.boorghani.com/?p=186200)
- Low-detail art is cheaper to produce and runs on more devices. It is common in hypercasual games. — [Udonis](https://blog.udonis.co/mobile-marketing/mobile-games/mobile-game-art-styles)
- Pixune reports cartoon styles overtaking realistic ones in the fantasy category, but its data appears to be ~2019. — [Pixune 2026 guide](https://pixune.com/blog/mobile-game-art/)
- Micro-interactions (button shadow and press-collapse feedback) are listed as a 2026 UI trend. The examples are web-oriented. — [ABP.io](https://abp.io/community/articles/UI-UX-Trends-That-Will-Shape-2026-bx4c2kow)
- UI elements must scale across screen sizes. The piece has a "Motion Design and Micro-Animations" section that didn't come through in the snippet. — [Barrett Media, Jan 2026](https://barrettmedia.com/2026/01/21/graphic-design-for-video-games-trends-players-notice-in-2026/)
- Publishers increasingly combine simple loops with progression, live events, battle passes and long-term retention systems. — [AppFollow mobile gaming trends 2026](https://appfollow.io/blog/mobile-gaming-trends-2026)
- **Competitor landscape:** BitLife is listed at 4.8★ (~1.8M App Store reviews), #4 in Games at time of capture, 17+, free. — [AppPricingLab comparison](https://apppricinglab.com/compare/apple/1374403536/933113994). Google Play shows 50M+ downloads, publisher Candywriter LLC, ~1.3M reviews. — [Google Play event page](https://play.google.com/store/apps/eventdetails/4829558936210962084)
- 100 Years – Life Simulator's rating reportedly fell from 4.58 to 4.4, with ad frequency the top complaint. — [Marlvel audit](https://marlvel.ai/api/llm/apps/games/100-years-life-simulator)
- Life Clicker: Move to Success is an idle-style career sim at 4.06★ from 572 reviews, and the audit names BitLife as its main rival. — [Marlvel audit](https://marlvel.ai/apps/life-clicker-move-to-success)
- BitLife's in-game "ribbons" (end-of-life achievement labels, ~30 listed) are a form of life recap or summary. — [DroidGamers ribbons guide](https://www.droidgamers.com/guides/bitlife-ribbons-guide-a-list-of-all-30-ribbons-and-how-to-get-them/); [Prima Games](https://primagames.com/tips/bitlife-ribbons-list-how-to-get-all-ribbons-in-bitlife)

### Inferences
- An illustrated look (cartoon avatars that age visually, illustrated event cards) plus restrained micro-animations, honoring Reduce Motion, sets a redesign apart from the text-list visuals of BitLife and its clones.
- BitLife's ribbon is a ready-made share artifact. An end-of-life recap card (timeline, ribbon, key stats, cause of death) is an obvious upgrade.

### Gaps
- No 2025–2026 quantitative data on art-style share or micro-animation effects on retention.
- No revenue or market-size data for the life-sim sub-genre (needs Sensor Tower/AppMagic). InstaLife and other named rivals returned no data.
- No sources on how competitors design timelines or shareable life recaps specifically.

## 3. Social/viral features that drive organic growth for narrative games

### Takeaway
BitLife's scale is confirmed (72M lives in a year; 6,800+ challenges). Its growth leaned on TikTok/Instagram, localized influencers, limited-time challenges, and Reddit communities decoding ribbons. Spotify Wrapped shows how a story-formatted recap with one-tap sharing, comparison with friends and a novel stat ("Listening Age") produces huge organic reach. The CallMeKevin link is real (a long-running BitLife series from Dec 2019), but no source quantifies its effect on downloads.

### Cited Findings
- Goodgame Studios (sister company to BitLife publisher Candywriter), Nov 2022: players lived 72M+ virtual lives in 12 months and played 6,800+ challenges, solving 600,000+ in-game tasks. Success is credited to "fully integrated, geographically coordinated marketing" plus local product development per region. — [Goodgame press release](https://goodgamestudios.com/company/press/releases/72-million-virtual-lives-in-one-year-bitlife-impresses-internationally/)
- The campaigns used TikTok and Instagram, with local influencers such as Gnu (Germany) and Jazzghost (Brazil). The Portuguese-language TikTok/Instagram channels passed 100,000 fans. — [Goodgame press release](https://goodgamestudios.com/company/press/releases/72-million-virtual-lives-in-one-year-bitlife-impresses-internationally/); [German PDF](https://goodgamestudios.com/wp-content/uploads/2022/11/25112022_press_release_blint1y_DE.pdf)
- CallMeKevin's BitLife series started Dec 1, 2019, and ran past 2020. — [TheTVDB BitLife (CallMeKevin)](https://www.thetvdb.com/series/bitlife-callmekevin/seasons/official/1). His channel reportedly reached 2M subscribers in March 2019 (fan wiki, low reliability). — [EverybodyWiki](https://en.everybodywiki.com/Call_Me_Kevin). Analytics describe a "chaotic playstyle" personality format. — [OutlierKit](https://outlierkit.com/channel/callmekevin)
- Limited-time BitLife challenges (Online Troll, Hell's Kitchen, etc.) "keep players coming back". — [LevelWinner](https://www.levelwinner.com/bitlife-online-troll-challenge-guide-how-to-complete-the-online-troll-challenge/)
- New ribbons drive community decoding. A Reddit user was among the first to earn the Model Bitizen ribbon and posted how. — [Gamezebo](https://www.gamezebo.com/walkthroughs/bitlife-guide-how-to-get-the-model-bitizen-ribbon/)
- The largest BitLife Discord is unofficial ("Coral Eclipse", ~3,187 members), not Candywriter-run. — [Discord listing](https://discord.com/servers/coral-eclipse-or-formerly-bitlife-792224999581810720)
- **Spotify Wrapped as a model:** each slide is formatted like an Instagram story with a share button. — [The Hustle](https://thehustle.co/12062021-spotify-wrapped). Wrapped is credited with a 21% rise in app downloads in the first week of Dec 2020 (citing Protocol) and 2B+ social impressions in 2023. — [Idomoo](https://www.idomoo.com/blog/why-spotify-wrapped-works-and-how-you-can-do-it-too/)
- Wrapped 2025 was reportedly shared 500M+ times on day one (+41% YoY). It added "Listening Age" and a real-time multiplayer "Wrapped Party" for comparing stats with friends. User counts differ across reports (150M vs 200M). — [RouteNote](https://routenote.com/blog/spotify-wrapped-2025-record-breaking-launch/); [Thred](https://thred.com/newsletters/its-a-wrapped-analysing-spotifys-gen-z-success/)
- UGC-style creative lifts impression-to-install conversion by an average of 152% (Liftoff 2025 Creative Index). — [Liftoff via Newswire](https://www.newswire.ca/news-releases/liftoff-s-2025-mobile-ad-creative-index-reveals-ugc-is-a-key-differentiator-for-top-apps-837345804.html)

### Inferences
- Build a "Life Wrapped" end-of-life recap: a vertical 9:16 story sequence (birth → milestones → ribbon → epitaph), one-tap export to TikTok/IG Stories with the app link, plus a novel shareable stat (e.g., a "Life Archetype"), mirroring Listening Age.
- Make challenges shareable as seeds/codes ("Try my life: born in X, goal Y") so friends compete on the same setup, mirroring Wrapped's comparison mechanics.
- Run a creator program: early builds and custom challenges for chaotic-personality YouTubers/TikTokers like CallMeKevin, and local-language creators per market, as Goodgame did with Gnu and Jazzghost.
- Run an official Discord: BitLife leaves that space to an unofficial server, which is an opening.

### Gaps
- No data quantifying CallMeKevin's (or any YouTuber's) effect on BitLife downloads.
- No design research on what makes a share card spread (layout, length).
- No data on UGC tools (custom scenario editors) in life sims.

## 4. Go-to-market: soft launch, ASO, UA and creatives, influencers, community, PR, timelines

### Takeaway
The classic soft-launch markets (Canada, Australia, NZ, Philippines, Nordics) still apply, but Canada and Australia have become pricey. 2026 commentary shifts the focus from cheap volume to tuning onboarding, monetization fit and scalability. ASO hinges on the first three screenshots and a muted, gameplay-first video. UA in 2025 is video-dominant, playables convert far better but only on AppLovin/Unity, UGC lifts conversion, and CPIs are rising. Build a Discord hub early, roughly 12 months before launch.

### Cited Findings
**Soft launch**
- Typical soft-launch markets: Canada, Philippines, Australia, New Zealand, Nordics. — [MWM glossary](https://mwm.ai/glossary/soft-launch). These English-speaking markets resemble US/UK players in spending. — [CGMagazine](https://www.cgmagonline.com/articles/phone-gets-new-games/)
- Major titles soft-launch for 3–12 months, smaller ones for 1–3. — [PayPro Global](https://payproglobal.com/pt_br/respostas/o-que-e-estrategia-de-soft-launch-de-jogo/)
- A Chartboost piece (surfaced in the same search, exact URL not captured) says Canada and Australia have become pricey and suggests Ireland, the Netherlands and the Philippines as cheaper alternatives. Philippine players behave less like Western players. — search results incl. [PocketGamer.biz new soft launch countries](https://www.pocketgamer.biz/new-soft-launch-countries/)
- 2025 soft launches leaned toward "cheap volume". 2026 shifts toward fine-tuning, sophisticated onboarding and data-backed scalability, and monetization should match each region's behavior rather than defaulting to CA/AU. — [PocketGamer.biz, "Soft launch is changing in 2026"](https://www.pocketgamer.biz/soft-launch-is-changing-in-2026-how-and-where-should-you-release-your-game)
- Core soft-launch metrics: CPI, ROAS, D1/D7/D30 retention, ad revenue per user (paywalled detail). — [Matej Lancaric, Soft Launch Bible 2025](https://lancaric.substack.com/p/the-soft-launch-bible-full-2025-blueprint)

**Benchmarks**
- GameAnalytics 2025 report (~11,600 apps): top-quartile D1 ≈ 26.5–27.7% at end-2024, down from 2023; median D7 ≈ 3.4–3.9%; top-quartile D7 ≈ 7–8%. — [GameDevReports recap, Feb 2025](https://gamedevreports.substack.com/p/weekly-gaming-reports-recap-february-21d). Vendor guides cite much higher numbers (median D1 25–35%, D7 15–20%), likely due to different retention definitions. — [AppFollow](https://appfollow.io/blog/mobile-game-kpis); also "avg D1 ~30%, D30 ~3%" — [Segwise](https://segwise.ai/blog/boost-mobile-game-retention-strategies)
- 2025 CPIs: Android $0.30–6.00, iOS $0.50–12.00 by genre. CPIs on Meta and TikTok are up 15–20% YoY. — [Admiral Media](https://admiral.media/mobile-game-marketing-benchmarks/)
- Blended global gaming CPI is ~$0.56 (+~30% YoY), and casual titles target ~7.6% D7 ROAS on iOS. These are third-party figures that weren't verified. — [Segwise](https://segwise.ai/blog/cpi-ipm-roas-benchmarks-optimizing-ad-spend/)
- Older example thresholds: D1 good 20 / mediocre 15 / bad 5; ROI ≥20% Android, ≥25% iOS. These are dated. — [ZENNA SlideShare](https://www.slideshare.net/ZennaApps/kpis-for-mobile-game-soft-launch)

**ASO**
- Icon, screenshots and video drive conversion, and conversion feeds store ranking and featuring. Only the first three portrait screenshots show in App Store search, so use one feature per screenshot with large text. Google Play now shows screenshots in search. Videos should open with the best content, use real footage, and work muted. — [AppTweak](https://www.apptweak.com/en/aso-blog/best-aso-practices-for-your-app-game-creatives?lang=en-US)
- Put searched keywords in screenshot captions (this helps searchers see their query, not indexing). The source is dated (2018). — [Gummicube](https://www.gummicube.com/blog/app-store-screenshot-design-there-is-no-game)
- Top games use sub-genre keywords rather than broad ones, rotate screenshots for live events, and localize into 15+ languages. Showing gameplay in the first seconds of video reduces bounce. — [Appdrift games benchmarks](https://appdrift.co/top-apps/games)
- A video plus screenshot refresh lifts conversion 10–30% (vendor claim). — [Dogtown Media](https://www.dogtownmedia.com/?p=22102)

**UA and creative**
- Playables: impression-to-install 8× non-playables for top spenders and 16× for others (Liftoff, Jan 2023–May 2025). UGC raises IPM by 152% on average. — [Liftoff 2025 Creative Index](https://www.newswire.ca/news-releases/liftoff-s-2025-mobile-ad-creative-index-reveals-ugc-is-a-key-differentiator-for-top-apps-837345804.html)
- Playables run at volume mainly on AppLovin and ironSource/Unity. Video is still 80%+ of game ad creatives (Mobvista/Insightrackr), and AI creative tools are being adopted for scale. — [PlayTurbo](https://www.playturbo.com/blog/scaling-playables-and-ai-creatives-in-2026)
- April 2025 trends: AI-generated 5-second hooks and TikTok-style POV playables. — [Two and a Half Gamers / Felix Braberg](https://felixbraberg.substack.com/p/the-latest-wtf-ads-pushing-the-creative-2d0)
- Meta's continuing dominance in mobile game UA. — [ContentGrip UA report](https://www.contentgrip.com/mobile-game-ua-report/)
- Analysis of 10,000+ game ads. — [FoxData](https://foxdata.com/en/blogs/winning-ad-creatives-for-mobile-games-analyzing-10000-ads-to-find-what-works/)

**Community, influencers, timeline**
- Start a Discord when development begins and use other socials as feeders into it. A 12-month pre-launch playbook spends months 1–2 on clarity (audience, one-line hook) before inviting anyone. — [FirstLook](https://firstlook.gg/blog/from-discord-to-steam-launch-community); [FirstLook](https://firstlook.gg/blog/how-to-build-a-game-community-from-scratch)
- Discord's own playbook: design the server around "what do you want people to do there?" and run events. — [Discord blog](https://discord.com/blog/the-game-developer-playbook-part-two-early-access-and-pre-launch)
- Use teasers, countdowns, exclusive early access and giveaways. Promote the server early to avoid a "ghost town". — [Wayline](https://www.wayline.io/blog/discord-community-indie-game-marketing); [Wayline hype guide](https://wayline.io/blog/how-to-build-hype-for-a-game-launch)
- BitLife's international rollout relied on per-region coordinated marketing and local influencers. — [Goodgame press release](https://goodgamestudios.com/company/press/releases/72-million-virtual-lives-in-one-year-bitlife-impresses-internationally/)
- "You don't need a publisher but you do need publishing" (PGC panel). — [PocketGamer.biz](https://www.pocketgamer.biz/pgc-you-dont-need-a-publisher-but-you-do-need-publishing-says-playgrounds-taht)

### Inferences
- A practical sequence: Discord and creator seeding during pre-production (T-12 months) → closed beta → soft launch in the Philippines (cheap retention/FTUE read) plus CA/AU or Ireland/NL (monetization read), 1–3 months for a small title → global launch with localized ASO and a creator wave.
- A text-heavy life sim's "gameplay" is outrageous story moments. Creatives should be POV/UGC-style "my life went wrong" hooks, which also match how CallMeKevin-type content works.
- Use sub-genre keywords such as "life simulator", "life sim", "choices", "text adventure", "story game".

### Gaps
- No primary source on PR strategy (press kits, embargoes) for mobile launches.
- No data on Google Play/App Store pre-registration conversion or timing.
- Life-sim-specific CPI or retention benchmarks were not found.

## 5. Pitching a game to clients/investors/publishers

### Takeaway
Keep the deck short (≈5–12 slides). Lead with the game: hook, genre, audience and USPs. Then show proof (playable core-loop prototype, trailer backup, KPIs/traction), comps, monetization, budget and timeline, team, and a clear ask. Publishers judge the product; investors judge the team and returns. The commonest mistakes are pitching creative vision without financial structure, unrealistic comps (e.g., "like Minecraft"), math errors, and pitching to funders whose catalog or model doesn't fit.

### Cited Findings
- Keep the deck to about 5 pages with minimal text. Cover the game overview (title, genre, audience, USPs), monetization, and the ask (funding, marketing, localization, playtesting). The factsheet should have release date, price, platforms, audience and comparable titles. — [WN Hub / Flying Oak Games' Thomas Altenburger](https://wnhub.io/news/analytics/item-2953); [Fungies](https://fungies.io/?p=29334); [ModDB](https://www.moddb.com/news/how-to-structure-a-killer-game-pitch-deck)
- The prototype should show the core loop and key feature with simple placeholder art (unless art is the hook) and be clear to an outsider. A full vertical slice isn't required, and a trailer is a backup if the build fails. — [WN Hub / Astrum Entertainment](https://wnhub.io/news/stores-and-publishing/item-44580)
- Publishers focus on the product, investors on the team. Pitch only to publishers whose catalog fits your genre. — [WN Hub / Astrum Entertainment](https://wnhub.io/news/stores-and-publishing/item-44580)
- Investors want main KPIs (e.g., downloads vs. retention). One commentator cited a soft-launch cohort bar of ≥1k players and ≥100 payers in one geo, and called it restrictive. — [Elite Game Developers #30](https://elitegamedevelopers.substack.com/p/egd-news-30)
- Pitches fail because they speak in creative terms rather than return structures, timelines and risk controls (Madeira Games Summit exercise). — [80.lv](https://80.lv/articles/pitch-perfect-how-to-prepare-your-game-for-investors-and-publishers/)
- Red flags: math errors, comparing your game to Minecraft, hardship stories to justify multi-year timelines, one-page pitches. A pitch is effectively a request for a "$50–200k bet". — [Positech (Cliff Harris)](https://www.positech.co.uk/cliffsblog/2015/01/06/how-to-pitch-your-indie-game-to-a-vc-investor/)
- Match funder to model: project funding for premium games, VC for F2P/GaaS (Jason Della Rocca). — [Game Developer – GDC Podcast ep. 28](https://www.gamedeveloper.com/business/the-missing-money-problem-with-jason-della-rocca%2d%2d-gdc-podcast-ep-28)
- "Sell the game idea first; sell the ROI second." "Traction beats any pitch deck" (wishlists, metrics, playtests). Expect rejections and use them as feedback. — [Wayline](https://www.wayline.io/blog/creating-compelling-game-pitch-secure-funding-interest-indie-game); [gamedev.net](https://gamedev.net/news/cluster/4622/)
- Shift.io's "perfect publisher pitch deck" guide. — [Shift Cutaway](https://cutaway.shift.io/the-perfect-publisher-pitch-deck)
- GDC 2017 talk on 30 common pitching mistakes (content not in results). — [GDC](https://www.gdconf.com/news/30-common-game-pitching-mistakes-will-explained-gdc-2017)

### Inferences
- A suggested deck for this project:
  1. Hook / one-liner ("BitLife, redesigned: one-thumb, illustrated, shareable lives").
  2. Market and comps: BitLife's 72M lives/yr and 50M+ installs; rivals' ad and monetization complaints.
  3. Player pain points: nested menus, unlabeled buttons, pay-gated features.
  4. Solution and key features: card UI, Life Wrapped sharing, accessibility.
  5. Prototype/video.
  6. Monetization (F2P ads + IAP; avoid the pay-to-win backlash).
  7. KPIs and targets vs. GameAnalytics benchmarks.
  8. GTM: soft-launch plan, creator program, Discord.
  9. Team.
  10. Budget, timeline, milestones.
  11. The ask.
- For a F2P life sim, VC/publisher funding fits better than project funding (Della Rocca's split).

### Gaps
- No consensus list of KPIs that publishers require. No specific publisher (e.g., Voodoo, Kwalee, Homa) pitch requirements surfaced.
- No 2025–2026 data on typical mobile-game seed budgets or deal terms.
