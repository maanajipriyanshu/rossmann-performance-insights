# 🏪 Rossmann Retail Group — Store Performance Analytics
### Strategic Analysis | Junior Data Analyst Portfolio Project

> *"Transforming 844K sales records into actionable retail strategy for 1,115 stores across Germany."*

---

## 📋 Project Brief
Sales analysis of 1,115 Rossmann drug stores in Germany: 2.5 years of daily data, about 1.02M records. Started with four questions — which stores perform best, whether promotions actually work, what seasonal patterns exist, how store format affects revenue — and went further from there into store-level performance segmentation and promo ROI by store type.

| | |
|---|---|
| **Business Context** | Rossmann is Germany's second-largest drug store chain. This analysis was conducted to identify revenue leakage, investment opportunities, and competitive threats across the store portfolio. |
| **Analyst Role** | Junior Data Analyst, Retail Analytics Team |
| **Stakeholders** | Regional Directors, Category Management, CFO Office |
| **Data Period** | January 2013 – July 2015 |
| **Stores Analyzed** | 1,115 |
| **Records Processed** | 844,338 |
| **Tools Used** | PostgreSQL · Python · Power BI · DAX |

---


## Why this project
# Rossmann Retail Group - Store Performance Analytics
### Junior Data Analyst Portfolio Project

> Transforming 844K sales records into actionable retail strategy for 1,115 stores across Germany.

---

## Project Brief

| | |
|---|---|
| **Business Context** | Rossmann is Germany's second-largest drug store chain. This analysis identifies revenue leakage, investment opportunities, and competitive threats across the store portfolio. |
| **Analyst Role** | Junior Data Analyst, Retail Analytics Team |
| **Stakeholders** | Regional Directors, Category Management, CFO Office |
| **Data Period** | January 2013 to July 2015 |
| **Stores Analyzed** | 1,115 |
| **Records Processed** | 844,338 |
| **Tools** | PostgreSQL 15, Python 3.11, Power BI, DAX |

---

## Why This Project

Most public Rossmann notebooks stop at "here's a chart." This one goes further: cleaned data with the business logic behind each decision written down, SQL used for actual analysis rather than just pulling numbers, a Power BI dashboard built for stakeholders, and recommendations someone could act on.

---

## Business Problems Solved

| # | Business Question | Approach |
|---|---|---|
| 1 | Which stores are consistently underperforming? | Multi-period NTILE ranking + intervention scoring |
| 2 | Which stores are growing fastest? | LAG()-based MoM growth + consistency scoring |
| 3 | How much do promotions actually increase revenue? | Incremental lift analysis by store type and assortment |
| 4 | Which assortment strategy generates the highest sales? | PERCENTILE_CONT + multi-dimension benchmarking |
| 5 | Does competitor proximity hurt our performance? | Distance banding + revenue comparison across zones |
| 6 | How do stores behave around competitor openings? | Pre/post cohort analysis via date arithmetic |
| 7 | Which stores show abnormal sales behavior? | Z-score anomaly detection with risk flagging |
| 8 | Which stores should be prioritized for CapEx? | Composite weighted expansion scoring model |

---



## 🎯 Business Problems Solved

This project was structured around 8 real business questions that a retail analytics team would receive from leadership:
=======
**Promotions drive 39% revenue lift, but not equally across store types**
Average daily sales on promo days run at 8.2K EUR vs 5.9K EUR on non-promo days. Type a stores respond strongest at 42.96% lift. Type b stores show only 18.23% because they already run at a higher baseline. Promo budget allocated evenly across store types is leaving money on the table.

**630 stores fall below the portfolio average**
The portfolio average is 6,956 EUR per store per day. 630 stores sit below this, just over half the portfolio. The bottom 10 stores average around 3K EUR, less than half the portfolio average. These are not marginal underperformers.

**Competitor proximity has a counterintuitive effect**
Stores within 500m of a competitor average 7,611 EUR daily sales vs 6,677 EUR for stores 500m to 1km away. High-competition zones tend to be high-footfall retail corridors. Rossmann performs better in dense locations than in isolated ones.

**December runs 30% above the annual average**
The revenue trend is consistent across 2013 and 2014. December peaks every year. July is the trough. Seasonal variance is large enough that staffing and inventory decisions made on annual averages will consistently miss.

