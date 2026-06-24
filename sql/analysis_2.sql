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


-- Impact of Competition proximity
-- Does having a competitor nearby actually hurt revenue?
-- Bands stores by distance to nearest competitor, compares average daily sales across zones.
WITH store_revenue AS (
    SELECT
        s.store,
        AVG(s.sales) AS avg_daily_sales,
        AVG(s.customers) AS avg_daily_customers,
        SUM(s.sales) AS total_revenue,
        COUNT(*) AS open_days
    FROM rossmann_sales s
    WHERE s.open = 1
    GROUP BY s.store
),
competition_bands AS (
    SELECT
        st.store,
        st.competitiondistance,
        st.storetype,
        st.assortment,
        sr.avg_daily_sales,
        sr.avg_daily_customers,
        CASE
            WHEN st.competitiondistance IS NULL THEN 'No competitor data'
            WHEN st.competitiondistance <= 500 THEN '0-500m'
            WHEN st.competitiondistance <= 1000 THEN '500m-1km'
            WHEN st.competitiondistance <= 3000 THEN '1km-3km'
            WHEN st.competitiondistance <= 10000 THEN '3km-10km'
            ELSE '10km+'
        END AS competition_zone
    FROM rossmann_store st
    JOIN store_revenue sr ON st.store = sr.store
)
SELECT
    competition_zone,
    COUNT(DISTINCT store)                          AS store_count,
    ROUND(AVG(avg_daily_sales), 2)                AS avg_daily_sales_eur,
    ROUND(AVG(avg_daily_customers), 0)            AS avg_daily_customers,
    ROUND(STDDEV(avg_daily_sales), 2)             AS sales_std_dev,
    ROUND(MIN(avg_daily_sales), 2)                AS min_store_sales,
    ROUND(MAX(avg_daily_sales), 2)                AS max_store_sales,
    ROUND(AVG(avg_daily_sales)
        / NULLIF((SELECT AVG(avg_daily_sales) FROM competition_bands), 0) * 100, 1)
                                                  AS index_vs_portfolio_avg
FROM competition_bands
GROUP BY competition_zone
ORDER BY AVG(avg_daily_sales) DESC;


-- Impact of holiday and season
-- Which months drive the highest revenue, and how much of that overlaps with holidays?
-- Indexes each month against the annual average to flag peak, normal, and low seasons.
WITH enriched_sales AS (
    SELECT
        s.sales,
        s.customers,
        s.promo,
        s.stateholiday,
        s.schoolholiday,
        EXTRACT(MONTH FROM s.date::DATE) AS month_num,
        TO_CHAR(s.date::DATE, 'Month') AS month_name,
        EXTRACT(DOW FROM s.date::DATE) AS dow_num,
        TO_CHAR(s.date::DATE, 'Day') AS day_name,
        EXTRACT(YEAR FROM s.date::DATE) AS year_num
    FROM rossmann_sales s
    WHERE s.open = 1
),
month_summary AS (
    SELECT
        month_num,
        TRIM(month_name) AS month_name,
        ROUND(AVG(sales)::NUMERIC, 2) AS avg_daily_sales,
        ROUND(AVG(customers)::NUMERIC, 0) AS avg_daily_customers,
        COUNT(*) FILTER (WHERE stateholiday != '0') AS state_holiday_days,
        COUNT(*) FILTER (WHERE schoolholiday = 1)   AS school_holiday_days
    FROM enriched_sales
    GROUP BY month_num, month_name
),
portfolio_avg AS (
    SELECT AVG(sales) AS overall_avg FROM enriched_sales
)
SELECT
    m.month_num,
    m.month_name,
    m.avg_daily_sales,
    m.avg_daily_customers,
    m.state_holiday_days,
    m.school_holiday_days,
    ROUND(m.avg_daily_sales / p.overall_avg * 100 - 100, 1) AS index_vs_annual_avg_pct,
    RANK() OVER (ORDER BY m.avg_daily_sales DESC) AS revenue_rank,
    CASE
        WHEN m.avg_daily_sales > p.overall_avg * 1.2 THEN 'Peak'
        WHEN m.avg_daily_sales > p.overall_avg * 0.9 THEN 'Normal'
        ELSE 'Low'
    END AS season_flag
FROM month_summary m, portfolio_avg p
ORDER BY m.month_num;

