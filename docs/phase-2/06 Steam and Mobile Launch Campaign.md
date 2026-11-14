---
title: "06 Steam and Mobile Launch Campaign"
project: Relivable
phase: 2
status: proposed
updated: 2026-11-14
tags: [relivable, phase-2, steam, mobile, marketing, launch]
---

# 06 Steam and Mobile Launch Campaign

*Purpose:* a concrete plan to ship Relivable on Steam and finish the mobile
launch (Google Play, then Apple), plus the marketing campaign around both.
This does not re-plan positioning or audience — that's already decided in
[[10 Go-to-Market]] and stays as-is; this doc adds **Steam specifically**
(not covered there) and turns [[01 Phase 2 Open Items]]'s A1/A2 (store
listings) into a dated execution plan rather than a status line. The
blockers are the same ones already tracked in [[01 Phase 2 Open Items]];
this doc doesn't re-litigate them, it sequences the work around them.

> [!danger] Read this first
> **The name "RELIVABLE" is an unresolved trademark conflict** ([[01 Phase 2 Open Items]] A7: reg. no. 7538229, owner Robert Matteson). [[10 Go-to-Market]] already flags this as blocking *any* paid promotion. It blocks more than that here: a Steamworks app page, a Google Play listing and an Apple App Store listing are themselves public launches under the name. **Nothing in this doc — the Steamworks account, the Play Console listing, a single dollar of paid UA — should be created under the name "RELIVABLE" until IP counsel clears it.** Everything below is written so it can proceed in parallel (store copy, assets, build pipeline, campaign calendar), with the name as a placeholder, and the actual store-page creation step held until A7 closes. Treat every "create the Steamworks page" / "submit to Play Console" step below as gated on A7, explicitly, not implicitly.

---

## 1. Platform readiness, today

| Platform | State | What it needs for a real launch |
|---|---|---|
| **Web** | Live, works on desktop and mobile browsers, "Add to Home Screen" | Nothing blocking; it's the fallback for every platform below |
| **Windows desktop** | Live: Electron shell in `desktop/` spawning the Nitro build (`HIVE_DESKTOP=1`), built by `.github/workflows/desktop.yml` | Code signing ([[01 Phase 2 Open Items]] A3) before wide distribution; **this is also the closest thing to a Steam build already in the repo** (§2.2) |
| **Android** | Live: APK built by `.github/workflows/android.yml` (per [[00 Phase 2 Development Route]]), self-updates from GitHub releases | Not Play-Store-shippable as-is: self-update via `REQUEST_INSTALL_PACKAGES` is against Play's policy for games. Needs a Play-specific build variant (§3.1) |
| **iOS** | Unsigned IPA via AltStore, or the web app | Apple Developer account, CI signing step (§3.2) |
| **Steam** | **Nothing exists** — no Steamworks app, no build pipeline, no store page | Everything in §2 |
| **macOS / Linux desktop** | Not built (web works) | Owner decision ([[01 Phase 2 Open Items]] A4); out of scope here |

---

## 2. Steam launch plan

### 2.1 Steamworks account and entity

Steamworks requires a **$100 one-time app fee per game** (refunded if the
game earns $1,000 within 90 days of release — Valve's standard term, verify
current terms at partner sign-up) and a **registered legal entity or
individual with a payable bank account and tax forms (W-9/W-8BEN)**, not an
anonymous developer. This is the same entity question as [[01 Phase 2 Open Items]]
G2 (Company and IP) in the investor pack — **one entity decision serves
both**, so sequence G2 before this rather than standing up a throwaway
structure just for Steam.

**Owner needs to provide:** the entity (or confirm sole-proprietor filing
status in their country), a bank account for payouts, and the $100 fee —
then IP counsel's go-ahead on the name (A7) before anything is actually
submitted under it.

### 2.2 Build pipeline