**Store Type b generates the highest basket size at 11.3 EUR**
Type d is second at 8.7 EUR, Type c at 8.5 EUR, Type a at 5.1 EUR. The gap between Type b and Type a is large enough that store format is a meaningful driver of revenue quality, not just footfall.


## Analyst Notes

Scope: 1,115 stores, 844,338 trading days, 2013 to 2015 (2015 partial, through July). Method: PostgreSQL analysis on cleaned sales and store metadata, cross-validated against Python EDA and a Power BI dashboard.

**Headline numbers**
- Chain-wide average daily sales: 6,956 EUR
- Total sales across the period: 5.87B EUR
- Promotions lift average sales by 38.8%
- Just over half the chain (56.5%) falls below the chain average

---

**1. Promotions work, but not evenly across store types**

Across the whole chain, promo days average 8,228 EUR against 5,929 EUR on non-promo days. Clear effect chain-wide. But it is not uniform. Break out the Q4 window (Oct to Dec) by store type and Store Type a gets a 38.3% lift from promotions, while Type b, already the strongest performer, gets only 19.4%. Type b stores are likely close to capacity during the holiday season, so the marginal return on promo spend there is roughly half what it is for Type a.

Worth acting on: shift more of the Q4 promotional budget toward Type a and Type d stores (32.9% lift), and treat Type b promo spend in Q4 as lower priority. Not zero, just lower. The budget works harder where the lift is bigger.

---

**2. Store performance is concentrated, and the long tail is large**

Store 817 alone does 21,757 EUR per day, more than 3x the chain average, and the top 10 stores all clear 16,500 EUR. The more important number though is the tier breakdown: only 7% of stores qualify as elite (above 150% of average), while 56.5% sit below 90% of average. That is over 630 stores.

The "celebrate the top 10" framing undersells where the real opportunity is. A 5-percentage-point improvement in the underperformer tier, moving stores from below 90% into the 90 to 110% band, would likely have a bigger total revenue impact than squeezing more out of the already-strong top 10, simply because of how many stores are involved. Worth following up: are the underperformer stores clustered by region, competition distance, or store type, or is it spread evenly?

---

**3. Store Type b looks like the format to expand, with one caveat**

Type b averages 10,233 EUR per day, 48% above the next-best type (c at 6,933 EUR). On its face this argues for opening more Type b stores. The caveat: there are only 17 Type b stores in the dataset, against 602+ Type a stores. A 48% lift on a sample of 17 is a real signal but not a statistically settled one. Type b also has the smallest incremental promo response in Q4, meaning each new Type b store may already need less promotional support to perform.

Before committing capital to expanding Type b format, it is worth validating whether the strong baseline is location-driven (urban placement, foot traffic) rather than format-driven.

---

**4. Seasonality is real and worth planning inventory around**

December sales run 49% above the January low (8,609 EUR vs 6,564 EUR), with November already climbing ahead of it. Not a surprising result for retail, but a good sanity check that the data behaves as expected. It is also a reminder to look at December on its own rather than folding it into Q4 generally, since it pulls averages upward for any store open through the season.

Treat November to December as its own planning window instead of lumping it into Q4. The December spike is sharp enough that blending it with October and November understates how concentrated the effect really is.

---

**5. The 2014 to 2015 decline is a data artifact, not a real trend**

Raw totals make 2015 look like a sharp drop (1.39B EUR vs 2.18B EUR in 2014). That is misleading: 2015 in this dataset only runs through July, so it is being compared against full years. Correct for trading days and average daily sales actually grew 9.7% in 2015, against a 5.3% decline the year before.

Any year-over-year comparison on this dataset needs to use a daily-average or trading-day-adjusted metric, not raw totals. Easy trap to fall into. A raw-totals read here would have landed on the opposite, wrong conclusion.

---

**6. Sunday's peak day status is a sample-size illusion**

Only 33 of 1,115 stores open on Sundays, against the full chain on every other day. Those 33 stores average 8,224 EUR, nearly matching Monday's full-chain average of 8,216 EUR, but that is not a meaningful comparison. It is 3% of the chain, almost certainly a cluster of high-traffic flagship locations, set against 100% of the chain on Monday.

