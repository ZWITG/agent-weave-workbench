---
title: "05 Product and Traction"
project: Relivable
phase: investor
status: draft for owner review
updated: 2026-11-13
tags: [relivable, investor, product, traction]
---

# 05 Product and Traction

*Purpose:* What already exists, measured on 13 Nov 2026, so investors can check every claim in the memo and the deck. It also says plainly what is not proven yet.

## 1. Timeline so far
| Date | Milestone |
|---|---|
| 26 Oct 2026 | Phase 1 plan complete (research, full feature spec, business model, budget); first playable Flutter build the same day |
| 27 Oct 2026 | Android app with self-update; Windows installer; the whole life cycle playable ("Whole Life" waves A–G) |
| 30–31 Oct 2026 | iPhone and iPad build and home-screen web app; prison life, heists, the upper-class Echelon, special-career foundations |
| 1 Nov 2026 | **Release 1.0 candidate** after a front-to-back audit and a legal pass; 80-second promo video |
| 7 Nov 2026 | Instagram batch 1 (feed posts, carousel, stories, three Reels) |
| 13 Nov 2026 | Hot Pursuit (police manhunts); the **"Calling" update**: 14 special careers, each with its own Hub, look and people; Instagram batch 2 and the 12-second Reel |

Every named update is listed in `game/CHANGELOG.md`.

## 2. What is built
| Area | State today |
|---|---|
| **Platforms** | Android APK that updates itself on launch; Windows installer and portable zip; iPhone/iPad (web app, plus an unsigned IPA); web. All built automatically by CI on every push |
| **Engine** | Data-driven storylet engine with conditions, weights, flags and callbacks; people remember choices and hold grudges; validator; 500-life simulator |
| **Code and tests** | About 80,700 lines of Dart in 114 source files; 176 automated tests, including a release fuzz test that plays whole dynasties (40,000+ simulated years) and checks that no screen overflows on small phones |
| **Life systems** | Birth to death, 4 visible and 6 hidden stats, school routes, jobs and career ladders, a working economy (tax, loans, index fund, property), relationships with bond facets, love, children, adoption, fostering, surrogacy, health, pets, fame and social media, identity, migration between countries |
| **Content** | 157 data events plus about 50 coded scene families with many branches; 56+ activities; **19 mini-game engines** themed to dozens of activities |
| **Crime and justice** | Planned crimes and heists, lawsuits with retaliation, prison life (gangs, visits, riots, escapes), police manhunts with getaway, break-in and breakout mini-games |
| **Special careers ("Calling")** | 14 careers (actor, musician, athlete, model, politician, armed forces, lawyer and judge, doctor, pilot, vet, street hustler, police, astronaut, fighter), each with its own Hub, signature instrument, seasons, people, stamped results and a Life Recap page |
| **Looks** | The game repaints itself: Night Feed (default), Yard Time (prison), Gilded (the super-rich, entered through the "Molten" moment), and 14 career looks, all tested for readable contrast |
| **World and legacy** | One persistent world per player, a yearly newspaper, news that affects your life, family-name reputation, history entries, Echo events; dynasties up to 8 generations; Life Recap and Dynasty Recap cards |
| **Accessibility** | Screen-reader labels, text scaling, reduce motion, colour-vision modes, left-hand layout (a manual VoiceOver/TalkBack pass is still to do) |
| **Money** | Prices localised to 40+ currencies |
| **Legal hygiene** | Real-world names fictionalised; About and legal section in Settings; 16+ notice; open-source licences page; fonts SIL OFL; all sounds and music generated in-house |
| **Marketing assets** | 80-second promo, two intro videos, 22 feed posts, 16 carousel slides, 4 stories and 4 Reels, all from real gameplay (`game/media/`) |

## 3. What is not proven yet
Investors will ask about these, so name them first:

| Gap | Why it matters | When it closes |
|---|---|---|
| **No real players yet** (only automated testing) | Fun, retention and sharing are still hypotheses | Playtests Dec 2026 (open item F1); soft launch May 2027 |
| **No analytics in the build** | Retention claims need measured data | Before playtests (C3) |
| **No purchases or ads in the build** (Plus is free for everyone for now) | Monetisation is untested | MVP (B1–B3) |
| **Not in the Play Store or App Store yet** | Distribution | Store accounts (A1, A2); soft launch |
| **The name "RELIVABLE" is a registered US trademark of a third party** | Must be resolved before marketing spend | Counsel review now (A7) |
| **Content volume:** about 200 events and scene families vs. 1,500+ at MVP | Repetition is the genre's main complaint | Writers funded by tranche 1 |
| **Saves are on-device only** | A lost phone loses the dynasty, a top genre complaint | Cloud saves at MVP (C1) |

## 4. How to demo it
See the demo path at the end of [[02 Pitch Deck Script]]. To try it before a meeting:
- **Android:** install the APK from the `relivable-latest` release (allow installs from that source once).
- **Windows:** `RelivableSetup.exe` from the same release. SmartScreen warns, because the installer isn't code-signed yet (A3).
- **iPhone:** use the web app and "Add to Home Screen".

Links are in [[00 Phase 2 Development Route]].

**[OWNER: decide whether investors get the public download links or a private build, and remove the self-update from any build you hand out if that matters to you.]**

## 5. How it was built
Product direction, design choices and review are founder-led. Engineering and first-draft writing were produced with AI-assisted development (Claude Code) working from the Phase 1 plan, with every change tested in CI and recorded in the plan ([[_Concept Brief]] decisions 21–32 and the change log).

For investors this means three things:
- **Speed and cost.** Under three weeks from plan to a 1.0 candidate.
- **A documented codebase.** Every feature traces to a planning note or an owner decision.
- **A process risk.** There's a key-person dependency on the founder's direction and on access to AI tooling. [[06 Investor FAQ and Due Diligence]] covers the mitigations.