The closest thing to a Steam build already in the repo is the **Windows
desktop Electron shell** (`desktop/main.cjs` spawning the Nitro
`HIVE_DESKTOP=1` build). Steam doesn't require SteamAPI integration for a
valid listing — plenty of shipped indie games are "no achievements, no
cloud saves via Steam, just the game" on day one. Recommended path:

1. **MVP Steam build = the existing desktop Electron app, re-packaged.** No
   Steamworks SDK calls needed to list and sell. Ship this first.
2. **Packaging:** Valve's `steamcmd`/SteamPipe uploads a depot built from
   the same artifact `.github/workflows/desktop.yml` already produces.
   Add a `steam.yml` workflow (or a job in the existing one) that, on a
   tag, uploads the built Electron app as a new depot build via
   `steamcmd +run_app_build`. Needs a Steam **build account** (separate
   from the owner's personal Steam login) and its credentials as a repo
   secret — same security posture as the Android signing key in
   [[04 Pre-launch Security Checklist]], store it the same way.
3. **Phase 2 (post-launch, optional):** Steamworks SDK integration for
   cloud saves (maps onto [[01 Phase 2 Open Items]] C1, since cloud saves
   are wanted everywhere, not just Steam) and achievements (maps onto
   existing Life Titles/Milestones — each could become a Steam
   achievement with near-zero new design work).
4. **Controller support:** Relivable is built for touch/tap; a mouse
   works fine (it's card-and-button driven), but Steam Input / full
   controller navigation is not required for launch and should stay
   out of scope unless playtesting shows players expect it on PC.

### 2.3 Store page assets

Exact Valve specs (verify against current Steamworks documentation before
upload, as Valve updates these occasionally):

| Asset | Spec | Status |
|---|---|---|
| Header capsule | 460×215 px | Not made |
| Small capsule | 231×87 px | Not made |
| Main capsule | 616×353 px | Not made |
| Vertical/Library capsule | 600×900 px | Not made |
| Library hero | 3840×1240 px | Not made |
| Screenshots | At least 5, 1920×1080 recommended | Have real gameplay footage/stills from the Instagram batches ([[10 Go-to-Market]] "Assets already made") — crop from those, don't reshoot |
| Trailer | MP4, under Valve's size/length limits (check current: historically ~30s–2min sweet spot for store conversion) | The existing 80-second "One life, one take" promo and the Reels ([[10 Go-to-Market]]) are the source footage; cut a Steam-specific edit (§4.3) |
| Short description | ~300 characters, shown in search/lists | Draft in §5.1 |
| About This Game | Long-form, supports basic formatting | Draft in §5.1 |
| System requirements | Minimum + Recommended, Windows | Draft in §5.1 |
| Tags | Up to 20(ish); pick from Valve's existing tag taxonomy | Draft: Life Sim, Simulation, Choices Matter, Narrative, Character Customization, Singleplayer, Casual, Text-Based, Family Friendly (careful: content is 16+, don't mis-tag), Replay Value |

### 2.4 Pricing and monetisation on Steam

[[06 Monetization and Economy]] locks the mobile model: free-to-play, every
career free, Relivable Plus a one-time $9.99 unlock, opt-in rewarded ads,
no loot boxes, no subscriptions. Steam's own conventions and its audience's
tolerance for ads are different from mobile's. **Recommendation** (owner
decision, not yet made):

- Ship Steam **free-to-play**, same base game as mobile, for parity and so
  the "every career free" promise means the same thing on every platform.
- Sell **Relivable Plus as a $9.99 DLC** on the Steam store page (Steam
  supports this natively) — same contents and price as mobile Plus.
- **No ads on the Steam build at all** (not opt-in, not rewarded) — PC
  storefront audiences react badly to ads in a paid-adjacent context, and
  Steam has no native rewarded-video unit. The free tier's ad-gated perks
  (e.g. extra Rewinds) become simply unavailable to Steam's free tier,
  or Steam's free tier gets the Plus-tier Rewind count as a platform
  concession — **this needs an owner call**, since it's a real economy
  difference, not just presentation.
