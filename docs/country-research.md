# Country research notes

How each country is represented in Relivable, and where the numbers come
from. The game data lives in `game/lib/engine/world_data.dart`
(`CountryProfile`); life in a country is applied in
`game/lib/engine/country_life.dart`, `careers.dart` (pay), `economy.dart`
(living costs), `homes.dart` and `property.dart` (house prices and rent),
`school.dart` (university fees), `engine.dart` (retirement age) and
`more_actions.dart` (gambling and driving ages).

Researched on 31 October 2026. Direct access to Wikipedia, Numbeo, the World
Bank and Reddit was blocked in the build environment, so figures were taken
from search-result summaries of those sources plus well-established facts.
Anything marked **approx.** should be checked against the primary source
before it is treated as exact.

## What players say

Searches of player reviews, guides and community pages about BitLife, the
best-known life simulator, found:

- Countries are seen as **mostly cosmetic**: one guide says there are no real
  differences between cities and only very small ones between countries,
  with **age restrictions** making up most of the difference
  ([Gfinity](https://www.gfinityesports.com/bitlife/city/)).
- Players **pick countries strategically** for perks they believe in, such
  as low taxes or long lives
  ([TouchTapPlay](https://www.touchtapplay.com/where-is-the-best-place-to-live-in-bitlife/)).
- Reviews ask for **more country-specific events and options**, more
  countries, and travel that matters (attending a parent's funeral abroad,
  for example) ([AppleVis comments](https://www.applevis.com/comment/107983),
  [App Store](https://apps.apple.com/ie/app/bitlife/id1374403536)).
- Country rules that do exist (royalty, arranged marriage, legal ages) are
  the parts players notice and talk about
  ([BitLife country guides](https://www.touchtapplay.com/bitlife-how-to-be-born-in-denmark/)).

No Reddit threads could be read directly (access blocked). Design response:

1. Make countries differ in **things that change a life**, not just labels:
   pay, prices, rent and house prices, university fees, retirement age,
   military service, safety, and legal ages that are actually enforced.
2. Give each country **local yearly moments** (festivals, weather, everyday
   frustrations) drawn from what living there is like.
3. Show it all on the **country card** in plain words, so moving abroad is a
   real decision.

## Mechanics and how they use the data

| Field | Effect in the game |
|---|---|
| `wage` | Multiplies every career salary, part-time and apprentice pay |
| `cost` | Multiplies living costs, rents and house prices |
| `tuition` | Multiplies university and graduate fees (0 = free) |
| `draft` / `draftMonths` | Call-up scene at 18: serve, defer while studying, civilian service, or (where universal) dodge |
| `retireAge` | When the retirement offer comes |
| `safety` | How often phone snatching, scams and theft happen (low 10, medium 5, high 2 in 100 a year) |
| `gamblingAge` | Casino age; 0 means banned for citizens |
| `drivingAge` | When driving lessons open |
| `local` | One local moment about one year in three |
| `everyday`, `culture` | Shown on the country card |

`wage` and `cost` are **compressed** game multipliers (United States = 1.0):
the real gaps between, say, Norway and Nigeria are larger than any game
balance allows, so the order and rough gaps follow the data while every
country stays playable.

## Sources by topic

- **Wages (relative order)**: OECD average annual wages via Trading Economics
  for OECD members (Canada ~$69k, UK ~$64k PPP, 2024)
  ([Trading Economics](https://tradingeconomics.com/canada/average-annual-wages)),
  plus widely reported national averages for non-OECD countries. **approx.**
- **Cost of living (relative order)**: Numbeo cost-of-living index summaries
  (NYC = 100; e.g. Indonesia ~26, Vietnam ~26)
  ([Voronoi](https://www.voronoiapp.com/economy/How-expensive-each-country-is-relative-to-New-York-City-7114)).
  **approx.**
- **Life expectancy**: World Bank based rankings, 2024: Sweden 84.1, Italy
  84.0, Spain 83.9, South Korea 83.6, China 78, Nigeria ~55, South Africa
  66.1 (2023), Argentina ~77 (2023), Egypt ~69 (2024), Kenya ~64
  ([The Global Economy](https://www.theglobaleconomy.com/rankings/Life_expectancy/),
  [Statistics of the World](https://statisticsoftheworld.com/country/south-africa/life-expectancy),
  [GeoRank](https://georank.org/life-expectancy/argentina/kenya)).
- **University fees**: free at German public universities (small semester
  fee), free state universities in Brazil and Argentina, France €170+ a year
  for undergraduates; Philippines free tuition at state universities since
  2017 ([Expatsi](https://expatsi.com/29-countries-with-free-college-tuition),
  [QS](https://www.topuniversities.com/node/277414)).
- **Same-sex marriage**: 38 countries as of 2025, including Thailand and
  Liechtenstein from 2025
  ([Pew Research](https://www.pewresearch.org/religion/fact-sheet/same-sex-marriage-around-the-world/)).
  Italy has civil unions only.
- **Military service**: South Korea 18 months (army) for men; Egypt up to 36
  months depending on education; Sweden selective conscription since 2018;
  Brazil and Mexico compulsory in law with few called up / lottery
  ([HonestMOS](https://www.honestmos.com/compare/conscription-length),
  [Statista](https://www.statista.com/chart/35551/military-services-compulsory-and-voluntary-in-european-countries)).
- **Retirement ages**: France's 2023 reform (64) suspended in 2025, holding
  the age at 62 years 9 months until 2027
  ([JURIST](https://www.jurist.org/news/2025/11/france-votes-to-suspend-pension-reform-law),
  [Connexion](https://www.connexionfrance.com/news/visual-how-does-suspension-of-pension-reform-affect-workers-in-france/748900));
  China rising from 60 to 63 for men from 2025
  ([Malay Mail](https://www.malaymail.com/news/world/2024/09/13/china-to-raise-retirement-age-from-2025-to-63-for-men-and-55-or-58-for-women-depending-on-job-type/150309));
  Spain 67 by 2027, Italy 67, Mexico 65
  ([Kiplinger](https://www.kiplinger.com/retirement/retirement-planning/from-age-55-to-70-why-your-passport-is-the-biggest-factor-in-retirement-age)).
  Others are well-established statutory or pension ages. **approx.** where the
  country has several ages (by sex or job).

## Country table (game values)

| Country | Pay | Cost | University | Service | Retire | Safety |
|---|---|---|---|---|---|---|
| United States | 1.00 | 1.00 | 1.00 | none | 67 | medium |
| Australia | 0.92 | 0.95 | 0.60 | none | 67 | high |
| Ireland | 0.90 | 0.95 | 0.25 | none | 66 | high |
| Netherlands | 0.88 | 0.92 | 0.25 | none | 67 | high |
| United Kingdom | 0.85 | 0.90 | 0.80 | none | 66 | medium |
| Canada | 0.85 | 0.90 | 0.60 | none | 65 | high |
| Germany | 0.85 | 0.88 | 0 | none | 67 | high |
| Sweden | 0.80 | 0.85 | 0 | selective | 67 | high |
| France | 0.78 | 0.90 | 0.05 | none | 63 | medium |
| Japan | 0.72 | 0.72 | 0.40 | none | 65 | high |
| South Korea | 0.72 | 0.83 | 0.50 | 18 months | 63 | high |
| Spain | 0.60 | 0.72 | 0.15 | none | 67 | high |
| Italy | 0.60 | 0.80 | 0.15 | none | 67 | medium |
| Portugal | 0.48 | 0.70 | 0.12 | none | 66 | high |
| China | 0.45 | 0.55 | 0.15 | none | 63 | high |
| South Africa | 0.42 | 0.55 | 0.25 | none | 60 | low |
| Mexico | 0.32 | 0.55 | 0.05 | lottery | 65 | low |
| Argentina | 0.32 | 0.50 | 0 | none | 65 | medium |
| Brazil | 0.30 | 0.50 | 0 | lottery | 65 | low |
| India | 0.22 | 0.38 | 0.10 | none | 60 | medium |
| Philippines | 0.20 | 0.48 | 0 | none | 60 | medium |
| Kenya | 0.20 | 0.45 | 0.15 | none | 60 | low |
| Egypt | 0.16 | 0.35 | 0.05 | 24 months | 60 | medium |
| Nigeria | 0.15 | 0.42 | 0.10 | none | 60 | low |

New in this pass: South Korea, France, Spain, Italy, China, South Africa,
Egypt, Sweden, Argentina and Kenya.

## Still to verify

- Exact average wages and cost-of-living indices for every country (Numbeo,
  ILO/World Bank) once those sites can be reached.
- Player comments from r/BitLife and similar communities, read directly.
- Retirement ages that differ by sex or job (China, Brazil, Argentina).
