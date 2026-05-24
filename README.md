# Rossmann Sales Performance Analysis

## Business Problem
Rossmann operates 1,115 drug stores across Germany. 
This project analyzes 844,338 sales records to identify 
key revenue drivers, seasonal patterns, and store 
performance benchmarks to support business decisions.

## Dataset
- Source: Rossmann Store Sales (Kaggle)
- Records: 844,338 sales transactions
- Period: January 2013 - July 2015
- Stores: 1,115 German retail stores

## Tech Stack
- Python (Pandas, NumPy, Matplotlib, Seaborn)
- PostgreSQL
- Power BI
- Jupyter Notebook

## Project Structure
rossmann-project/
├── data/
│   ├── raw/
│   └── clean/
├── notebooks/
│   ├── 01_cleaning.ipynb
│   └── 02_eda.ipynb
└── charts/

## Key Findings
1. **Store 817** is the top performer with €21.8K average daily sales, 3x the overall average
2. **Promotions increase sales by 38%** - from €5.9K to €8.2K average daily sales
3. **December sales spike 49%** above yearly average - strong Christmas seasonality
4. **Store Type b** generates 48% higher sales than other store types
5. **Competition distance shows no negative impact** - top stores have competition within 500m
6. **Sunday and Monday** are peak sales days. Saturday is lowest

## SQL Queries
There are 8 PostgreSQL queries including:
- CTEs for above-average store identification
- RANK() window function for store rankings
- LAG() for month-over-month growth analysis
- JOIN across sales and store tables

## Power BI Dashboard
![Dashboard](Charts/dashboard.png)


## Business Recommendations

1. **Scale Promotions Strategically**
Promotions drive 38% higher sales. Recommend running promotions 
consistently in September, the lowest sales month to reduce 
seasonal dip.

2. **Replicate Store Type b Model**
Store Type b generates 48% higher average daily sales. 
Recommend analyzing Type b store locations and formats 
for expansion strategy.

3. **Maximize December Inventory**
December sales spike 49% above average. Recommend increasing 
inventory by minimum 40% from November onwards to avoid 
stockouts during peak season.

4. **Investigate Store 817 Success Factors**
Store 817 outperforms all others despite having competition 
140 meters away. Recommend detailed store audit to identify 
replicable success factors.

5. **Address September Slump**
September is consistently the weakest month. Targeted promotions 
or loyalty campaigns during this period could recover lost revenue.


## How to Run
1. Clone this repository
2. Install requirements: `pip install pandas numpy matplotlib seaborn sqlalchemy psycopg2-binary`
3. Run notebooks in order: 01_cleaning → 02_eda
