# Rossmann Performance Insights

Sales analysis of 1,115 Rossmann drug stores in Germany: 2.5 years of daily data, about 1.02M records. Started with four questions — which stores perform best, whether promotions actually work, what seasonal patterns exist, how store format affects revenue — and went further from there into store-level performance segmentation and promo ROI by store type.

## Why this project

Most public Rossmann notebooks stop at "here's a chart." This one tries to go where an analyst handing this to a retail operations team would go: cleaned data with the business logic behind each decision written down, SQL used for actual analysis instead of just pulling numbers, a Power BI dashboard for stakeholders, and recommendations someone could act on.

## Key Findings

- Promotions lift average daily sales by 38.8% (€8,228.74 vs €5,929.83 on non-promo days, across 844,338 trading days).
- Store 817 is the top performer at €21,757 average daily sales, over 3x the chain-wide average of €6,956. All ten of the top stores clear €16,500.
- Store Type B outperforms every other format at €10,233 average daily sales, 48% above the next-best type. Worth a caveat though: there are only 17 Type B stores in the dataset, so this is more of a strong lead than a settled conclusion.
- December sales spike 49% above the January low (€8,609 vs €6,564). November already starts climbing ahead of it, so holiday seasonality shows up clearly.
- Promotional lift isn't even across formats. In Q4, Store Type A gets the biggest lift from promos (+38.3%), while Type B, already the strongest performer, gets the smallest (+19.4%). Promo budget pointed at Type B in Q4 is probably not the best use of that spend.
- Splitting all 1,115 stores into four performance tiers against the €6,956 chain average tells a different story than the top-10 leaderboard: 7.0% are Elite (≥150% of average), 22.4% High Performer, 26.9% On Track, and 43.7% Underperformer. Almost half the chain sits below average.
- Sunday's sales average looks like a "peak day" at €8,225, nearly matching Monday. But only 33 of 1,115 stores open on Sundays, against the full chain every other day. Once that's accounted for, Monday is the actual strongest full-chain trading day, and Sunday isn't a comparable measurement at all.

Full write-up with business recommendations: [`reports/executive_summary.md`](reports/executive_summary.md)

## Project Structure

```
rossmann-performance-insights/
├── data/
│   ├── raw/                  # train.csv, store.csv (Kaggle source)
│   └── clean/                # train_clean.csv, store_clean.csv, merged_cleaned.csv
├── notebooks/
│   ├── 01_data_cleaning.ipynb
│   ├── 02_eda.ipynb
│   └── 03_postgresql.ipynb
├── charts/                   # exported PNGs from EDA
├── dashboard/                 # Power BI .pbix
├── reports/
│   └── executive_summary.md
└── README.md
```

## What Each Notebook Does

**01_data_cleaning.ipynb** — Loads the raw 1,017,209-row train.csv and store.csv. Drops 172,817 rows where the store was closed (Open = 0) and 54 rows where the store was open but recorded zero sales, since both are noise for sales analysis, not real signal. Fills missing competition data with the median (the mean was skewed by a 75,860m outlier against a 2,325m median) and treats missing Promo2 fields as a structural zero, since those stores never ran a second promotion in the first place — so the missing value isn't really missing, it's a "no." Extracts year, month, week, and day from the date field, merges sales with store metadata, and loads both into PostgreSQL.

**02_eda.ipynb** — Six business questions answered with charts: top 10 stores, promo impact, monthly seasonality, sales by store type, competition distance vs. sales, and sales by day of week. Each section opens with the business question before the chart, so it's clear what's being investigated and why.

**03_postgresql.ipynb** — The deeper analysis layer, run directly against PostgreSQL with SQLAlchemy. Twelve queries covering CTEs, RANK() and LAG() window functions, a JOIN-based revenue comparison by store type, and two versions of year-over-year growth. The first uses raw totals, which makes 2015 look like a collapse since it's only a partial year through July. The corrected version uses average daily sales instead, which shows 2015 actually grew 9.7% over 2014. The store performance tier classification (Elite / High Performer / On Track / Underperformer) and the Q4 promotional lift by store type are both built here too.

## Dashboard

Power BI dashboard built on the cleaned, merged dataset: total sales, average daily sales, monthly trend, revenue by store class, top 10 stores, and promotion impact, all on one page for at-a-glance review. (See `dashboard/` for the .pbix file.)

## Tools

Python (Pandas), PostgreSQL, SQLAlchemy, Power BI, Matplotlib/Seaborn.

## Data Source

[Rossmann Store Sales](https://www.kaggle.com/c/rossmann-store-sales) — Kaggle.

## Author

Priyanshu Singh — [LinkedIn] · [Portfolio]