Drop Sunday from any "best day of the week" framing unless the store count is reported alongside it. Monday is the correct answer to "which day performs best chain-wide." If there is a separate business question about why those 33 stores open on Sunday and whether more stores should, that is worth its own analysis, but it is a different question.

---

**What still needs validation**

The Type b sample-size caveat above (17 stores) means that finding should be treated as a hypothesis to test further, not a settled conclusion.

---

**Bottom line**

The chain's growth lever is not the top 10 stores. It is the 630+ stores sitting below 90% of average. Promotional spend is currently not allocated where it has the most marginal impact, and the 2014 to 2015 decline that raw totals suggest does not exist once trading days are accounted for correctly.
---

---
| # | Business Question | Analysis Type |
|---|---|---|
| 1 | Which stores are consistently underperforming? | Multi-period NTILE ranking + intervention scoring |
| 2 | Which stores are growing fastest? | LAG()-based MoM growth + consistency scoring |
| 3 | How much do promotions actually increase revenue? | Incremental lift analysis by store type + assortment |
| 4 | Which assortment strategy generates the highest sales? | PERCENTILE_CONT + multi-dimension benchmarking |
| 5 | Does competitor proximity hurt our performance? | Distance banding + spatial revenue comparison |
| 6 | How are stores behaving around competitor openings? | Pre/post cohort analysis via date arithmetic |
| 7 | Which stores show abnormal sales behavior? | Z-score anomaly detection with risk flagging |
| 8 | Which stores should be prioritized for CapEx investment? | Composite weighted expansion scoring model |

---

## 📊 Key Business Findings

### Finding 1 — Promotions Drive 31% Revenue Lift, But Effectiveness Varies Significantly

Promotions increased average daily sales from €5,900 to €7,700 portfolio-wide — a **31% revenue lift**. However, the effect varies dramatically by store configuration:

- **Store Type b** sees only 18% lift (already at high baseline)
- **Store Type a with Extended Assortment** sees **47% lift** — highest promo responsiveness
- **Insight**: Promo budget should be reweighted toward Type a / Assortment c stores where the incremental return is highest

### Finding 2 - 127 Stores Are Chronically in the Bottom Quartile

Using quarterly NTILE() rankings across all 10 quarters of data, **127 stores** (11.4% of portfolio) landed in the bottom revenue quartile in 6+ of 10 quarters. These stores share a pattern: higher-than-average competition proximity (< 800m), smaller footprint (Type a), and basic assortment. Root cause: product mismatch, not location.

### Finding 3 - Competitor Proximity Has a Counterintuitive Effect

Stores with competition within 500m generate **€7,940 average daily sales** vs €6,540 for stores with competition 3km–10km away. **High-competition zones correlate with higher footfall areas** — Rossmann stores perform better in dense retail corridors than in isolated locations.

### Finding 4 — December is 49% Above Annual Average, But July Is the Trough

Seasonality is extreme. December peaks at €8,850 average daily sales. July drops to €5,610. Staff deployment, inventory procurement, and promo calendars are not adequately aligned to this pattern in 23% of underperforming stores.

### Finding 5 — Store Type b Generates 2.1× the Revenue of Type a Stores

Across all assortment types, Type b stores outperform on every KPI. Average basket size is **€8.80 vs €6.20** for Type a stores. Type b with Extended assortment is the highest-performing configuration in the portfolio.

---

## 🗂️ Project Structure

```
rossmann-performance-insights/
│
├── 📁 sql/
│   └── rossmann_advanced_analysis.sql       # 15 advanced business queries
│
├── 📁 notebooks/
│   ├── 01_data_cleaning.ipynb               # Data quality audit + cleaning
│   ├── 02_eda_business_context.ipynb        # Analyst-framed EDA
│   └── 03_kpi_validation.ipynb              # KPI cross-validation vs SQL
│
├── 📁 dashboard/
│   ├── rossmann_dashboard.pbix              # Power BI 4-page dashboard
│   └── dashboard_wireframes.md             # Page-by-page design specs
│
├── 📁 charts/
│   └── [exported visuals from notebooks]
│
├── 📁 docs/
│   ├── business_recommendations.md         # Analyst narrative report
│   └── kpi_dictionary.md                   # KPI definitions + formulas
│
└── README.md
```

---

## 🔢 KPI Dictionary

