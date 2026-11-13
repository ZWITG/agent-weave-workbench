---
title: "06 Investor FAQ and Due Diligence"
project: Relivable
phase: investor
status: draft for owner review
updated: 2026-11-13
tags: [relivable, investor, faq, due-diligence, risks]
---

# 06 Investor FAQ and Due Diligence

*Purpose:* Straight answers to the questions investors are most likely to ask, the risks ranked for an investor, and the data room to prepare.

## 1. Likely questions

### Market and competition
**Why would players leave BitLife?**
They don't have to leave. Life-sim players play several games, and the genre's top complaints (ads after paying, paywalled systems, lost saves, repetition) are exactly what we designed against ([[03 Player Research and Wishlist]]). Our base case needs about a tenth of BitLife's US audience.

**Isn't this a clone?**
No. It's an original game in an established genre, like many farming or match-3 games. We use no BitLife text, names, UI or assets. We keep a banned-terms list, and real-world names are fictionalised. Our distinct features include memory and callbacks, looks that change with your life, the Echelon, 14 career worlds, a shared persistent world and accessibility. The incumbent has used DMCA notices before, so we keep a clean, documented, original codebase (risk R9).

**What stops a clone of us?**
Mainly speed and content. Our engine and pipeline ship content quickly, and the looks and world give the game an identity that is hard to copy cheaply. We don't claim a patent-style moat.

### Product
**Has anyone played it?**
Not at scale. It has been tested by automation (a 500-life simulator and a 40,000-year fuzz test) and by the founder. Playtests with 10–20 players are the first milestone ([[04 Use of Funds and Milestones]]). **[OWNER: add any informal player feedback you have.]**

**Is it fun?**
That is what Gate 2 measures: "want to keep playing" ≥ 4.0 out of 5, and ≥ 70% of players noticing a callback without being prompted ([[12 Risks and KPIs]] §3). Until then, the demo is the evidence.

**How much content is enough?**
The plan targets 1,500+ events at MVP and 3,000+ at launch, so players don't see repeats. Today there are about 200 events and scene families with many branches. Writing is the critical path, and most of the round pays for it.

### Business
**Why so little money per player?**
It's a choice. No forced ads, no paid currency, no pay-per-use undo. Our base ARPDAU ($0.066) is below aggressive hybrid-casual games ($0.15–0.50). We grow it with seasons, Story Packs and price tests, never with the tactics players complain about ([[06 Monetization and Economy]] §9).

**Can you buy users profitably?**
Not in Tier-1 iOS at base-case LTV ($0.53 against CPIs of $1.40–3.00). The plan is organic-first: share cards, Reels made from the game's looks, and creators. Paid UA only in markets where LTV ≥ 1.2× CPI ([[03 Financial Plan]] §4). Soft launch measures this before tranche 2.

**Why will it be profitable in 2028?**
In the base case, 120,000 average daily players earn $2.56M net, against a LiveOps team of about $66K a month and $400K of UA. The conservative case is not profitable. That's why tranche 2 depends on Gate 4.

### Team and execution
**Who is building it?**
**[OWNER: founder bios.]** So far, founder-led design with AI-assisted engineering ([[05 Product and Traction]] §5). The round adds a narrative lead and writers, art, part-time backend and QA, and community roles.

**What if the AI tooling changes or disappears?**
The codebase is ordinary Flutter (Dart). Any Flutter engineer can work on it, and it's covered by 176 tests, CI and a written plan. AI speeds up the work; it isn't a runtime dependency. AI flavour text inside the game is optional and on-device first.

**Key-person risk?**
Yes, the founder. Mitigations:
- Everything is documented: the plan vault, the change log, and tests that pin behaviour.
- The round hires a narrative lead who owns the content pipeline.
- **[OWNER: key-person cover, for example a co-founder or adviser.]**

### Legal and compliance
**The name?**
"RELIVABLE" is a registered US trademark of a third party (classes 41 and 42). Counsel will advise whether to keep, license or rename. Until then it is presented as a working title, and $25K of the round is reserved for name, privacy and rating work.

**Age ratings and minors?**
The content targets 16+ (Apple 16+, Google Mature 17+). US state app-store age laws and the EU rules are mapped in [[09 Compliance and Ratings]]. Ages 13–15 are an open owner decision: block them, or build a softened profile.

**Data and privacy?**
Today the game is fully offline and collects nothing. Accounts, cloud saves and analytics at MVP bring in a privacy policy, consent, account deletion and data export. These are budgeted.

## 2. Risk summary for investors
Ranked from the full register in [[12 Risks and KPIs]] §1, with the risks that are new since Phase 1 added.

| # | Risk | Severity | Mitigation | Tells us early |
|---|---|---|---|---|
| 1 | **Retention below the gates** (D1 < 35%, D30 < 3.5%) | High | Playtests, then soft launch; tranche 2 held until Gate 4 | Gate 2 and Gate 4 readouts |
| 2 | **Organic growth doesn't happen** (LTV < CPI, so paid UA can't carry it) | High | Share cards, seeds, Reels, creators; paid UA only where LTV ≥ 1.2× CPI | Recap share rate < 4% in soft launch |
| 3 | **Name conflict** (RELIVABLE trademark) | High until resolved | Counsel now; rename budget; backup names | Counsel's opinion |
| 4 | **Content throughput** too slow for 1,500 / 3,000 events | High | Writers funded first; AI-assisted first drafts with human editing; throughput measured at Gate 2 | Net events per writer-day < 6 |
| 5 | **Key person** (the founder) | Medium–High | Documentation, tests, narrative lead hire, **[OWNER]** cover | — |
| 6 | **IP claim from the incumbent** | Medium | Original text and art, banned terms, records of authorship | Any notice received |
| 7 | **Rating lands at 18+** | Medium | Implied-only content; questionnaire dry-run | Rating dry-run at Gate 2 |
| 8 | **Platform fee and policy changes** | Low–Medium | Web shop, link-outs where allowed; no reliance on one store | Court and policy news |

## 3. Data-room checklist
**Company** **[OWNER]**
- [ ] Certificate of incorporation, cap table, founder agreements, IP assignment from the founder(s) to the company
- [ ] Any prior funding or loans; board and adviser agreements
- [ ] Bank details for the round; the round documents (SAFE or term sheet)

**Product and IP**
- [ ] Read access to the repository (or a snapshot) and a CI run showing the tests pass
- [ ] Demo builds (Android, Windows, web) and a demo video
- [ ] Records that all text, sounds and code are original; the font licences (SIL OFL); the open-source licence list (in-game)
- [ ] Trademark search results and counsel's opinion (A7)
- [ ] A statement on AI-assisted development: which tools, who reviewed the output, who owns it **[OWNER/legal]**

**Plan and numbers**
- [ ] This investor pack (00–06) as PDFs
- [ ] `Relivable Financial Model.xlsx`
- [ ] The Phase 1 plan vault (`docs/phase-1/`) and the Phase 2 progress notes (`docs/phase-2/`)
- [ ] Playtest results and the Gate 2 readout (once done)

**Compliance**
- [ ] Privacy statement (in-game today), the store privacy policy and terms (when drafted)
- [ ] Age-rating approach ([[09 Compliance and Ratings]])
