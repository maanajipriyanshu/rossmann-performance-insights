-- Rossmann Store Performance Analysis
-- FY2013 – H1 2015 | 1,115 stores | 844,338 records
-- PostgreSQL 15
-- Personal portfolio project — source data from Kaggle Rossmann Store Sales competition

-- Tables used:
--   rossmann_sales(Store, Date, Sales, Customers, Open, Promo, StateHoliday, SchoolHoliday)
--   rossmann_store(Store, StoreType, Assortment, CompetitionDistance,
--                   CompetitionOpenSinceMonth, CompetitionOpenSinceYear,
--                   Promo2, Promo2SinceWeek, Promo2SinceYear, PromoInterval)

-- Executive KPI summary
-- Revenue, customers and promotion coverage
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

-- which stores keep landing in the bottom 25% every quarter?
-- using NTILE to rank stores per quarter, then counting how often each store falls in quartile 4

WITH quarterly_sales AS (
    SELECT
        store,
        DATE_TRUNC('quarter', date::DATE) AS quarter,
        SUM(sales) AS quarterly_revenue,
        AVG(sales) AS avg_daily_sales,
        COUNT(*) AS open_days
    FROM rossmann_sales
    WHERE open = 1
    GROUP BY store, DATE_TRUNC('quarter', date::DATE)
),
store_quarterly_rank AS (
    SELECT
        store,
        quarter,
        quarterly_revenue,
        avg_daily_sales,
        NTILE(4) OVER (PARTITION BY quarter ORDER BY quarterly_revenue DESC) AS quartile
        -- Quartile 4 = bottom 25% in that quarter
    FROM quarterly_sales
),
underperformance_score AS (
    SELECT
        store,
        COUNT(*) FILTER (WHERE quartile = 4) AS quarters_in_bottom_25pct,
        COUNT(*) AS total_quarters,
        ROUND(AVG(avg_daily_sales)::NUMERIC, 2) AS avg_daily_sales_eur,
        ROUND(
            COUNT(*) FILTER (WHERE quartile = 4)::NUMERIC / COUNT(*) * 100
        , 1) AS bottom_quartile_rate_pct
    FROM store_quarterly_rank
    GROUP BY store
)
SELECT
    u.store,
    u.quarters_in_bottom_25pct,
    u.total_quarters,
    u.bottom_quartile_rate_pct,
    u.avg_daily_sales_eur,
    s.storetype,
    s.assortment,
    ROUND(s.competitiondistance::NUMERIC, 0) AS competition_dist_m,
    CASE
        WHEN u.bottom_quartile_rate_pct >= 75 THEN 'critical'
        WHEN u.bottom_quartile_rate_pct >= 50 THEN 'high'
        ELSE 'moderate'
    END AS intervention_priority
FROM underperformance_score u
JOIN rossmann_store s ON u.store = s.store
WHERE u.bottom_quartile_rate_pct >= 50
ORDER BY u.bottom_quartile_rate_pct DESC, u.avg_daily_sales_eur ASC
LIMIT 30;

-- quick check: monthly revenue trend before building the full growth query
SELECT
    DATE_TRUNC('month', date::DATE) AS month,
    SUM(sales)
FROM rossmann_sales
GROUP BY 1
ORDER BY month;


-- stores that are growing faster
-- Store-level month-over-month growth analysis
-- Uses LAG() for month-over-month growth + consistency scoring across 12+ months.
WITH monthly_revenue AS (
    SELECT
        store,
        DATE_TRUNC('month', date::DATE) AS month,
        SUM(sales) AS monthly_revenue,
        COUNT(*) AS open_days
    FROM rossmann_sales
    WHERE open = 1
    GROUP BY store, DATE_TRUNC('month', date::DATE)
),
growth_calc AS (
    SELECT
        store,
        month,
        monthly_revenue,
        LAG(monthly_revenue) OVER (PARTITION BY store ORDER BY month) AS prev_month_revenue,
        ROUND(
            (monthly_revenue - LAG(monthly_revenue) OVER (PARTITION BY store ORDER BY month))
          / NULLIF(LAG(monthly_revenue) OVER (PARTITION BY store ORDER BY month), 0) * 100
        , 2) AS mom_growth_pct
    FROM monthly_revenue
),
store_growth_profile AS (
    SELECT
        store,
        ROUND(AVG(mom_growth_pct)::NUMERIC, 2) AS avg_mom_growth_pct,
        ROUND(STDDEV(mom_growth_pct)::NUMERIC, 2) AS growth_volatility,
        COUNT(*) FILTER (WHERE mom_growth_pct > 0) AS positive_growth_months,
        COUNT(*) FILTER (WHERE mom_growth_pct IS NOT NULL) AS total_growth_months,
        ROUND(AVG(monthly_revenue)::NUMERIC, 0) AS avg_monthly_revenue_eur
    FROM growth_calc
    GROUP BY store
),
ranked_growth AS (
    SELECT
        *,
        DENSE_RANK() OVER (ORDER BY avg_mom_growth_pct DESC) AS growth_rank,
        ROUND(
            positive_growth_months::NUMERIC / NULLIF(total_growth_months, 0) * 100
        , 1) AS growth_consistency_pct
    FROM store_growth_profile
    WHERE total_growth_months >= 12  -- need at least a year of data to trust the trend
)
SELECT
    rg.store,
    rg.growth_rank,
    rg.avg_mom_growth_pct,
    rg.growth_volatility,
    rg.growth_consistency_pct,
    rg.avg_monthly_revenue_eur,
    s.storetype,
    s.assortment,
    CASE
        WHEN rg.avg_mom_growth_pct > 5 AND rg.growth_consistency_pct > 70
            THEN 'Top Performer'
        WHEN rg.avg_mom_growth_pct > 3 AND rg.growth_consistency_pct > 60
            THEN 'Growing'
        WHEN rg.avg_mom_growth_pct > 0
            THEN 'Stable'
        ELSE 'Needs Attention'
    END AS investment_signal