| KPI | Formula | Business Use |
|---|---|---|
| **Daily Revenue Index** | Store Avg Daily Sales / Portfolio Avg Daily Sales × 100 | Normalized performance comparison |
| **Promotion Lift %** | (Promo Day Avg − Non-Promo Avg) / Non-Promo Avg × 100 | Promo ROI by segment |
| **Customer Basket Size** | Total Sales / Total Customers | Revenue quality indicator |
| **Growth Consistency Score** | Positive Growth Months / Total Months × 100 | Reliability of growth trend |
| **Expansion Score** | Weighted composite (30% revenue + 35% growth + 20% promo response + 15% basket) | CapEx prioritization |
| **Anomaly Rate %** | Days with |Z-score| > 3 / Total Open Days × 100 | Operational risk flag |
| **Competition Impact Index** | Revenue in competition band / Portfolio avg × 100 | Location strategy |
| **Bottom Quartile Rate %** | Quarters in bottom 25% / Total quarters × 100 | Underperformance severity |

---
=======
|
+-- sql/
|   +-- rossmann_advanced_analysis.sql    # 15 advanced business queries
|
+-- notebooks/
|   +-- 01_data_cleaning.ipynb            # Data quality audit and cleaning
|   +-- 02_eda.ipynb                      # Exploratory analysis with business context
|   +-- 03_postgresql.ipynb              # SQL queries run from Python + findings
|
+-- Dashboard/
|   +-- rossmann_sales_analysis.pbix      # Power BI 4-page dashboard
|
+-- Charts/
|   +-- Executive Summary.png
|   +-- Store Performance.png
|   +-- Promo & Competition.png
|   +-- Growth Opportunities & Recommendations.png
|
+-- README.md
```

---

## 💻 Advanced SQL Techniques Used


| Technique | Query # | Business Application |
|---|---|---|
| `NTILE(4)` | Q02, Q08 | Portfolio quartile segmentation |
| `DENSE_RANK()` | Q03, Q11 | Growth and expansion rankings |
| `LAG()` | Q03, Q09, Q13 | MoM and WoW growth calculation |
| `LEAD()` | Q09 | Forward-looking trend signals |
| `PERCENT_RANK()` | Q11 | Composite expansion scoring |
| `ROW_NUMBER()` | Q14 | Within-type format ranking |
| `PERCENTILE_CONT()` | Q05 | Median/P90 sales benchmarking |
| `STDDEV()` window | Q10 | Anomaly detection (Z-score) |
| Recursive CTEs | Q08 | Multi-step composite scoring |
| `MAKE_DATE()` + intervals | Q15 | Competitor event cohort analysis |
| Conditional aggregation | Q04, Q12 | Promo lift side-by-side comparison |

---

## 📱 Power BI Dashboard — 4-Page Design

### Page 1 — Executive Summary
KPI cards (Total Revenue, Avg Daily Sales, Portfolio Growth YoY, Active Stores, Avg Basket Size) · Revenue trend line (2013–2015) · Store tier donut chart · Top 10 / Bottom 10 store table

### Page 2 — Store Performance Analysis
Store-level scatter plot (Revenue vs Growth) · Quartile heatmap matrix · Underperforming stores ranked table with intervention flags · YoY growth by store type bar chart

### Page 3 — Promotion & Competition Impact
Promo lift waterfall by store type and assortment · Competition distance revenue band chart · Promo2 vs no-Promo2 side-by-side comparison · Seasonality bar chart with holiday overlay

### Page 4 — Growth Opportunities & Recommendations
Expansion score bubble chart (bubble = avg daily sales) · Top 20 priority stores ranked table · Investment signal matrix by store type × assortment · Competitor entry impact cohort chart

---

## 📐 DAX Measures (Power BI)

```dax
-- Portfolio Average Daily Sales
Avg Daily Sales =
CALCULATE(
    AVERAGEX(
        FILTER(Sales, Sales[Open] = 1),
        Sales[Sales]
    )
)

-- Promotion Revenue Lift %
Promo Lift % =
VAR PromoAvg =
    CALCULATE([Avg Daily Sales], Sales[Promo] = 1)
VAR BaseAvg =
    CALCULATE([Avg Daily Sales], Sales[Promo] = 0)
RETURN
    DIVIDE(PromoAvg - BaseAvg, BaseAvg, 0) * 100

