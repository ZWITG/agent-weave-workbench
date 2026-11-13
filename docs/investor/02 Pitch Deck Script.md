---
title: "02 Pitch Deck Script"
project: Relivable
phase: investor
status: draft for owner review
updated: 2026-11-13
tags: [relivable, investor, deck, pitch]
---

# 02 Pitch Deck Script

*Purpose:* The investor deck, slide by slide: what goes on screen, what to say, and how long to take. It replaces the client deck in [[13 Client Pitch Script and FAQ]] for investor meetings.

> [!info] The visual deck
> Built as "Relivable Investor Deck" (https://claude.ai/artifact/Vh7d3JooSz8GJR8trU4M4P; private until you share it from its Share menu, and it exports to PowerPoint or PDF). It has 15 slides: the 13 below, plus a **Team** slide before the ask (fill its bracketed fields) and a closing **Live demo** slide. Speaker notes on each slide carry the "Say" text.

> [!tip] Format
> **13 slides, about 12 minutes, then a 5-minute live demo and Q&A.** One idea per slide. Show real screens from the game, not mock-ups: stills are in `game/media/social/` and `game/media/social/calling/`, and `game/tool/render_*_test.dart` renders more. Put the Reel on slide 1, or play it as people sit down.

| # | Slide | Time | Cumulative |
|---|---|---|---|
| 1 | Hook | 0:45 | 0:45 |
| 2 | The problem | 1:00 | 1:45 |
| 3 | The opening | 0:45 | 2:30 |
| 4 | Relivable | 1:00 | 3:30 |
| 5 | The game changes with your life | 0:45 | 4:15 |
| 6 | Proof: built in under three weeks | 1:15 | 5:30 |
| 7 | Market | 0:45 | 6:15 |
| 8 | Business model | 1:00 | 7:15 |
| 9 | Growth | 1:00 | 8:15 |
| 10 | Competition | 0:45 | 9:00 |
| 11 | Financials | 1:00 | 10:00 |
| 12 | Roadmap and milestones | 0:45 | 10:45 |
| 13 | The ask | 1:00 | 11:45 |

---

### Slide 1: Hook (0:45)
**On screen:** the 12-second Reel playing full screen (`game/media/social/calling/reel_calling.mp4`). The last frame holds: "Pick a job. The whole game changes."
**Say:** "That is a real game, already playable on Android, Windows, iPhone and the web. It's a life simulator: you're born, you live one year per tap, you make choices, and your family carries on after you. It's a genre that already makes tens of millions a year for one company. We think it's ready for a better game."

### Slide 2: The problem (1:00)
**On screen:** three headline numbers.
- BitLife: 50M+ Google Play installs.
- About $9–11M of revenue a quarter.
- Organic revenue down 19% in Q1 and Q2 2026 when paid UA was cut.

Underneath, three player quotes about ads after paying, lost purchases and repetitive events ([[03 Player Research and Wishlist]]).

**Say:** "The genre has one leader, and its players are tired of it. Since 2023 new systems arrive as paid packs, up to a $21 Boss Mode. Saves and purchases get lost. When the company cut paid ads this year, organic revenue fell 19% two quarters running. Big audience, low goodwill, no real challenger."

### Slide 3: The opening (0:45)
**On screen:** a timeline.
- The Sims Mobile closed (Jan 2026).
- Life by You cancelled (2024).
- Apple 0% link-out in the US and Google alternative billing (2026).
- Loot-box rules and the EU Digital Fairness Act.

**Say:** "The visual competitors have left. Store fees are falling. Regulators are pushing exactly the fair monetisation we chose anyway. The window is open now."

### Slide 4: Relivable (1:00)
**On screen:** the one-liner "A life sim where every choice is remembered", then the five pillars as icons:
- Remembered
- One tap
- Fair forever
- Share your story
- Accessible

Show a Life feed screen with an event card next to them.

**Say:** "Relivable keeps everything players love and fixes what they complain about. People remember you: the brother you sued turns up at your door fifteen years later. Everything is one tap away, and locked actions tell you why. Every career is free, and there's no paying to undo a mistake. Every life ends in a shareable recap. And it works with a screen reader from day one."

### Slide 5: The game changes with your life (0:45)
**On screen:** a grid of six screens:
- Night Feed (the default look).
- Yard Time (prison).
- Gilded (the super-rich).
- Marquee (actor).
- Orbit (astronaut).
- Fight Night (fighter).

**Say:** "This is what people remember after the meeting. The whole game repaints itself around your life: colours, type, sounds, even the words on the buttons. Go to prison and it's stencil type and cell bars. Make $100 million and molten gold pours down the screen. Fourteen careers each have their own world. Text games don't usually look like this, and every one of these moments is made for short video."

### Slide 6: Proof: built in under three weeks (1:15)
**On screen:** "26 Oct → 13 Nov 2026" and a stat block:
- About 80,700 lines of code.
- 176 automated tests, including a 40,000-year fuzz test.
- 200+ story events and scenes.
- 19 mini-game engines.
- 14 career worlds.
- 4 platforms.
- Promo video and two social batches.

Small print: "Plan budget for this prototype: $25–60K over 8 weeks."

**Say:** "Our plan said a prototype would take eight weeks and up to $60K. We went past it in under three weeks, with founder-led design and AI-assisted engineering. That changes the economics of content, which is this genre's bottleneck. What we haven't done yet is put it in front of real players at scale. That's the first thing this money does."

### Slide 7: Market (0:45)
**On screen:**
- Life Simulator: a top hybrid-casual subgenre, US Android ARPU about $11–15.
- BitLife's US revenue: about $14–26M a year (Sensor Tower, H1 2025).
- Target markets: English first, then Spanish, Brazilian Portuguese, German and French.

**Say:** "We don't need to replace BitLife to build a good business. Our base case is about a tenth of its audience."

### Slide 8: Business model (1:00)
**On screen:** the price ladder:
- Free, with capped opt-in ads.
- Relivable Plus, $9.99 one-time.
- Season Pass, $4.99.
- Story Packs, $2.99–3.99.
- Cosmetics.

A banner across it: "No loot boxes · no paid currency · no pay-per-use undo".

**Say:** "Fair is the product, not a slogan. Plus is a one-time unlock. Ads are opt-in and capped at eight a day. Our base case earns about 6.6 cents per daily player, more from purchases than ads. That's below the most aggressive games in the genre, by choice. Seasons and Story Packs grow it over time."

### Slide 9: Growth (1:00)
**On screen:** a Life Recap share card, a Reel still and a seed code (`#RL-…`). Below them: "Base LTV $0.53 vs Tier-1 iOS CPI $1.40–3.00 → organic first".
**Say:** "We're honest about unit economics. In the base case a player is worth about 53 cents. That doesn't pay for Tier-1 iOS installs. So the plan is organic: every life ends in a recap card made to be shared, seed codes let players challenge friends, and the game's looks make ready-made Reels. We already make that content from real gameplay. Paid ads go only where lifetime value beats cost, starting with cheap Android markets."

### Slide 10: Competition (0:45)
**On screen:** a 2×2 grid. One axis: depth of consequences. The other: fairness of monetisation.
- BitLife: deep, unfair.
- Clones: shallow, unfair.
- Visual sims: exited.
- Relivable: deep, fair.

**Say:** "Clones copy BitLife's structure and its monetisation. We compete on memory, look and fairness, and on the speed we can ship content."

### Slide 11: Financials (1:00)
**On screen:** the 2028 table from [[03 Financial Plan]]: conservative, base and optimistic, with DAU, net revenue, EBITDA and cash.
**Say:** "Base case: 120,000 daily players in 2028, $2.6M net revenue, $1.3M EBITDA, profitable in the first full year live. The conservative case loses money, and that's why the second tranche only comes after soft launch proves retention. The model's in the data room. Change the assumptions yourself."

### Slide 12: Roadmap and milestones (0:45)
**On screen:** a timeline:
- Playtests and Gate 2 (Dec 2026–Jan 2027).
- Tranche 1 close (Q1 2027).
- Soft launch (17 May 2027).
- Gate 4 (Aug 2027).
- Global launch (12 Oct 2027).
- LiveOps steady state (Jan 2028).

**Say:** "Every step has a gate with numbers attached. If soft launch misses the retention gates, we iterate or stop before most of the money is spent."

### Slide 13: The ask (1:00)
**On screen:** "$1.25M in two tranches", with the use of funds in two columns:
- **Tranche 1, $450K:** MVP, legal and name, soft launch.
- **Tranche 2, $795K:** global launch, 90 days of marketing, LiveOps buffer.

Then the instrument **[OWNER]** and contact details.

**Say:** "We're raising $1.25M. $450K now takes the game to soft launch with real retention data. $795K follows only if those numbers clear the gate, and takes it to global launch. Then I'd like to show you the game."

---

## Live demo (5 minutes)
Use a phone with these saves ready:
1. **A fresh life (1 min):** create a character and age up a few years. Show the year feed, an event card with a choice, and a result pop-up.
2. **A special career (1.5 min):** open the Career Hub (actor or astronaut). Show the look, the instrument, the season and a played mini-game, then a stamped result.
3. **Consequences (1 min):** a save with an old grudge or an Echo event, where something from years ago comes back.
4. **The extremes (1 min):** cross $100M to show Molten turning into Gilded, or go to prison to show Yard Time.
5. **The ending (0:30):** a death, the Life Recap story cards, the share card and the heir carrying on.

**Backups:** a screen recording of the same path, in case the phone or the venue's Wi-Fi fails (the game runs offline anyway). If you have time to show a desktop, use the Windows build on a laptop.

## Design notes for the visual deck
- Build each slide in the game's own looks: Night Feed for the core slides, and the look that matches the content elsewhere (Gilded for financials works well).
- Use only fonts already licensed in the repo (Sora, Playfair Display, Stardos Stencil, Caveat; all SIL OFL).
- Mark every estimate as an estimate, and put sources in the speaker notes, not on the slides.
- Label the name a working title until the trademark question is answered.