- Story Packs and the Season Pass (when built, per [[01 Phase 2 Open Items]]
  B3/B4) ship as Steam DLC the same way.

### 2.5 Age rating on Steam

Steam uses its own **content survey** at store-page setup (not the
IARC/Play Console flow in [[09 Compliance and Ratings]] §2.2, though the
answers should be consistent with it) plus the same territory-specific
submissions ([[09 Compliance and Ratings]] names USK for Germany, GRAC for
South Korea) if targeting those storefronts explicitly at launch. Simplest
path: answer Steam's content survey consistently with the Play Console's
ESRB M / PEGI 16 target (§2.5 of [[09 Compliance and Ratings]]) and skip
USK/GRAC submission for v1 — Steam allows a store page to go live without
them, restricting visibility only in those specific territories until
submitted.

### 2.6 Timeline (phases, not dates — the owner sets dates once A7 clears)

| Phase | What happens | Gate to move to next phase |
|---|---|---|
| 0. Pre-work | Entity (G2), $100 fee, IP counsel clears the name (A7) | A7 resolved |
| 1. Coming Soon page | Store page live, wishlist-only, no price yet | Trailer cut, capsule art done, 5+ screenshots |
| 2. Wishlist drive | Campaign per §4 runs for weeks-to-months | Wishlist count and conversion data inform the launch date |
| 3. (Optional) Steam Next Fest / demo | A time-boxed vertical slice (birth → age 30, matching the original Phase 2 scope per [[00 Phase 2 Development Route]]) as a free demo during a Next Fest window | Owner decision — high visibility, real engineering cost to carve out a demo build |
| 4. Launch | Price goes live, launch-week campaign (§4.1) | — |
| 5. Post-launch | Reviews, patches, Steamworks SDK phase 2 (§2.2) | — |

---

## 3. Mobile completion plan

[[01 Phase 2 Open Items]] A1 and A2 already name what's missing; this
sequences it.

### 3.1 Google Play

1. **Remove self-update from the Play build.** Keep self-update for the
   sideloaded/GitHub-release APK (it's a real feature for players who
   can't or don't want Play), but the Play variant must not request
   `REQUEST_INSTALL_PACKAGES` or self-install updates — Play's own update
   mechanism replaces it. This is a build-flavor split in the existing
   Android pipeline, not a rewrite.