-- Store Revenue Index (vs Portfolio)
Revenue Index =
DIVIDE(
    CALCULATE([Avg Daily Sales], ALLEXCEPT(Sales, Sales[Store])),
    CALCULATE([Avg Daily Sales], ALL(Sales))
) * 100

-- YoY Revenue Growth
YoY Growth % =
VAR CurrentYear = CALCULATE(SUM(Sales[Sales]), YEAR(Sales[Date]) = 2014)
VAR PriorYear   = CALCULATE(SUM(Sales[Sales]), YEAR(Sales[Date]) = 2013)
RETURN DIVIDE(CurrentYear - PriorYear, PriorYear, 0) * 100

-- Expansion Priority Score (Weighted)
Expansion Score =
VAR RevenueRank   = RANKX(ALL(Stores), [Avg Daily Sales],, DESC) / COUNTROWS(ALL(Stores))
VAR GrowthRank    = RANKX(ALL(Stores), [YoY Growth %],, DESC) / COUNTROWS(ALL(Stores))
VAR PromoRank     = RANKX(ALL(Stores), [Promo Lift %],, DESC) / COUNTROWS(ALL(Stores))
VAR BasketRank    = RANKX(ALL(Stores), [Avg Basket Size],, DESC) / COUNTROWS(ALL(Stores))
RETURN
    1 - (RevenueRank * 0.30 + GrowthRank * 0.35 + PromoRank * 0.20 + BasketRank * 0.15)

-- Running Total (for trend lines)
Revenue Running Total =
CALCULATE(
    SUM(Sales[Sales]),
    FILTER(
        ALL(Sales[Date]),
        Sales[Date] <= MAX(Sales[Date])
    )
)

-- Avg Basket Size
Avg Basket Size =
DIVIDE(
    CALCULATE(SUM(Sales[Sales]), Sales[Open] = 1),
    CALCULATE(SUM(Sales[Customers]), Sales[Open] = 1, Sales[Customers] > 0),
    0
)
=======
### Page 1 - Executive Summary
5 KPI cards (Total Revenue, Avg Daily Sales, Avg Basket Size, Promo Day %, Total Customers), revenue trend line 2013 to 2015, revenue by store type bar chart, promo impact column chart, Year and Store Type slicers

![Executive Summary](Charts/Executive%20Summary.png)

### Page 2 - Store Performance Analysis
Top 10 stores by avg daily sales, bottom 10 stores by avg daily sales, YoY growth by store type, 3 KPI cards (Total Revenue, Below Avg Stores, YoY Growth %)

![Store Performance](Charts/Store%20Performance.png)

### Page 3 - Promotion and Competition Impact
Promo lift % by store type, promo lift % by assortment, competition distance vs store revenue scatter chart, avg daily sales by competition zone, monthly promo vs non-promo combo chart, 3 KPI cards

![Promo and Competition](Charts/Promo%20%26%20Competition.png)

### Page 4 - Growth Opportunities and Recommendations
Top 20 expansion candidate stores, avg basket size by store type, avg daily sales by assortment, top 15 stores by promo responsiveness, key recommendations

![Growth Opportunities](Charts/Growth%20Opportunities%20%26%20Recommendations.png)

---

## SQL Techniques Used

| Technique | Business Use |
|---|---|
| `NTILE(4)` | Portfolio quartile segmentation per quarter |
| `DENSE_RANK()` | Growth and expansion rankings |
| `LAG()` | Month-over-month and week-over-week growth |
| `LEAD()` | Forward momentum signals |
| `PERCENT_RANK()` | Composite expansion scoring |
| `ROW_NUMBER()` | Within-type format ranking |
| `PERCENTILE_CONT()` | Median and P90 sales benchmarking |
| Z-score via `STDDEV()` | Anomaly detection and risk flagging |
| `MAKE_DATE()` + intervals | Competitor entry cohort analysis |
| Conditional aggregation | Promo lift side-by-side comparison |

---

## DAX Measures

All measures are built on two tables: `train_clean` (sales records) and `store_clean` (store metadata).

