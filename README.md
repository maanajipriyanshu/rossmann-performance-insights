# Rossmann Retail Group: Store Performance Analytics

*Junior Data Analyst Portfolio Project*

Turning 844K sales records into something a retail analytics team could actually act on, across 1,115 Rossmann stores in Germany.

---

## Project Brief

Sales analysis of 1,115 Rossmann drug stores in Germany: 2.5 years of daily data, about 1.02M records. It started with four questions, which stores perform best, whether promotions actually work, what seasonal patterns exist, how store format affects revenue, and grew from there into store-level segmentation and promo ROI by store type.

| | |
|---|---|
| Business Context | Rossmann is Germany's second-largest drug store chain. This analysis looks for revenue leakage, investment opportunities, and competitive threats across the store portfolio. |
| Analyst Role | Junior Data Analyst, Retail Analytics Team |
| Stakeholders | Regional Directors, Category Management, CFO Office |
| Data Period | January 2013 to July 2015 |
| Stores Analyzed | 1,115 |
| Records Processed | 844,338 |
| Tools | PostgreSQL 15, Python 3.11, Power BI, DAX |

---

## Why This Project

Most public Rossmann notebooks stop at "here's a chart." This one goes further: cleaned data with the reasoning behind each decision written down, SQL used for real analysis instead of just pulling numbers, a Power BI dashboard built for stakeholders, and recommendations someone could actually act on.

---

## Business Problems Solved

| # | Business Question | Approach |
|---|---|---|
| 1 | Which stores are consistently underperforming? | Multi-period NTILE ranking, intervention scoring |
| 2 | Which stores are growing fastest? | LAG()-based month-over-month growth, consistency scoring |
| 3 | How much do promotions actually increase revenue? | Incremental lift analysis by store type and assortment |
| 4 | Which assortment strategy generates the highest sales? | PERCENTILE_CONT, multi-dimension benchmarking |
| 5 | Does competitor proximity hurt performance? | Distance banding, spatial revenue comparison |
| 6 | How do stores behave around competitor openings? | Pre/post cohort analysis via date arithmetic |
| 7 | Which stores show abnormal sales behavior? | Z-score anomaly detection with risk flagging |
| 8 | Which stores should be prioritized for capital investment? | Composite weighted expansion scoring model |

---

## Analyst Notes

Scope: 1,115 stores, 844,338 trading days, 2013 to 2015 (2015 partial, through July). Method: PostgreSQL analysis on cleaned sales and store metadata, cross-checked against Python EDA and a Power BI dashboard.

**Headline numbers**
- Chain-wide average daily sales: €6,956
- Total sales across the period: €5.87B
- Promotions lift average sales by 38.8%
- Just over half the chain (56.5%) sits below the chain average

**1. Promotions work, but not evenly across store types**

Chain-wide, promo days average €8,228 against €5,929 on non-promo days. A clear effect, but not a uniform one. Break out Q4 (October to December) by store type and Type a gets a 38.3% lift from promotions, while Type b, already the strongest performer, gets only 19.4%. Type b stores are likely close to capacity during the holiday season, so the marginal return on promo spend there is roughly half what it is for Type a.

Worth acting on: shift more of the Q4 promotional budget toward Type a and Type d stores (32.9% lift), and treat Type b promo spend in Q4 as lower priority. Not zero, just lower. The budget works harder where the lift is bigger.

**2. Store performance is concentrated, and the long tail is large**

Store 817 alone does €21,757 a day, more than 3x the chain average, and the top 10 stores all clear €16,500. The more important number is the tier breakdown though: only 7% of stores qualify as elite (above 150% of average), while 56.5% sit below 90% of average. That's over 630 stores.

Celebrating the top 10 undersells where the real opportunity is. A 5-percentage-point improvement in the underperformer tier, moving stores from below 90% into the 90 to 110% band, would likely move more total revenue than squeezing more out of the already-strong top 10, just because of how many stores are involved. Worth following up: are the underperformer stores clustered by region, competition distance, or store type, or is it spread evenly?

**3. Store Type b looks like the format to expand, with one caveat**

Type b averages €10,233 a day, 48% above the next-best type (c, at €6,933). On its face that argues for opening more Type b stores. The caveat: there are only 17 Type b stores in the dataset, against 602+ Type a stores. A 48% lift on a sample of 17 is a real signal, not a statistically settled one. Type b also has the smallest incremental promo response in Q4, meaning each new Type b store may already need less promotional support to perform.

Before committing capital to expanding the Type b format, it's worth checking whether the strong baseline is location-driven (urban placement, foot traffic) rather than format-driven.

**4. Seasonality is real and worth planning inventory around**

December sales run 49% above the January low (€8,609 vs €6,564), with November already climbing ahead of it. Not a surprising result for retail, but a good sanity check that the data behaves as expected. It's also a reminder to look at December on its own rather than folding it into Q4 generally, since it pulls the average upward for any store open through the season.

Treat November to December as its own planning window instead of lumping it into Q4. The December spike is sharp enough that blending it with October and November understates how concentrated the effect really is.

**5. The 2014 to 2015 decline is a data artifact, not a real trend**

Raw totals make 2015 look like a sharp drop (€1.39B vs €2.18B in 2014). That's misleading: 2015 in this dataset only runs through July, so it's being compared against full years. Correct for trading days and average daily sales actually grew 9.7% in 2015, against a 5.3% decline the year before.

Any year-over-year comparison on this dataset needs to use a daily-average or trading-day-adjusted metric, not raw totals. Easy trap to fall into. A raw-totals read here would have landed on the wrong conclusion.

**6. Sunday's peak-day status is a sample-size illusion**