2. **Play App Signing:** enrol once the Play Console account exists
   ([[04 Pre-launch Security Checklist]] already flags doing this "when
   the Play listing exists").
3. **Listing assets:** feature graphic, icon, phone + tablet screenshots,
   short/full description — same source material as the Steam assets
   (§2.3), resized to Play's specs.
4. **Release track:** Internal testing → Closed testing (the 10–20
   playtesters from [[01 Phase 2 Open Items]] F1 double as this cohort) →
   Production.
5. Needs from owner: Play developer account ($25 one-time), the age
   rating questionnaire (§2.5 of [[09 Compliance and Ratings]]), privacy
   policy (A6).

### 3.2 Apple App Store

1. Apple Developer account ($99/year).
2. CI signing step (macOS runner, cert + provisioning profile as repo
   secrets, same security posture as the Android key).
3. TestFlight first (per [[00 Phase 2 Development Route]] step 3), App
   Store listing second.
4. Needs from owner: the account, and a decision on ages 13–15
   ([[01 Phase 2 Open Items]] A5).

### 3.3 Cross-platform messaging

Once Steam and mobile are both live, every store page and every piece of
campaign creative should say where else the game is — "Also on Android,
iPhone and Steam" / "Also on PC" — cheap, and it's the single most direct
way the existing organic-first strategy ([[10 Go-to-Market]]) compounds: a
player who finds Relivable through a mobile Reel can play on their PC that
night, and vice versa. Build this into the store-page template (§5.1) and
the closing frame of every campaign asset (§4.3).

---

## 4. Marketing campaign (Steam + mobile dual launch)

This extends [[10 Go-to-Market]]'s organic-first, creator-led strategy —
it does not replace it. New here: a Steam-specific wishlist phase (Steam's
algorithm rewards wishlist velocity before launch more than almost any
other single lever) and a unified cross-platform calendar.

### 4.1 Phases and channels

| Phase | Steam | Mobile | Shared |
|---|---|---|---|
| **Teaser** | Coming Soon page up, no price | "Coming to Android/iPhone" social posts | Reuse existing promo footage ([[10 Go-to-Market]] "Assets already made") |
| **Wishlist drive** | Steam wishlist CTA on every post; press kit to PC-focused press (RPS, PCGamesN-style outlets, life-sim and narrative-game Discord communities) | Discord opened now per [[10 Go-to-Market]] §summary; Android/iOS pre-registration where the store supports it | Creator seeding: send early builds to the chaotic-playthrough creators named in [[10 Go-to-Market]] — a Steam key works for the same creators doing mobile content, it's the same playthrough energy |
| **Launch week** | Launch-day post, "now 20% off" or similar if the owner wants a launch discount (common Steam practice, improves day-1 visibility) | Store listings go live same week for simultaneity | One coordinated push across every channel the same day, not staggered |
| **Post-launch** | Respond to reviews, first patch notes as content | LiveOps calendar per [[01 Phase 2 Open Items]] E2, once built | Shared content calendar — a feature update (e.g. "Calling: Encore") is one piece of creative reused across every storefront |

### 4.2 Budget

Ties into the investor pack's fundraising ask ([[04 Use of Funds and Milestones]],
[[01 Phase 2 Open Items]] G1) rather than a separate budget line — paid UA
is explicitly de-prioritised in [[10 Go-to-Market]] (organic-first, paid UA
"marginal until retention proves top-decile"), so **this campaign is
near-zero paid spend by design**: the cost is creative time (trailer cut,
capsule art, press kit) and the $100 Steam fee + $25 Play + $99/yr Apple,
not ad spend. If the owner wants to budget *any* paid UA for the Steam
wishlist phase specifically (Steam wishlist ads are a known, relatively
efficient channel), that's a new line item to size against G1's tranche 1,
not assumed here.

### 4.3 Asset plan

Every piece of creative follows [[../ad-styles/relivable.md]], the
established "Calling reel" house style (eyebrow tag, serif headline, muted
wordmark, tilted device mockup, per-moment accent colour, collage CTA
close) — **extended with a PC/Steam frame variant**, added to that style
guide in this update (see the diff to `docs/ad-styles/relivable.md`) so
future sessions don't have to re-derive it: a monitor/desktop mockup in
place of the phone, and a "Wishlist on Steam" CTA pill alongside the
existing "Play free · link in bio."

Minimum asset set for launch:
- 1 Steam-specific trailer cut (from existing footage, §2.3)
- 5+ Steam screenshots (cropped from existing gameplay stills)
- Capsule art set (§2.3 dimensions)
- A short wishlist-phase reel (3–4 frames, Steam-flavoured, in the house style)
- A cross-platform "where to play" closing frame, reused across every asset

### 4.4 Messaging guardrails (unchanged, restated because Steam raises new ones)

From [[10 Go-to-Market]] §1.3, still in force everywhere, Steam included:
don't name BitLife in store metadata or paid ads; don't headline the
optional AI flavour-text feature; don't target or appeal to children. New
for Steam specifically: Steam's own content and comparison guidelines are
stricter about naming competitors in store assets than social media is —
treat the Steam store page as the strictest-guardrail surface, not the
loosest.

---

## 5. Draft copy (ready now; the name is a placeholder pending A7)

### 5.1 Steam short description (~300 characters)

> Live a whole life, one choice at a time. Every career is free, every
> choice is remembered — your bully shows up at your wedding, your kids
> inherit your grudges. No pay-per-undo, no paywalled careers, built to
> work with a screen reader. Your life, your story, worth sharing.