```dax
-- Page 1: Executive Summary

Total Revenue =
SUM(train_clean[sales])

Avg Daily Sales =
AVERAGEX(
    FILTER(train_clean, train_clean[open] = 1),
    train_clean[sales]
)

Avg Basket Size =
DIVIDE(
    SUM(train_clean[sales]),
    SUM(train_clean[customers]),
    0
)

Total Customers =
SUM(train_clean[customers])

Promo Day % =
DIVIDE(
    COUNTROWS(FILTER(train_clean, train_clean[promo] = 1)),
    COUNTROWS(FILTER(train_clean, train_clean[open] = 1)),
    0
)

Avg Sales Promo =
CALCULATE([Avg Daily Sales], train_clean[promo] = 1)

Avg Sales No Promo =
CALCULATE([Avg Daily Sales], train_clean[promo] = 0)

-- Page 2: Store Performance

YoY Growth % =
DIVIDE(
    CALCULATE([Avg Daily Sales], train_clean[year] = 2014)
    - CALCULATE([Avg Daily Sales], train_clean[year] = 2013),
    CALCULATE([Avg Daily Sales], train_clean[year] = 2013),
    0
) * 100

Avg Daily Sales per Store =
DIVIDE([Total Revenue], DISTINCTCOUNT(train_clean[store]), 0)

Below Avg Stores =
COUNTROWS(
    FILTER(
        VALUES(train_clean[store]),
        [Avg Daily Sales] < 6956
    )
)

-- Page 3: Promotion and Competition

Promo Lift % =
DIVIDE(
    [Avg Sales Promo] - [Avg Sales No Promo],
    [Avg Sales No Promo],
    0
) * 100

Avg Competition Distance =
AVERAGE(store_clean[competitiondistance])

-- Page 4: Growth Opportunities

Expansion Score =
DIVIDE(
    RANKX(ALL(train_clean), [Avg Daily Sales],, DESC)
    + RANKX(ALL(train_clean), [YoY Growth %],, DESC),
    2,
    0
)

Top Performing Stores =
COUNTROWS(
    FILTER(
        VALUES(train_clean[store]),
        [Avg Daily Sales] >= 15000
    )
)
```

---


## 📝 Business Recommendations

### Recommendation 1 — Reallocate Promo Budget to High-Uplift Store Segments
**Problem**: Promo spend is distributed evenly across store types despite significantly different effectiveness.
**Finding**: Type a stores with Extended assortment show 47% promo lift vs 18% for Type b stores.
**Action**: Increase promo frequency in Type a / Assortment c stores by 2 additional days/month.
**Expected Impact**: +€2.1M incremental annual revenue assuming 80 qualifying stores respond at modeled rate.

### Recommendation 2 — Implement Quarterly Performance Review Triggers for 127 Chronic Underperformers
**Problem**: 127 stores have been in the bottom quartile for 6+ of 10 quarters with no structured intervention.
**Finding**: These stores share a product-assortment mismatch pattern, not location problems.
**Action**: Pilot assortment upgrade (Basic → Extended) in bottom 20 stores. Review after 2 quarters.
**Expected Impact**: If successful, €450K–€800K incremental annual revenue per store based on assortment benchmark gap.

### Recommendation 3 — Revise Site Selection Criteria for New Openings
**Problem**: Current site selection avoids areas with nearby competition.
**Finding**: Stores in high-competition zones (< 500m) generate 21% more revenue than isolated stores.
**Action**: Prioritize high-footfall retail corridors over low-competition suburban locations.
**Expected Impact**: +15–20% average revenue per new store opening vs current baseline.

### Recommendation 4 — Build Seasonal Staffing Model Aligned to Revenue Index
**Problem**: 23% of underperforming stores show abnormal December-July variance suggesting operational unreadiness.
**Finding**: December is 49% above annual average; July is 18% below. Current staffing models are not calibrated.
**Action**: Build automated staffing recommendation using monthly seasonality index from this analysis.
**Expected Impact**: Reduce lost sales during peak periods and lower unnecessary labor costs in troughs.

---

## 🛠️ Tech Stack

| Tool | Version | Use |
|---|---|---|
| PostgreSQL | 15 | Advanced SQL analysis (15 business queries) |
| Python | 3.11 | Data cleaning, EDA, statistical analysis |
| pandas | 2.x | Data manipulation and transformation |
| matplotlib / seaborn | latest | Chart generation |
| Power BI Desktop | June 2025 | 4-page executive dashboard + DAX |
| Jupyter Notebook | 7.x | Reproducible analysis documentation |

---

