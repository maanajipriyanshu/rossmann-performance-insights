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

## Key Findings

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

---

## Project Structure

```
rossmann-performance-insights/
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

## Dashboard

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
# Place train.csv and store.csv in the project root

# 4. Run notebooks in order
jupyter notebook notebooks/

# 5. Load cleaned data into PostgreSQL and run SQL queries
# Table names: rossmann_sales, rossmann_store

# 6. Open Power BI dashboard
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

*Connect: [LinkedIn](https://linkedin.com/in/maanajipriyanshu) · [GitHub](https://github.com/maanajipriyanshu)*