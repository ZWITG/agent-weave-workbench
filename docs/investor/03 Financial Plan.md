---
title: "03 Financial Plan"
project: Relivable
phase: investor
status: draft for owner review
updated: 2026-11-13
tags: [relivable, investor, financials]
---

# 03 Financial Plan

*Purpose:* The three-year financial picture for investors: revenue scenarios, costs, cash, unit economics, and which assumptions matter most. The live model is `Relivable Financial Model.xlsx` in this folder.

> [!caution] Planning estimates, not forecasts
> There is no player data yet. Revenue inputs come from the Phase 1 model ([[06 Monetization and Economy]] §6), which is built on third-party benchmarks. Soft launch (from 17 May 2027) replaces these assumptions with measured retention and revenue. Figures are in USD, before tax and interest, and with no founder salary beyond the plan's labour lines.

## 1. Timeline the model follows
| Period | What happens | Source |
|---|---|---|
| Nov 2026 – Jan 2027 | Prototype done; playtests and Gate 2 | [[00 Phase 2 Development Route]] |
| Jan – May 2027 | MVP build (Phase 3) | [[11 Roadmap Team and Budget]] §4.3 |
| 17 May 2027 | Soft launch: Philippines, then Ireland and the Netherlands | [[10 Go-to-Market]] §3 |
| Aug 2027 | Gate 4: soft-launch KPIs decide tranche 2 | [[12 Risks and KPIs]] §3 |
| 12 Oct 2027 | Global launch, then 90 days of launch marketing | [[_Concept Brief]] decision 9 |
| 2028 → | First full year of LiveOps: seasons, Story Packs | [[07 Retention and LiveOps]] |

## 2. Key assumptions
| Input | Conservative | Base | Optimistic | Source |
|---|---|---|---|---|
| Blended ARPDAU (live) | $0.034 | $0.066 | $0.129 | [[06 Monetization and Economy]] §6.3 |
| Net factor (after store fees and ad share) | 91% | 89% | 86% | 06 §6.3 |
| Average DAU 2027 | 4,000 | 15,000 | 40,000 | New assumption (soft launch + Q4 launch) |
| Average DAU 2028 | 30,000 | 120,000 | 400,000 | 06 §6.2 |
| Average DAU 2029 | 25,000 | 140,000 | 450,000 | New assumption |
| LiveOps team per month | $40K | $66K | $99K | [[11 Roadmap Team and Budget]] §4.6 |
| Paid UA 2028 / 2029 | $60K / $40K | $400K / $500K | $1.5M / $2.0M | [[10 Go-to-Market]] §10, scaled by LTV |
| Build cost (Phases 3–4) | $480K | $480K | $480K | 11 §4.5, Low (hybrid team) |

In 2027, soft-launch revenue is counted at 60% of live ARPDAU. The base DAU for 2028 (120,000) is about a tenth of BitLife's US weekly audience in Q2 2025.

## 3. Results
| | Cons. 2027 | Cons. 2028 | Cons. 2029 | **Base 2027** | **Base 2028** | **Base 2029** | Opt. 2027 | Opt. 2028 | Opt. 2029 |
|---|---|---|---|---|---|---|---|---|---|
| Average DAU | 4,000 | 30,000 | 25,000 | 15,000 | 120,000 | 140,000 | 40,000 | 400,000 | 450,000 |
| Net revenue | $27K | $340K | $283K | $192K | **$2.56M** | **$2.99M** | $966K | $16.1M | $18.1M |
| Total costs | $935K | $573K | $553K | $939K | $1.25M | $1.35M | $948K | $2.79M | $3.29M |
| **EBITDA** | −$907K | −$233K | −$269K | −$747K | **$1.32M** | **$1.64M** | $18K | $13.3M | $14.8M |
| Cash at year end | $338K | $105K | −$164K | $498K | $1.82M | $3.46M | $1.26M | $14.6M | $29.4M |

*All costs in 2027 are the same in every scenario: the build ($480K), legal and the name ($25K), launch go-to-market ($425K) and tools. The whole $1.245M raise arrives at the start of 2027. Contingency and the LiveOps buffer are not spent in the model, so they carry into 2028 as cash.*

**How to read it:**
- **Base case:** the low point is about $0.5M of cash at the end of 2027. The game is EBITDA-positive in 2028, its first full year live, and needs no further round.
- **Conservative case:** without action, cash runs out in 2029. In practice Gate 4 catches this in August 2027. Weak soft-launch retention would hold back tranche 2 ($795K), and the game would iterate, pivot or stop with most of that money unspent.
- **Optimistic case:** reaches roughly BitLife's US scale. It assumes the game becomes a hit through sharing, and it isn't needed to justify the round.

## 4. Unit economics
| Measure | Conservative | Base | Optimistic |
|---|---|---|---|
| Net LTV per install (ARPDAU × lifetime days × net factor) | $0.19 | $0.53 | $1.32 |
| Blended CPI assumed | $1.20 | $1.00 | $0.90 |
| LTV ÷ CPI | 0.16 | 0.53 | 1.47 |
| Share of 2028 DAU that must come from organic sources | 97% | 92% | 86% |

**What this means:**
- In every case except the optimistic one, **paid installs don't pay back** at blended prices. The plan's growth engine is organic:
  - Life Recap share cards and seed codes;
  - short-video content made from the game's own looks (two batches already made);
  - creators;
  - store search.
- Paid UA scales only in markets where measured cohort LTV reaches 1.2× CPI ([[10 Go-to-Market]] §10), starting with cheap Android markets (casual Android CPI is about $0.14 globally).
- This is the biggest risk in the plan, and soft launch exists to measure it.

## 5. What moves the numbers most
| Lever | Effect on 2028 base net revenue | How we would pull it |
|---|---|---|
| DAU ±25% | ±$0.64M | Share features, creator programme, store features |
| ARPDAU $0.066 → $0.10 | +$1.3M | Plus price test ($9.99 vs $12.99), Season Pass cadence, Story Packs, web shop (lower fees) |
| Ad cap 8 → 10 a day | about +$0.2–0.3M | A/B test; never forced ads ([[06 Monetization and Economy]] §4) |
| Store fees: link-out and web shop | +2–5 points of margin | US link-out at 0–15% instead of 15–30% |
| Content cost per event | Lower LiveOps cost | AI-assisted first drafts with human editing (already in use) |

## 6. What is deliberately left out
- **Valuation and round terms.** These are for the owner and their advisers.
- **Founder compensation** above the plan's labour lines. **[OWNER]**
- **Revenue from PC and web** beyond the mobile model. Windows and web builds exist but are treated as upside.
- **Optional cloud AI costs.** AI flavour text is optional and on-device first ([[08 Technical Architecture]]).
- **Tax, company formation and interest.**

## 7. How to use the spreadsheet
`Relivable Financial Model.xlsx` has five sheets:
- **Read me**
- **Assumptions:** the yellow cells are inputs.
- **Use of Funds**
- **P&L 2027-2029**
- **Unit Economics**

Every number above is a formula from those inputs. Change one input and every sheet updates. Before a meeting, decide which inputs you'll defend line by line (ARPDAU, DAU, LTV), and keep the sources column with them.
