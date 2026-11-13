---
title: "02 Crime - Next Step"
project: Relivable
phase: 2
status: built (Hot Pursuit, 13 Nov 2026)
updated: 2026-11-13
tags: [relivable, phase-2, crime, prison, plan]
---

# 02 Crime: Next Step

*Purpose:* compare Relivable's crime and prison systems with BitLife's and
with what players ask for, then pick the next piece of crime work.

## 1. What Relivable has today

| Area | What is in the game | Code |
|---|---|---|
| Crimes | 20 crime activities: shoplifting, pickpocketing, graffiti, porch theft, burglary, car theft, street racing, fraud, identity theft, hacking, counterfeiting, insurance fraud, insider trading, embezzlement, tax evasion, extortion, smuggling, assault, armed robbery, murder (with a hitman option), plus the black market | `justice.dart`, `crime_jobs.dart` |
| Planned jobs | Pick a target and a method, sometimes a twist halfway through; street skill grows with each job you get away with | `crime_jobs.dart` |
| Heists | Six targets (jewellers, cash truck, night mail train, gold exhibit, casino vault, central bank), each showing its window first; crew, intel and an after-action report | `heists.dart` |
| Heat and dirty money | Visible heat with its causes, lying low, laundering in three stages, unexplained-wealth checks | `underworld.dart` |
| Crews | Three crews outside prison, five ranks (Associate to Boss), respect, loyalty, rivals, informing, leaving | `underworld.dart` |
| Justice | Evidence that lingers for years, arrest, charge and plea, lawyers, a jury trial with perjury risk, sentencing, appeal, parole, a sealed record, community service, lighter sentences under 18 | `justice.dart` |
| Prison | A complete "inside" game (Lockdown): Yard Time look, the Yard map, jobs, courses, gym, letters, visits, cell items and contraband, three gangs with orders and wars, riots, solitary, bribing guards, escape as a story scene, life on the run, a halfway house | `prison_life.dart`, `gangs.dart`, `cell.dart` |
| Look | Back Alley: the alley that remembers your crimes, the police scanner, case folders, stamped results | `back_alley.dart`, `crime_wall.dart` |
| Mini-games | Only **shoplifting** and **pickpocketing** (sneak and timing) | `ui/minigames.dart` |
| Other side of the law | Police officer and detective jobs with a police case scene; lawsuits both ways | `careers.dart`, `jobs.dart` |

## 2. Relivable compared with BitLife

