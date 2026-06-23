-- Rossmann Store Performance Analysis
-- FY2013 – H1 2015 | 1,115 stores | 844,338 records
-- PostgreSQL 15
-- Personal portfolio project — source data from Kaggle Rossmann Store Sales competition

-- Tables used:
--   rossmann_sales(Store, Date, Sales, Customers, Open, Promo, StateHoliday, SchoolHoliday)
--   rossmann_stores(Store, StoreType, Assortment, CompetitionDistance,
--                   CompetitionOpenSinceMonth, CompetitionOpenSinceYear,
--                   Promo2, Promo2SinceWeek, Promo2SinceYear, PromoInterval)


-- What does the overall dataset look like? Revenue, customers, promo coverage — one row.
-- Used as the opening slide number in weekly store performance reviews.
WITH base AS (
    SELECT
        MIN(date) AS report_start_date,
        MAX(date) AS report_end_date,
        COUNT(DISTINCT store) AS total_active_stores,
        SUM(sales)::NUMERIC AS total_revenue_eur,
        ROUND(
            SUM(sales)::NUMERIC /
            COUNT(DISTINCT date),
        2) AS avg_daily_revenue_eur,
        SUM(customers) AS total_customers,
        ROUND(
            SUM(sales)::NUMERIC /
            NULLIF(SUM(customers),0),
        2) AS revenue_per_customer_eur,
        ROUND(
            100.0 * COUNT(*) FILTER (WHERE promo = 1)
            / COUNT(*),
        2) AS promo_store_day_pct
    FROM rossmann_sales
    WHERE open = 1  -- exclude closed store-days; they'd pull down all averages
)
SELECT *
FROM base;