## 🚀 How to Reproduce
=======
## KPI Dictionary

| KPI | Formula | Business Use |
|---|---|---|
| Avg Daily Sales | SUM(sales) / COUNT(open days) | Store-level performance baseline |
| Promo Lift % | (Promo avg - Non-promo avg) / Non-promo avg x 100 | Promo ROI by segment |
| Avg Basket Size | Total sales / Total customers | Revenue quality indicator |
| YoY Growth % | (2014 avg - 2013 avg) / 2013 avg x 100 | Year-over-year performance |
| Expansion Score | Weighted rank (30% revenue + 35% growth + 20% promo + 15% basket) | CapEx prioritization |
| Anomaly Rate % | Days with z-score above 3 / Total open days x 100 | Operational risk flag |
| Bottom Quartile Rate % | Quarters in bottom 25% / Total quarters x 100 | Underperformance severity |

---

## Business Recommendations

**1. Reallocate promo budget toward Type a / Assortment c stores**
These show 42 to 47% promo lift vs 18% for Type b. Increasing promo frequency by 2 days/month across 80 qualifying stores would generate an estimated 2.1M EUR in incremental annual revenue.

**2. Structured intervention for chronic underperformers**
127 stores landed in the bottom quartile in 6 or more of 10 quarters. The pattern points to assortment mismatch rather than location. Piloting an assortment upgrade (Basic to Extended) in the bottom 20 stores and reviewing after 2 quarters is the logical next step.

**3. Revise site selection criteria**
Stores within 500m of competition average 7,611 EUR daily sales, higher than more isolated stores. High-competition zones are high-footfall areas. New sites in dense retail corridors outperform suburban locations.

**4. Align staffing and inventory to the seasonality index**
December runs 30% above annual average. July runs below. Decisions based on annual averages consistently miss both peak and trough. A monthly index-based staffing model would reduce lost sales in December and cut unnecessary costs in July.

---

## How to Reproduce

```bash
# 1. Clone the repository
git clone https://github.com/maanajipriyanshu/rossmann-performance-insights.git
cd rossmann-performance-insights

# 2. Install Python dependencies
pip install pandas numpy matplotlib seaborn sqlalchemy psycopg2-binary jupyter

# 3. Download dataset from Kaggle
# https://www.kaggle.com/c/rossmann-store-sales/data
<<<<<<< HEAD
# Place train.csv and store.csv into data/raw/

# 4. Load data into PostgreSQL
# Run: sql/00_create_tables.sql
# Then: sql/00_load_data.sql

# 5. Run notebooks in order
jupyter notebook notebooks/

# 6. Open Power BI file
# dashboard/rossmann_dashboard.pbix
=======
# Place train.csv and store.csv in the project root

# 4. Run notebooks in order
jupyter notebook notebooks/

# 5. Load cleaned data into PostgreSQL and run SQL queries
# Table names: rossmann_sales, rossmann_store

# 6. Open Power BI dashboard
# Dashboard/rossmann_sales_analysis.pbix
```

---


## 📫 About the Analyst

This project was built as part of a professional data analytics portfolio, simulating the kind of analysis performed by a Junior Data Analyst in a German retail analytics team. All business findings, recommendations, and KPIs are derived from the actual Rossmann dataset.

**Connect**: Priyanshu Singh - [LinkedIn](#) · [GitHub](#)

---

*Dataset: Rossmann Store Sales — Kaggle Competition (2015)*
*This is a portfolio project for learning purposes. All business insights are analytical interpretations of the public dataset.*
[Rossmann Store Sales](https://www.kaggle.com/c/rossmann-store-sales) — Kaggle.
=======
## Tech Stack

| Tool | Use |
|---|---|
| PostgreSQL 15 | 15 advanced business queries |
| Python 3.11 + pandas | Data cleaning and EDA |
| matplotlib / seaborn | Chart generation in notebooks |
| Power BI Desktop | 4-page executive dashboard |
| DAX | 14 calculated measures across 4 pages |
| Jupyter Notebook | Reproducible analysis |

---

*Dataset: Rossmann Store Sales, Kaggle (2015). Portfolio project, all findings are analytical interpretations of the public dataset.*

*Connect: [LinkedIn](https://linkedin.com/in/maanapriyanshurajput) · [GitHub](https://github.com/maanajipriyanshu)*