### 5.2 About This Game (long description)

> **Every choice is remembered.**
>
> Relivable is a life simulator where nothing you do disappears. The
> favour you called in at 19 comes due at 40. The rival you made in
> school shows up again, richer or worse off, at your reunion. Your kids
> inherit more than your money — they inherit your grudges, your
> reputation, and sometimes your enemies.
>
> **One life, every path.**
> Start as anyone, anywhere, and go wherever the life takes you: climb a
> special career from actor to astronaut to fighter — each with its own
> look, its own people, its own story — commit a crime and build a
> defence, run a business across several locations at once, build an
> eight-generation dynasty, or just live quietly and well. Every career
> and every system is free. Nothing is locked behind a paywall.
>
> **Fair, forever.**
> One optional unlock, Relivable Plus, adds unlimited Rewind, deeper
> dynasties and editor tools — it changes nothing about what you can
> play, only how much of it you can keep. No ads interrupt a choice. No
> loot boxes. No subscriptions.
>
> **Built for everyone.**
> Full screen-reader support, adjustable text size, reduced motion and
> colour-vision modes aren't an afterthought — they're how the game
> ships.
>
> **Your story, worth sharing.**
> Every life ends with a Life Recap — a shareable record of who you were,
> what you did, and what it cost. Try someone else's life with a seed
> code. Build a dynasty worth remembering.
>
> Also on Android, iPhone and the web.

### 5.3 Feature bullets

- 12+ special careers, each with its own look, mini-games and people
- A full crime-to-prison system: heists, evidence, trials, parole, prison life
- An eight-generation dynasty mode with family legacy and inheritance
- A living world with its own newspaper reacting to what you do
- Every choice remembered — NPCs recall what you did, years later
- One fair $9.99 unlock; every career and system free for everyone
- Full accessibility: screen reader support, text scaling, reduced motion, colour-vision modes
- Cross-platform: PC, Android, iPhone, web

### 5.4 System requirements (draft — verify against the actual Electron build's footprint)

| | Minimum | Recommended |
|---|---|---|
| OS | Windows 10 64-bit | Windows 10/11 64-bit |
| Processor | Dual-core 2 GHz | Quad-core 2.5 GHz+ |
| Memory | 4 GB RAM | 8 GB RAM |
| Graphics | Integrated graphics | Integrated graphics |
| Storage | 500 MB | 500 MB |

Relivable is a 2D, card-based game (no 3D rendering) — these are
conservative placeholders for an Electron/Chromium app; measure the real
installed size and memory footprint from the existing desktop build before
publishing.

---

## 6. Blockers, in order

1. **A7 — the RELIVABLE trademark.** Nothing public (Steamworks page, Play
   listing, App Store listing, paid promotion) happens under this name
   until IP counsel clears it, licenses it, or a rename is decided. This
   blocks the *creation* step everywhere in this doc, not the prep work.
2. **G2 — company entity and IP assignment.** Needed for the Steamworks
   payout account and is a prerequisite the investor pack already needs;
   do it once, for both.
3. **A1/A2 — Play and Apple developer accounts** ($25 one-time / $99/yr).
4. **Steam's $100 app fee**, once A7 and G2 clear.
5. **A5/A6 — age rating decision and privacy policy**, needed by every
   storefront (Steam, Play, Apple) identically — write once, submit
   three times.
6. **The Android signing-key fix** ([[04 Pre-launch Security Checklist]]
   "Owner to-do #1") — unrelated to Steam, but do it before any store
   push increases how many installs depend on that key surviving.

None of §2.2 (Steam build pipeline), §2.3 (store assets), §3.1–3.2 (store
listing assets), §4.3 (campaign creative) or §5 (store copy) needs to wait
on these — all of it can be built now, under the placeholder name, ready
to go live the moment the name question resolves.
