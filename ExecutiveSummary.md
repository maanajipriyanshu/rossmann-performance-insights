# Executive Summary - Rossmann Sales Performance

**Scope:** 1,115 stores, 844,338 trading days, 2013–2015 (2015 partial, through July).
**Method:** PostgreSQL analysis on cleaned and merged sales + store metadata, cross-validated against Python EDA and a Power BI dashboard.

## The headline numbers

- Chain-wide average daily sales: **€6,956**
- Total sales across the period: **€5.87B**
- Promotions lift average sales by **38.8%**
- Nearly half the chain (**43.7%**) is underperforming the chain average

## Findings and what they mean for the business

### 1. Promotions work, but not evenly across store types

Across the whole chain, promo days average €8,228.74 against €5,929.83 on non-promo days. Clear effect chain-wide. But break out Q4 (Oct-Dec) by store type and Store Type A gets a 38.3% lift from promotions, while Type B - already the strongest performer - gets only 19.4%. Type B stores are likely near capacity during the holiday season, so the marginal return on promo spend there is roughly half what it is for Type A.

**Recommendation:** Shift more Q4 promotional budget toward Type A and Type D stores (32.9% lift). Type B promo spend in Q4 is lower priority - the budget works harder where the lift is bigger.

### 2. Store performance is concentrated, and the long tail is large

Store 817 does €21,757/day, more than 3x the chain average, and the top 10 stores all clear €16,500. But the more important number is the tier breakdown: only 7.0% of stores qualify as Elite (≥150% of average), while 43.7% sit below 90% of average - over 480 stores.

**Recommendation:** A 5-percentage-point improvement in the Underperformer tier would likely have a bigger total revenue impact than pushing the already-strong top 10 further, just because of how many stores are involved. A useful follow-up: are the Underperformer stores clustered by region, competition distance, or store type, or spread evenly across the chain?

### 3. Store Type B looks like the format to expand, with one caveat

Type B averages €10,233/day, 48% above the next-best type (C at €6,933). The caveat: there are only 17 Type B stores in the dataset, against 602+ Type A stores. A 48% lift on 17 stores is a real signal but a thin sample, and Type B also has the smallest incremental promo response in Q4 - meaning each new Type B store may need less promotional support to perform.

**Recommendation:** Before committing capital to expanding Type B format, validate the finding with a larger sample if available, or examine whether Type B's strong baseline is location-driven (urban placement, foot traffic) rather than format-driven.

### 4. Seasonality is real and worth planning around

December sales run 49% above the January low (€8,609 vs. €6,564), with November already climbing ahead of it. Expected for retail, but worth noting: December pulls Q4 averages up sharply, so blending it with October and November understates how concentrated the effect actually is.

**Recommendation:** Treat November–December as its own planning window rather than folding it into a general Q4 view. The spike is sharp enough that the distinction matters for both inventory and staffing.

### 5. The 2014→2015 "decline" is a data artifact

Raw totals make 2015 look like a sharp drop (€1.39B vs. €2.18B in 2014). That's because 2015 in this dataset only runs through July. Correct for trading days and average daily sales actually grew 9.7% in 2015, against a 5.3% decline the year before - the opposite of what raw totals suggest.

**Recommendation:** Any year-over-year comparison on a dataset with a partial final year needs to use daily-average or trading-day-adjusted figures, not raw totals.

### 6. Sunday's "peak day" status is a sample-size problem

Only 33 of 1,115 stores open on Sundays, against the full chain every other day. Those 33 stores average €8,224.72 - nearly matching Monday's full-chain average of €8,216.25 - but that's 3% of the chain, almost certainly a cluster of high-traffic locations, compared against 100% of stores on Monday.

**Recommendation:** Drop Sunday from any "best trading day" framing unless the store count is shown alongside it. Monday is the correct answer to which day performs best chain-wide. Whether more stores should open on Sundays is a separate question, and a different analysis.

## What still needs validation

The Type B finding (17 stores) should be treated as a hypothesis to test further, not a settled conclusion.

## Bottom line

The biggest revenue opportunity in this chain isn't the top 10 stores - it's the 480+ stores sitting below 90% of average. Promotional spend isn't currently allocated where it has the most marginal impact, and the 2014–2015 decline that raw totals imply doesn't exist once trading days are accounted for.