Sources: the repo's BitLife feature guide (`research_notes/BitLife complete
feature guide/careers_money_crime.md`, `premium_packs_challenges.md`) and web
guides listed in section 6.

| BitLife has | Relivable |
|---|---|
| Burglary as a top-down maze: dogs, homeowners, police turning up at the exit, loot sold at a pawn shop | Burglary is a choice-based job; **no mini-game** |
| Prison escape as a grid maze (the guard moves twice for every move you make); "Houdini" ribbon for 10+ escapes | Escape is a story scene; **no mini-game** |
| Prison riot mini-game (chain 10+ inmates) | Riot is a story scene |
| Bank and train robbery: pick bank, weapon, disguise, getaway; players call it trial and error | Heists show their window and odds first, with an after-action report: **we are ahead here** |
| Mafia pack: six families, five ranks to Godfather, extortion up to $25k, earnings split by rank | Three crews, five ranks, extortion, informants, coups: **comparable; fewer families** |
| Juvenile detention (Criminal update v1.29) | Lighter sentences under 18, **no youth custody** |
| Death penalty (serial killers almost always get it) | **None** (owner decision, section 5) |
| Drug trafficking; Black Market pack with six vendors (including drugs and arms), police confiscation | Black market activity, smuggling; **no drug trade** (owner decision) |
| Street Hustler pack: scam artist, picking streets by police presence and crime level | **No scams or street hustle** |
| Royalty can execute people | Not relevant (no royalty) |
| Paywalled: Mafia, Black Market, Street Hustler and Secret Agent packs, gangs behind Bitizenship | **All crime content free**, as promised in the plan |

Where Relivable is already ahead: odds shown before every crime, evidence and
investigations that follow you for years, laundering, a full justice
process, prison as its own game, and a crime look that reacts to your life.

## 3. What players want

> [!warning] Limits
> Reddit could not be reached from this session (blocked for the search
> tool, and the Reddit mirror and LevelWinner fetches were outside the
> network settings). This section uses the Phase 1 player research
> (`docs/phase-1/03 Player Research and Wishlist.md`,
> `research_notes/Life sim game phase 1/reddit_player_wishlist.md`) plus
> the web guides. It is directional, not a vote count.

What the evidence says about crime specifically:

1. **Opaque crime outcomes annoy players.** The train robbery always says
   "too early" and nobody knows why; bank robbery is described as trial
   and error. *Relivable already shows the odds and reasons. Keep doing
   that in anything new.*
2. **A police academy career** is a repeated request. *We have police and
   detective jobs, but they are thin.*
3. **Lawsuits with retaliation, and jail terms after release.** *Built.*
4. **Skippable maze mini-games** for screen-reader players. *Our rule is
   already "every mini-game has Skip, resolving at 0.6".*
5. **Play that is repetitive, random and low-consequence** is the
   genre's fourth-biggest complaint ("passive decision-making"). *Crime is
   where players most want moments that feel like their own doing.*
6. **Paywalled crime** (Mafia, Black Market and Street Hustler packs, prison
   gangs behind Bitizenship) is part of the number-two complaint, paywall
   creep. *Keep all crime free.*

Inference: the crime moments players remember from BitLife are the **maze
mini-games** (burglary and prison escape) and the **big swings** (heists,
the Mafia). What they complain about is **not knowing why** they failed and
**paying** for it.

## 4. Options, scored

Scored 1–5 for player value (V), how much it closes a BitLife gap (G) and
effort (E, 5 = smallest).

| # | Option | V | G | E | Notes |
|---|---|---|---|---|---|
| 1 | **Crime you play:** burglary break-in, getaway chase, prison escape, all original mini-games with odds shown and Skip | 5 | 5 | 3 | The biggest gap; answers "passive" play |
| 2 | **Manhunt:** red-hot heat becomes a real chase: Most Wanted, roadblocks, bounty hunters, people who know you tempted by the reward (betrayal by bond) | 5 | 3 | 4 | Builds on the bounty and poster just shipped; original, not in BitLife |
| 3 | **Police academy and detective path:** academy, cases that use the same evidence system from the other side, undercover work in a crew, corruption | 4 | 3 | 2 | The top request in this area; big writing job |
| 4 | **Youth custody:** a short young-offender centre, its own small "inside" for under-18s | 3 | 4 | 4 | Reuses Lockdown |
| 5 | **Street hustle and scams:** con games, picking a street by police and footfall | 3 | 4 | 3 | Paid pack in BitLife; free here |
| 6 | **More crews:** six crews with territory on a city map and turf wars | 3 | 2 | 2 | Nice, but less asked for |
| 7 | **Country law:** sentences, death penalty and drug laws that follow the country | 3 | 3 | 3 | A differentiator; needs owner decisions (section 5) |

## 5. Decisions only the owner can make

| # | Decision | Why it matters |
|---|---|---|
| D1 | **Drug trade, yes or no?** BitLife has it (Black Market pack, drug trafficking). | Affects the age rating (`09 Compliance and Ratings`, open item A5: 16+ confirmed? 13–15 build?). Option: keep it abstract ("contraband") |
| D2 | **Death penalty, yes or no?** If yes, only in countries that have it, with appeals and a long wait. | Heavy theme; rating questionnaires ask about it |
| D3 | **Mini-game style.** Original designs only (proposal below), not copies of BitLife's mazes. | The project rule: genre mechanics yes, recreations no |

## 6. Recommended next step: "Crime 3: Hot Pursuit"

Do **options 1 and 2 together** as one update, because they feed each other.
The mini-games make crimes playable, and the manhunt turns high heat into
gameplay instead of only a warning.

### 6.1 Three original mini-games (option 1)

All follow the existing mini-game rules: the odds and what helps are shown
first, Skip resolves at 0.6, reduce motion and screen readers get a
turn-based version, and every result explains itself in the after-report.

| Mini-game | Plays when | Idea (original) | Feeds into |
|---|---|---|---|
| **Break-in** | Burglary (and the burglary step of crew jobs) | A house as a floor plan seen from above. Rooms light up as you open them. The occupants' torch beams sweep on a pattern you can read. Grab valuables (each has a weight; a full bag is slower). A noise meter fills with every move; leave by any window before it fills. Floor plan, alarm and dog are shown on a casing card before you go in | Take (fenced through the black market), evidence left, heat |
| **Getaway** | After a robbery, heist, car theft or street race when the alarm went off | A top-down drive through the player's city grid, pursued by police cars that close in; side streets, a car swap point, a tunnel that breaks line of sight. Heat sets the number of cars | Escape: clean or seen. Caught: arrest scene |
| **Breakout** | Plan an escape, in prison | Turn-based: the yard at night as a grid, a searchlight that sweeps on a fixed rhythm and two guards on routes you can study for a turn before you move. Tools from the cell (cutters, a uniform, a bribed gate) open shortcuts | Escape: life on the run. Caught: solitary plus years |

### 6.2 The manhunt (option 2)

- **Most Wanted** at heat 70+: the city's list of wanted people, with your
  photo and the bounty from `crime_wall.dart`.
- **Yearly manhunt events** while you are Most Wanted: roadblock (Getaway),
  dawn raid on your home (hide the bag of cash: dirty money at risk),
  bounty hunter at the door, a TV appeal.
- **Betrayal by reward:** friends, a partner or crew members with low bond
  and money worries may tip off the police; a high bond protects you. Shown
  as a scanner line ("caller says they know where Raphaël Thomas is
  sleeping") before it happens, so it never comes out of nowhere.
- **Ways out:** leave the country (ties into migration), a new identity
  (black market papers), turn yourself in for a lighter sentence, or wait
  it out.
- **Back Alley ties:** the WANTED poster gets your initials; the scanner
  reports the manhunt; the alley's police lights stay on.

### 6.3 Work plan

| Step | Work | Done when |
|---|---|---|
| 1 | Engine: `manhunt.dart` (Most Wanted, yearly events, tip-offs by bond and need, ways out) with tests | Fuzz runs with Most Wanted lives show no stuck states; tip-off odds visible |
| 2 | Getaway mini-game (reuses the lanes and reaction game parts) | Playable at 320×568; skip and reduce-motion versions; render check |
| 3 | Break-in mini-game, the casing card and the fence | Same, plus burglary picks it up from Crime › Theft |
| 4 | Breakout mini-game with cell tools | Same; escape scene offers it |
| 5 | Manhunt scenes and scanner, poster and feed lines | Each event wears Back Alley; stamped results |
| 6 | Full test run, release fuzz, render checks, ship | All tests pass; screenshots reviewed |

Rough size: similar to the Echelon update (about 5–7 working sessions).

### 6.4 After that

1. **Police academy and detective path** (option 3): **built 13 Nov 2026**
   (`engine/policing.dart`): academy tests played as mini-games, casework on
   the same evidence scale, promotion by closed cases, crew bribes and
   Internal Affairs, undercover operations, and a badge card on Path.
2. **Crime linked across careers: built 13 Nov 2026**
   (`engine/career_law.dart`): job-based odds, convictions ending the
   careers that cannot carry one, a cop's own crimes on the Internal Affairs
   file and on their own desk, crews and the Most Wanted list for cops,
   lawyers defending themselves and records costing votes. Each special
   career also wears its own look (`theme.dart` `careerLooks`,
   `ui/career_curtain.dart`) as groundwork for the special careers update.
3. **Youth custody** (option 4) and **street hustle** (option 5) as a
   smaller update.
4. **Country law** (option 7), once D1 and D2 are decided.

## 7. Sources

- Repo research: `research_notes/BitLife complete feature guide/careers_money_crime.md`, `premium_packs_challenges.md`, `history_updates.md`; `docs/phase-1/03 Player Research and Wishlist.md`; `research_notes/Life sim game phase 1/reddit_player_wishlist.md`
- Black Market pack: [Level Winner](https://www.levelwinner.com/bitlife-black-market-update-guide-everything-you-need-to-know-about-the-black-market-expansion-pack/), [GameSkinny](https://www.gameskinny.com/tips/bitlife-how-to-use-the-black-market/), [Prima Games: arms dealer](https://primagames.com/tips/how-to-purchase-weapons-from-an-arms-dealer-in-bitlife)
- Street Hustler pack: [Pro Game Guides](https://progameguides.com/bitlife/bitlife-street-hustler-update-everything-you-need-to-know/), [Prima Games](https://primagames.com/tips/how-to-become-a-street-hustler-in-bitlife), [Prima Games: scam a cop](https://primagames.com/tips/how-to-scam-a-cop-in-bitlife)
- Mafia: [Prima Games](https://primagames.com/tips/how-to-become-a-mafia-boss-in-bitlife), [Pro Game Guides](https://progameguides.com/bitlife/how-to-become-a-mafia-boss-in-bitlife/), [Destructoid: extortion](https://www.destructoid.com/how-to-extort-money-from-a-ceo-in-bitlife/)
- Burglary and robbery: [Pro Game Guides: burglary](https://progameguides.com/bitlife/how-to-burgle-and-rob-a-house-in-bitlife/), [Gamer Journalist](https://gamerjournalist.com/bitlife-burglary-burgle-houses), [Gfinity: bank robbery](https://www.gfinityesports.com/bitlife/bank-robbery/), [Gamezebo: train robbery](https://www.gamezebo.com/walkthroughs/bitlife-train-robbery-guide-how-to-rob-a-train-and-get-away-with-it/), [Pro Game Guides: Criminal update v1.29](https://progameguides.com/bitlife/bitlife-criminal-update-patch-notes-v1-29/)
- Prison escape: [Pocket Gamer](https://www.pocketgamer.com/bitlife-life-simulator/how-to-escape-every-prison), [Gamezebo](https://www.gamezebo.com/walkthroughs/bitlife-life-simulator-how-to-escape-from-jail/)
- Execution (royalty only): [Pro Game Guides](https://progameguides.com/bitlife/how-to-execute-someone-in-bitlife/)
