# Rossmann Performance Insights

Sales analysis of 1,115 Rossmann drug stores in Germany: 2.5 years of daily data, roughly 1.02M records. Started with four questions - which stores perform best, whether promotions actually work, what seasonal patterns look like, how store format affects revenue - and kept going from there into store-level segmentation and promo ROI by store type.

## Why this project

Most public Rossmann analyses stop at charts. This one goes further: cleaned data with the business logic behind each decision written down, SQL used for real analysis rather than just pulling numbers, a Power BI dashboard, and recommendations someone could actually act on.

## Key Findings

- Promotions lift average daily sales by 38.8% (€8,228.74 vs €5,929.83 on non-promo days, across 844,338 trading days).
- Store 817 is the top performer at €21,757 average daily sales - over 3x the chain-wide average of €6,956. All ten top stores clear €16,500.
- Store Type B leads every other format at €10,233 average daily sales, 48% above the next-best type. Caveat: only 17 Type B stores are in the dataset, so treat this as a strong lead, not a settled finding.
- December sales run 49% above the January low (€8,609 vs €6,564). November already starts climbing ahead of it - holiday seasonality shows up clearly in the data.
- Promo lift isn't even across formats. In Q4, Store Type A gets the biggest lift (+38.3%), while Type B - already the strongest performer - gets the smallest (+19.4%). Promo budget pointed at Type B in Q4 is probably not the best use of that spend.
- Splitting all 1,115 stores into four tiers against the €6,956 chain average: 7.0% Elite (≥150% of average), 22.4% High Performer, 26.9% On Track, 43.7% Underperformer. Nearly half the chain sits below average.
- Sunday's sales average looks like a peak day at €8,225, nearly matching Monday. But only 33 of 1,115 stores open on Sundays, against the full chain every other day. Once that's accounted for, Monday is the actual strongest full-chain trading day - Sunday isn't a comparable number at all.

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
├── dashboard/                # Power BI .pbix
├── reports/
│   └── executive_summary.md
└── README.md
```

## What Each Notebook Does

**01_data_cleaning.ipynb** - Loads the raw 1,017,209-row train.csv and store.csv. Drops 172,817 closed-store rows (Open = 0) and 54 rows where the store was open but recorded zero sales - both are noise, not signal. Fills missing competition data with the median rather than the mean (a 75,860m outlier was skewing the mean well above the 2,325m median). Treats missing Promo2 fields as structural zeros: those stores never ran a second promotion, so the missing value is a "no," not a gap. Extracts year, month, week, and day from the date field, merges sales with store metadata, and loads both into PostgreSQL.

**02_eda.ipynb** - Six business questions answered with charts: top 10 stores, promo impact, monthly seasonality, sales by store type, competition distance vs. sales, day-of-week patterns. Each section opens with the question before the chart.

**03_postgresql.ipynb** - Deeper analysis run directly against PostgreSQL via SQLAlchemy. Twelve queries using CTEs, RANK() and LAG() window functions, and JOIN-based revenue comparisons by store type. Includes two versions of year-over-year growth: one using raw totals, which makes 2015 look like a collapse because it only runs through July, and a corrected version using average daily sales, which shows 2015 actually grew 9.7% over 2014. Store tier classification and Q4 promotional lift by store type are both built here.

## Dashboard

Power BI dashboard built on the cleaned, merged dataset: total sales, average daily sales, monthly trend, revenue by store class, top 10 stores, and promo impact - one page, at a glance. (.pbix file in `dashboard/`.)

## Tools

Python (Pandas), PostgreSQL, SQLAlchemy, Power BI, Matplotlib/Seaborn.

## Data Source

[Rossmann Store Sales](https://www.kaggle.com/c/rossmann-store-sales) - Kaggle.

## Author

Priyanshu Singh - [(https://www.linkedin.com/in/maanapriyanshurajput/)] · [(https://maanajipriyanshu.github.io/insights-by-priyanshu/)]
