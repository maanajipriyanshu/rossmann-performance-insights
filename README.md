# Rossmann Sales Performance Analysis

## Business Problem
Rossmann operates 1,115 drug stores across Germany. 
This project analyzes 844,338 sales records to identify 
key revenue drivers, seasonal patterns, and store 
performance benchmarks to support business decisions.

## Dataset
- Source: Rossmann Store Sales (Kaggle)
- Records: 844,338 sales transactions
- Period: January 2013 – July 2015
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
1. **Store 817** is the top performer with €21.8K average daily sales — 3x the overall average
2. **Promotions increase sales by 38%** — from €5.9K to €8.2K average daily sales
3. **December sales spike 49%** above yearly average — strong Christmas seasonality
4. **Store Type b** generates 48% higher sales than other store types
5. **Competition distance shows no negative impact** — top stores have competition within 500m
6. **Sunday and Monday** are peak sales days — Saturday is lowest

## SQL Queries
8 PostgreSQL queries including:
- CTEs for above-average store identification
- RANK() window function for store rankings
- LAG() for month-over-month growth analysis
- JOIN across sales and store tables

## Power BI Dashboard
![Dashboard](Charts/dashboard.png)

## How to Run
1. Clone this repository
2. Install requirements: `pip install pandas numpy matplotlib seaborn sqlalchemy psycopg2-binary`
3. Run notebooks in order: 01_cleaning → 02_eda