-- Store tier classification
-- How do the 1,115 stores break down when scored across revenue, growth, and consistency?
-- Uses NTILE quartiles on each dimension, then sums into a composite score.
-- Lower composite = stronger store (1 = top quartile on all three).
WITH store_kpis AS (
    SELECT
        s.store,
        SUM(s.sales) AS total_revenue,
        AVG(s.sales) AS avg_daily_sales,
        STDDEV(s.sales) AS sales_volatility,
        AVG(s.sales) / NULLIF(STDDEV(s.sales), 0) AS consistency_ratio,
        COUNT(*) AS open_days,
        AVG(s.sales) FILTER (WHERE EXTRACT(YEAR FROM s.date::DATE) = 2014)
            / NULLIF(AVG(s.sales) FILTER (WHERE EXTRACT(YEAR FROM s.date::DATE) = 2013), 0)
            - 1 AS yoy_growth_rate
    FROM rossmann_sales s
    WHERE s.open = 1
    GROUP BY s.store
),
scored AS (
    SELECT
        store,
        avg_daily_sales,
        consistency_ratio,
        yoy_growth_rate,
        NTILE(4) OVER (ORDER BY avg_daily_sales DESC) AS revenue_quartile,
        NTILE(4) OVER (ORDER BY yoy_growth_rate DESC) AS growth_quartile,
        NTILE(4) OVER (ORDER BY consistency_ratio DESC) AS consistency_quartile
    FROM store_kpis
    WHERE yoy_growth_rate IS NOT NULL
),
composite AS (
    SELECT
        store,
        avg_daily_sales,
        yoy_growth_rate,
        consistency_ratio,
        -- Lower total = better (each quartile: 1=top, 4=bottom)
        revenue_quartile + growth_quartile + consistency_quartile AS composite_score
    FROM scored
)
SELECT
    c.store,
    ROUND(c.avg_daily_sales ::NUMERIC, 2) AS avg_daily_sales_eur,
    ROUND(c.yoy_growth_rate * 100 ::NUMERIC, 1) AS yoy_growth_pct,
    ROUND(c.consistency_ratio ::NUMERIC, 2) AS consistency_ratio,
    c.composite_score,
    CASE
        WHEN composite_score <= 5 THEN 'Tier 1 - top performers across all three dimensions'
        WHEN composite_score <= 7 THEN 'Tier 2 - strong on at least two dimensions'
        WHEN composite_score <= 9 THEN 'Tier 3 - mixed, room to improve'
        ELSE                           'Tier 4 - underperforming, needs review'
    END AS store_tier,
    st.storetype,
    st.assortment,
    ROUND(st.competitiondistance, 0) AS competition_dist_m
FROM composite c
JOIN stores st ON c.store = st.store
ORDER BY c.composite_score, c.avg_daily_sales DESC;

-- Sales momentum over week over week
-- Is each store accelerating or slowing down in the most recent period?
-- Uses LAG() for WoW and 4-week-ago comparisons, plus a rolling 4-week average as baseline.
WITH weekly_sales AS (
    SELECT
        store,
        DATE_TRUNC('week', date::DATE) AS week_start,
        SUM(sales) AS weekly_revenue,
        SUM(customers) AS weekly_customers,
        COUNT(*) AS open_days
    FROM rossmann_sales
    WHERE open = 1
    GROUP BY store, DATE_TRUNC('week', date::DATE)
),
weekly_momentum AS (
    SELECT
        store,
        week_start,
        weekly_revenue,
        LAG(weekly_revenue, 1) OVER (PARTITION BY store ORDER BY week_start) AS prev_week_rev,
        LAG(weekly_revenue, 4) OVER (PARTITION BY store ORDER BY week_start) AS prev_4wk_rev,
        LEAD(weekly_revenue, 1) OVER (PARTITION BY store ORDER BY week_start) AS next_week_rev,
        AVG(weekly_revenue) OVER (
            PARTITION BY store
            ORDER BY week_start
            ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
        ) AS rolling_4wk_avg
    FROM weekly_sales
)
SELECT
    store,
    week_start,
    weekly_revenue,
    ROUND(weekly_revenue - prev_week_rev::NUMERIC, 0) AS wow_change_eur,
    ROUND((weekly_revenue - prev_week_rev)
        / NULLIF(prev_week_rev, 0) * 100 ::NUMERIC, 1) AS wow_growth_pct,
    ROUND((weekly_revenue - prev_4wk_rev)
        / NULLIF(prev_4wk_rev, 0) * 100::NUMERIC, 1) AS vs_4wk_ago_pct,
    ROUND(rolling_4wk_avg::NUMERIC, 0) AS rolling_4wk_avg_eur,
    CASE
        WHEN weekly_revenue > rolling_4wk_avg * 1.1 THEN 'Accelerating'
        WHEN weekly_revenue > rolling_4wk_avg * 0.9 THEN 'Stable'
        ELSE 'Decelerating'
    END AS momentum_flag
FROM weekly_momentum
WHERE week_start >= '2015-01-01'  -- most recent period only
ORDER BY store, week_start;