Only 33 of 1,115 stores open on Sundays, against the full chain on every other day. Those 33 stores average €8,224, nearly matching Monday's full-chain average of €8,216, but it's not a meaningful comparison. It's 3% of the chain, almost certainly a cluster of high-traffic flagship locations, set against 100% of the chain on Monday.

Drop Sunday from any "best day of the week" framing unless the store count is reported alongside it. Monday is the correct answer to "which day performs best chain-wide." Whether those 33 Sunday stores should stay open, and whether more should follow, is a separate question worth its own analysis.

**What still needs validation**

The Type b sample-size caveat (17 stores) means that finding should be treated as a hypothesis to test further, not a settled conclusion.

**Bottom line**

The chain's real growth lever isn't the top 10 stores. It's the 630+ stores sitting below 90% of average. Promotional spend isn't currently allocated where it has the most marginal impact, and the 2014 to 2015 decline that raw totals suggest doesn't actually exist once trading days are accounted for correctly.

---

## Project Structure

```
rossmann-performance-insights/
│
├── sql/
│   └── rossmann_advanced_analysis.sql      # 15 advanced business queries
│
├── notebooks/
│   ├── 01_data_cleaning.ipynb              # Data quality audit and cleaning
│   ├── 02_eda.ipynb                        # Exploratory analysis with business context
│   └── 03_postgresql.ipynb                 # SQL queries run from Python, plus findings
│
├── Dashboard/
│   └── rossmann_sales_analysis.pbix        # Power BI 4-page dashboard
│
├── Charts/
│   ├── Executive Summary.png
│   ├── Store Performance.png
│   ├── Promo & Competition.png
│   └── Growth Opportunities & Recommendations.png
│
└── README.md
```

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

## Power BI Dashboard: 4-Page Design

**Page 1, Executive Summary**
5 KPI cards (Total Revenue, Avg Daily Sales, Avg Basket Size, Promo Day %, Total Customers), revenue trend line 2013 to 2015, revenue by store type bar chart, promo impact column chart, Year and Store Type slicers.

**Page 2, Store Performance Analysis**
Top 10 stores by average daily sales, bottom 10 stores by average daily sales, year-over-year growth by store type, 3 KPI cards (Total Revenue, Below Avg Stores, YoY Growth %).

**Page 3, Promotion and Competition Impact**
Promo lift % by store type, promo lift % by assortment, competition distance vs. store revenue scatter chart, average daily sales by competition zone, monthly promo vs. non-promo combo chart, 3 KPI cards.

**Page 4, Growth Opportunities and Recommendations**
Top 20 expansion candidate stores, average basket size by store type, average daily sales by assortment, top 15 stores by promo responsiveness, key recommendations.

---

## DAX Measures

Built on two tables: `train_clean` (sales records) and `store_clean` (store metadata).

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

## KPI Dictionary

| KPI | Formula | Business Use |
|---|---|---|
| Avg Daily Sales | SUM(sales) / COUNT(open days) | Store-level performance baseline |
| Promo Lift % | (Promo avg - Non-promo avg) / Non-promo avg × 100 | Promo ROI by segment |
| Avg Basket Size | Total sales / Total customers | Revenue quality indicator |
| YoY Growth % | (2014 avg - 2013 avg) / 2013 avg × 100 | Year-over-year performance |
| Expansion Score | Weighted rank (30% revenue, 35% growth, 20% promo, 15% basket) | Capital investment prioritization |
| Anomaly Rate % | Days with z-score above 3 / Total open days × 100 | Operational risk flag |
| Bottom Quartile Rate % | Quarters in bottom 25% / Total quarters × 100 | Underperformance severity |

---

## Business Recommendations

**1. Reallocate promo budget toward Type a / Assortment c stores**

These show 42 to 47% promo lift versus 18% for Type b. Increasing promo frequency by 2 days a month across 80 qualifying stores would generate an estimated €2.1M in incremental annual revenue.

**2. Structured intervention for chronic underperformers**

127 stores landed in the bottom quartile in 6 or more of the last 10 quarters. The pattern points to assortment mismatch rather than location. Piloting an assortment upgrade (Basic to Extended) in the bottom 20 stores and reviewing after 2 quarters is the logical next step.

**3. Revise site selection criteria**

Stores within 500m of competition average €7,611 in daily sales, higher than more isolated stores. High-competition zones tend to be high-footfall areas. New sites in dense retail corridors outperform suburban locations.

**4. Align staffing and inventory to the seasonality index**

December runs 30% above the annual average. July runs below it. Decisions based on annual averages consistently miss both the peak and the trough. A monthly index-based staffing model would reduce lost sales in December and cut unnecessary costs in July.

---

## How to Reproduce

```bash
# 1. Clone the repository
git clone https://github.com/maanajipriyanshu/rossmann-performance-insights.git
cd rossmann-performance-insights

# 2. Install Python dependencies
pip install pandas numpy matplotlib seaborn sqlalchemy psycopg2-binary jupyter

# 3. Download the dataset from Kaggle
# https://www.kaggle.com/c/rossmann-store-sales/data
# Place train.csv and store.csv in the project root

# 4. Run the notebooks in order
jupyter notebook notebooks/

# 5. Load the cleaned data into PostgreSQL and run the SQL queries
# Table names: rossmann_sales, rossmann_store

# 6. Open the Power BI dashboard
# Dashboard/rossmann_sales_analysis.pbix
```

---

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

*Connect: [LinkedIn](https://linkedin.com/in/maanapriyanshurajput) · [GitHub](https://github.com/maanajipriyanshu) · [Portfolio](https://maanajipriyanshu.github.io/insights-by-priyanshu/)*