FROM ranked_growth rg
JOIN rossmann_store s ON rg.store = s.store
ORDER BY rg.growth_rank
LIMIT 25;


-- Promotion impact analysis
-- Compare sales, customers and basket size between promo and non-promo days
WITH promo_base AS (
    SELECT
        s.store,
        st.storetype,
        st.assortment,
        EXTRACT(DOW FROM s.date::DATE) AS day_of_week,
        s.promo,
        s.sales,
        s.customers,
        ROUND(s.sales / NULLIF(s.customers, 0)::NUMERIC, 2) AS basket_size
    FROM rossmann_sales s
    JOIN rossmann_store st ON s.store = st.store
    WHERE s.open = 1
),
promo_summary AS (
    SELECT
        storetype,
        assortment,
        ROUND(AVG(sales) FILTER (WHERE promo = 1), 2) AS avg_sales_promo_day,
        ROUND(AVG(sales) FILTER (WHERE promo = 0), 2) AS avg_sales_non_promo_day,
        ROUND(AVG(customers) FILTER (WHERE promo = 1), 0) AS avg_customers_promo,
        ROUND(AVG(customers) FILTER (WHERE promo = 0), 0) AS avg_customers_non_promo,
        ROUND(AVG(basket_size) FILTER (WHERE promo = 1), 2) AS avg_basket_promo,
        ROUND(AVG(basket_size) FILTER (WHERE promo = 0), 2) AS avg_basket_non_promo,
        COUNT(*) FILTER (WHERE promo = 1) AS total_promo_days,
        COUNT(*) FILTER (WHERE promo = 0) AS total_non_promo_days
    FROM promo_base
    GROUP BY storetype, assortment
)
SELECT
    storetype,
    assortment,
    avg_sales_promo_day,
    avg_sales_non_promo_day,
    ROUND(avg_sales_promo_day - avg_sales_non_promo_day::NUMERIC, 2) AS revenue_lift_eur,
    ROUND((avg_sales_promo_day - avg_sales_non_promo_day)
        / NULLIF(avg_sales_non_promo_day, 0) * 100, 1) AS revenue_lift_pct,
    avg_customers_promo,
    avg_customers_non_promo,
    ROUND((avg_customers_promo - avg_customers_non_promo)::NUMERIC
        / NULLIF(avg_customers_non_promo, 0) * 100, 1) AS customer_lift_pct,
    avg_basket_promo,
    avg_basket_non_promo,
    ROUND(avg_basket_promo - avg_basket_non_promo, 2) AS basket_size_delta_eur,
    ROUND((avg_sales_promo_day - avg_sales_non_promo_day)
        * total_promo_days / 1000, 1) AS annualized_promo_lift_k_eur
FROM promo_summary
ORDER BY revenue_lift_pct DESC;

-- Performance benchmark for assortment
-- Which assortment type (basic / extra / extended) drives the most revenue per store?
-- Includes promo effectiveness ratio to see whether assortment type affects promo response.
WITH store_metrics AS (
    SELECT
        s.store,
        st.assortment,
        st.storetype,
        SUM(s.sales) AS total_revenue,
        AVG(s.sales) AS avg_daily_sales,
        AVG(s.customers) AS avg_daily_customers,
        ROUND(AVG(s.sales / NULLIF(s.customers, 0)), 2) AS avg_basket_size,
        COUNT(*) AS open_days,
        AVG(s.sales) FILTER (WHERE s.promo = 1)
            / NULLIF(AVG(s.sales) FILTER (WHERE s.promo = 0), 0) AS promo_multiplier
    FROM rossmann_sales s
    JOIN rossmann_store st ON s.store = st.store
    WHERE s.open = 1
    GROUP BY s.store, st.assortment, st.storetype
),
assortment_agg AS (
    SELECT
        assortment,
        storetype,
        COUNT(DISTINCT store) AS store_count,
        ROUND(AVG(avg_daily_sales)::NUMERIC, 2) AS avg_daily_sales_eur,
        ROUND(AVG(avg_daily_customers)::NUMERIC, 0) AS avg_daily_customers,
        ROUND(AVG(avg_basket_size)::NUMERIC, 2) AS avg_basket_size_eur,
        ROUND(AVG(promo_multiplier)::NUMERIC, 3) AS promo_effectiveness_ratio,
        ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP
		      (ORDER BY avg_daily_sales)::NUMERIC, 2) AS median_daily_sales_eur,
        ROUND(PERCENTILE_CONT(0.9) WITHIN GROUP
            (ORDER BY avg_daily_sales)::NUMERIC, 2) AS p90_daily_sales_eur
    FROM store_metrics
    GROUP BY assortment, storetype
)
SELECT
    assortment,
    CASE assortment
        WHEN 'a' THEN 'Basic'
        WHEN 'b' THEN 'Extra'
        WHEN 'c' THEN 'Extended'
    END AS assortment_label,
    storetype,
    store_count,
    avg_daily_sales_eur,
    avg_daily_customers,
    avg_basket_size_eur,
    promo_effectiveness_ratio,
    median_daily_sales_eur,
    p90_daily_sales_eur,
    RANK() OVER (ORDER BY avg_daily_sales_eur DESC) AS revenue_rank
FROM assortment_agg
ORDER BY avg_daily_sales_eur DESC;