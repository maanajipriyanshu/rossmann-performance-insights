# Executive Summary — Rossmann Sales Performance

**Scope:** 1,115 stores, 844,338 trading days, 2013–2015 (2015 partial, through July).
**Method:** PostgreSQL analysis on cleaned and merged sales + store metadata, cross-validated against Python EDA and a Power BI dashboard.

## The headline numbers

- Chain-wide average daily sales: **€6,956**
- Total sales across the period: **€5.87B**
- Promotions lift average sales by **38.8%**
- Nearly half the chain (**43.7%**) is underperforming the chain average

## Findings and what they mean for the business

### 1. Promotions work, but not evenly across store types

Across the whole chain, promo days average €8,228.74 against €5,929.83 on non-promo days. Clear effect, chain-wide. But it isn't uniform: break out the Q4 window (Oct–Dec) by store type and Store Type A gets a 38.3% lift from promotions, while Type B, already the strongest performer, gets only 19.4%. Type B stores are likely close to capacity already during the holiday season, so the marginal return on promo spend there is roughly half what it is for Type A.

**Recommendation:** Shift more of the Q4 promotional budget toward Type A and Type D stores (32.9% lift), and treat Type B promo spend in Q4 as lower priority. Not zero, just lower. The budget works harder where the lift is bigger.

### 2. Store performance is concentrated, and the long tail is large

Store 817 alone does €21,757/day, more than 3x the chain average, and the top 10 stores all clear €16,500. Good for a highlight reel. But the more important number is the tier breakdown: only 7.0% of stores qualify as "Elite" (≥150% of average), while 43.7% sit below 90% of average. That's over 480 stores.

**Recommendation:** The "celebrate the top 10" framing undersells where the real opportunity is. A 5-percentage-point improvement in the Underperformer tier, moving stores from below 90% into the 90–110% "On Track" band, would likely have a bigger total revenue impact than squeezing more out of the already-strong top 10, just because of how many stores are involved. Worth a follow-up: are the Underperformer stores clustered by region, competition distance, or store type, or is it spread evenly?

### 3. Store Type B looks like the format to expand, with one caveat

Type B averages €10,233/day, 48% above the next-best type (C at €6,933). On its face this argues for opening more Type B stores. The caveat: there are only 17 Type B stores in the dataset, against 602+ Type A stores. A 48% lift on a sample of 17 is a real signal but not yet a statistically settled one, and Type B is the format with the *smallest* incremental promo response in Q4, meaning each new Type B store may already need less promotional support to perform.

**Recommendation:** Before committing capital to expanding Type B format, validate the finding against a larger sample if more stores are available, or examine whether Type B's strong baseline is location-driven (urban placement, foot traffic) rather than format-driven.

### 4. Seasonality is real and worth planning inventory around, not just promo timing

December sales run 49% above the January low (€8,609 vs. €6,564), with November already climbing ahead of it. Not a surprising result for retail, but a good sanity check that the data behaves the way it should. It's also a reminder to look at December on its own rather than folding it into "Q4" generally, since it pulls averages upward for any store open through the season.

**Recommendation:** Treat November–December as its own planning window instead of lumping it into Q4 or year-end. The December spike is sharp enough that blending it with October and November understates how concentrated the effect really is.

### 5. The 2014→2015 "decline" is a data artifact, not a real trend

Raw totals make 2015 look like a sharp drop (€1.39B vs €2.18B in 2014). That's misleading: 2015 in this dataset only runs through July, so it's getting compared against full years. Correct for trading days and average daily sales actually grew 9.7% in 2015, against a 5.3% decline the year before.

**Recommendation:** Any year-over-year comparison on this dataset, or on any retail dataset with a partial final year, needs to use a daily-average or trading-day-adjusted metric, not raw totals. Easy trap to fall into. A quick raw-totals read here would have landed on the opposite, wrong conclusion.

## What still needs validation

- Day-of-week sales: the original EDA flagged Sunday and Monday as peak days based on raw averages, but Sunday is only traded by a small subset of stores, so that average isn't directly comparable to the other six days. Monday holds up as the strongest day with broad store participation. Sunday needs the open-store count reported alongside it before it's cited as a "peak day" finding. See `notebooks/02_eda.ipynb` for the corrected version.
- The Type B sample-size caveat above (17 stores) means that finding should be treated as a hypothesis to test further, not a settled conclusion.

## Bottom line

The chain's growth lever isn't the top 10 stores, it's the 480+ stores sitting below 90% of average. Promotional spend is currently not allocated where it has the most marginal impact, and the 2014–2015 "decline" that raw totals suggest doesn't actually exist once trading days are accounted for correctly.