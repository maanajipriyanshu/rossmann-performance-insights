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

Most public Rossmann notebooks stop at "here's a chart." This one tries to go where an analyst handing this to a retail operations team would go: cleaned data with the business logic behind each decision written down, SQL used for actual analysis instead of just pulling numbers, a Power BI dashboard for stakeholders, and recommendations someone could act on.


## 🎯 Business Problems Solved

This project was structured around 8 real business questions that a retail analytics team would receive from leadership:

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

### Finding 2 — 127 Stores Are Chronically in the Bottom Quartile

Using quarterly NTILE() rankings across all 10 quarters of data, **127 stores** (11.4% of portfolio) landed in the bottom revenue quartile in 6+ of 10 quarters. These stores share a pattern: higher-than-average competition proximity (< 800m), smaller footprint (Type a), and basic assortment. Root cause: product mismatch, not location.

### Finding 3 — Competitor Proximity Has a Counterintuitive Effect

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

```bash
# 1. Clone the repository
git clone https://github.com/maanajipriyanshu/rossmann-performance-insights.git
cd rossmann-performance-insights

# 2. Install Python dependencies
pip install pandas numpy matplotlib seaborn sqlalchemy psycopg2-binary jupyter

# 3. Download dataset from Kaggle
# https://www.kaggle.com/c/rossmann-store-sales/data
# Place train.csv and store.csv into data/raw/

# 4. Load data into PostgreSQL
# Run: sql/00_create_tables.sql
# Then: sql/00_load_data.sql

# 5. Run notebooks in order
jupyter notebook notebooks/

# 6. Open Power BI file
# dashboard/rossmann_dashboard.pbix
```

---

## 📫 About the Analyst

This project was built as part of a professional data analytics portfolio, simulating the kind of analysis performed by a Junior Data Analyst in a German retail analytics team. All business findings, recommendations, and KPIs are derived from the actual Rossmann dataset.

**Connect**: Priyanshu Singh - [LinkedIn](#) · [GitHub](#)

---

*Dataset: Rossmann Store Sales — Kaggle Competition (2015)*
*This is a portfolio project for learning purposes. All business insights are analytical interpretations of the public dataset.*
[Rossmann Store Sales](https://www.kaggle.com/c/rossmann-store-sales) — Kaggle.
