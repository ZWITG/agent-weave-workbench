---
title: "01 Phase 2 Open Items"
project: Relivable
phase: 2
status: open
updated: 2026-11-01
tags: [relivable, phase-2, release, decisions]
---

# 01 Phase 2 Open Items

*Purpose:* what the Phase 1 plan asked for that the game does not have yet,
after the first release (1.0) audit on 1 Nov 2026, and what each item needs
from the owner. The game itself (life systems, prison, the Echelon, the
world, dynasties) is built and tested; what is left is mostly things that
need **accounts, money, people, legal review or a decision**.

How to read it: **Needs** is what only the owner (or a hired person) can
provide. Items are ordered by how much they block a public store launch.

## A. Store launch (blocks Google Play and the App Store)

| # | Item | Today | Needs from you |
|---|---|---|---|
| A1 | **Google Play listing** | APK is sideloaded from GitHub and updates itself (`REQUEST_INSTALL_PACKAGES`, which Play does not allow for games) | A Play developer account ($25 once), a store listing, and the go-ahead to build a Play variant without self-update |
| A2 | **Apple App Store / TestFlight** | iPhone players use the web app or an unsigned IPA via AltStore | Apple Developer account ($99/year) and a decision to sign builds in CI |
| A3 | **Windows code signing** | Installer is unsigned, so Windows SmartScreen warns on first run | A code-signing certificate (or a Microsoft Store listing) |
| A4 | **macOS and Linux desktop** | Not built (web works there) | Whether you want them; macOS needs the Apple account from A2 |
| A5 | **Age rating** | Content is written for 16+; there is no age screen | Confirm 16+, and decide ages 13–15: block, or a softened build (plan 04 open decision 4). Then the Apple questionnaire and IARC |
| A6 | **Privacy policy and terms** | The game is offline and collects nothing, which keeps this simple | Approve a short policy (needed by both stores even for offline games) |
| A7 | **Trademark clearance** for "Relivable" and the fictional brand names (Vybe, Lenso, Murmur…) | Not started | IP counsel, or accept the risk for a small release |

## B. Money (the plan's business model is not built)

| # | Item | Today | Needs from you |
|---|---|---|---|
| B1 | **Relivable Plus** purchase ($9.99 in the plan) | Plus features (unlimited Rewind, 8 generations) are **free for everyone in 1.0**; the test switch is hidden (`plusForEveryone` in `profile.dart`) | Store accounts (A1, A2), a payments service (RevenueCat in the plan) and a yes on pricing |
| B2 | **Destiny Mode** (Plus "editor tools") | Promised in the plan, not built | Decide what it lets players edit before it is built |
| B3 | **No Ads, Story Packs, Season Pass, Welcome Pack, Founder's Bundle** | Not built; the game has no ads at all | Decide whether 1.x has ads at all. If not, No Ads and rewarded perks drop out of the plan |
| B4 | **Story Packs** (Spotlight, Night Shift, Old Money, Frontier 1850…) | Not built | Pick the first pack; each is a writing project |

## C. Accounts, cloud and data

| # | Item | Today | Needs from you |
|---|---|---|---|
| C1 | **Cloud saves and sign-in** | Saves live only on the device; a lost phone loses the dynasty | Choose a backend (the repo already has Supabase for the Tensai app) and approve accounts, which pulls in C2 and A6 |
| C2 | **Account deletion and data export** | Not needed while offline | Required by both stores once accounts exist |
| C3 | **Analytics and crash reports** | None; "playtest analytics" from the plan are not instrumented | Choose a provider and consent approach; needed for the Gate 2 playtest numbers |

## D. Content and art (the critical path in the plan)

| # | Item | Today | Needs from you |
|---|---|---|---|
| D1 | **Event volume** | About 157 data events plus about 50 coded scene families with many branches; the plan targets 1,500–3,000 events at global launch | Writers (or more sessions with me) and **your review** of tone; a style bible and banned-terms list (plan checklist) |
| D2 | **Avatars and art** | Initials in rings; drawn decals for prison and the Echelon; no character art | An art direction decision and an illustrator, or approve a generated-shape avatar system |
| D3 | **Music** | Sound effects only (all generated) | Whether to commission a soundtrack |
| D4 | **Localisation** | English only (money is localised to 40+ currencies) | Which languages first (the plan says ES, PT-BR, DE, FR) and a translation budget |

## E. Live game and social

| # | Item | Today | Needs from you |
|---|---|---|---|
| E1 | **Push notifications** | None | Approve the plan's notification policy and which platforms |
| E2 | **LiveOps calendar, remote config and seasonal events** | Daily goals, weekly challenges and seasonal activities run on device; nothing is controlled remotely | A server (ties to C1) and someone to run events |
| E3 | **Async social** (leaderboards, friend challenges) | Seed codes can be shared; Life Recap cards can be saved and shared | Decide if 1.x needs it; needs accounts (C1) |
| E4 | **Creator Mode** (player-made scenarios) | Not built | Moderation plan and policy (plan checklist 21) |
| E5 | **Optional AI Storyteller** (rewording) | Not built | Provider, budget per player, consent and safety rules (plan 08 §10) |

## F. Playtests and Gate 2

| # | Item | Today | Needs from you |
|---|---|---|---|
| F1 | **Playtests** | Automated: 500-life simulator, 40,000-year release fuzz, small-phone UI checks; no real players yet | 10–20 players (5–8 moderated, 2 screen-reader users) |
| F2 | **In-game feedback form** | None | Where feedback should go (email, form, Discord) |
| F3 | **Accessibility release gate** | Labels, text size, reduce motion, colour-vision modes and left-hand layout are in; no manual VoiceOver/TalkBack pass yet | A device test session, and later an external audit for the European Accessibility Act |
| F4 | **Gate 2 readout** | Not written | Playtest data from F1 and C3 |

## What the 1.0 audit fixed (for reference)

- Life titles that could never be earned now work: The Healer, The Teacher and The Restaurateur are remembered after you change job or sell up.
- Joining the Stage Kids at school now opens acting as the plan intended.
- An affair coming out is remembered (the Life Recap and later partners' doubts use it).
- Palliative care now gives comfort every year instead of doing nothing after the choice.
- The "Relivable Plus (test switch)" is gone from Settings and Plus is free for everyone, so no player meets a paywall they cannot pay.
- An unreadable save is kept aside instead of being overwritten, and the load-error screen has a Try again button.
- Versions are now `1.0.<build>` on every platform; the game has a player README with install steps.
- Static sweeps found no missing scene handlers, no menu pointing at a missing activity and no unsaved state; a new release fuzz test plays whole dynasties (including full prison sentences from the inside and lives at the top of the List) with no issues across 41,580 simulated years.
