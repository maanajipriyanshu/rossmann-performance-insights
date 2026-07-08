-- =============================================================================
-- ROSSMANN RETAIL GROUP | STORE PERFORMANCE ANALYTICS
-- Analyst: Junior Data Analyst, Retail Analytics Team
-- Period: FY2013 – H1 2015 | Stores: 1,115 | Records: 844,338
-- Database: PostgreSQL 15
-- =============================================================================
-- SCHEMA REFERENCE:
--   sales(Store, Date, Sales, Customers, Open, Promo, StateHoliday, SchoolHoliday)
--   stores(Store, StoreType, Assortment, CompetitionDistance,
--          CompetitionOpenSinceMonth, CompetitionOpenSinceYear,
--          Promo2, Promo2SinceWeek, Promo2SinceYear, PromoInterval)
-- =============================================================================


-- =============================================================================
-- QUERY 01 | EXECUTIVE KPI SUMMARY
-- Business Question: What is the overall performance baseline?
-- Purpose: Weekly leadership briefing — single-row KPI snapshot
-- =============================================================================
WITH base AS (
    SELECT
        COUNT(DISTINCT store)                          AS total_active_stores,
        SUM(sales)                                     AS total_revenue_eur,
        ROUND(AVG(sales), 2)                           AS avg_daily_sales_eur,
        SUM(customers)                                 AS total_customers,
        ROUND(AVG(sales) / NULLIF(AVG(customers), 0), 2) AS avg_basket_size_eur,
        COUNT(*) FILTER (WHERE promo = 1)::FLOAT
            / NULLIF(COUNT(*), 0) * 100                AS promo_day_pct
    FROM sales
    WHERE open = 1
),
yoy AS (
    SELECT
        ROUND(
            (SUM(CASE WHEN EXTRACT(YEAR FROM date) = 2014 THEN sales END)
           - SUM(CASE WHEN EXTRACT(YEAR FROM date) = 2013 THEN sales END))
          / NULLIF(SUM(CASE WHEN EXTRACT(YEAR FROM date) = 2013 THEN sales END), 0) * 100
        , 2) AS revenue_growth_yoy_pct
    FROM sales
    WHERE open = 1
)
SELECT
    b.total_active_stores,
    ROUND(b.total_revenue_eur / 1000000.0, 2)  AS total_revenue_million_eur,
    b.avg_daily_sales_eur,
    b.total_customers,
    b.avg_basket_size_eur,
    ROUND(b.promo_day_pct, 1)                  AS promo_day_pct,
    y.revenue_growth_yoy_pct
FROM base b, yoy y;


-- =============================================================================
-- QUERY 02 | CONSISTENTLY UNDERPERFORMING STORES — ROOT CAUSE FLAGGING
-- Business Question: Which stores are chronic underperformers across all periods?
-- Purpose: Regional manager escalation list — stores needing intervention
-- Technique: Multi-period RANK() comparison + flag scoring
-- =============================================================================
WITH quarterly_sales AS (
    SELECT
        store,
        DATE_TRUNC('quarter', date)   AS quarter,
        SUM(sales)                    AS quarterly_revenue,
        AVG(sales)                    AS avg_daily_sales,
        COUNT(*)                      AS open_days
    FROM sales
    WHERE open = 1
    GROUP BY store, DATE_TRUNC('quarter', date)
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
        COUNT(*) FILTER (WHERE quartile = 4)  AS quarters_in_bottom_25pct,
        COUNT(*)                               AS total_quarters,
        ROUND(AVG(avg_daily_sales), 2)         AS avg_daily_sales_eur,
        ROUND(
            COUNT(*) FILTER (WHERE quartile = 4)::NUMERIC / COUNT(*) * 100
        , 1)                                   AS bottom_quartile_rate_pct
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
    ROUND(s.competitiondistance, 0) AS competition_dist_m,
    CASE
        WHEN u.bottom_quartile_rate_pct >= 75 THEN 'CRITICAL — Immediate Review'
        WHEN u.bottom_quartile_rate_pct >= 50 THEN 'HIGH — Monitor Closely'
        ELSE 'MODERATE — Quarterly Check-In'
    END AS intervention_priority
FROM underperformance_score u
JOIN stores s ON u.store = s.store
WHERE u.bottom_quartile_rate_pct >= 50
ORDER BY u.bottom_quartile_rate_pct DESC, u.avg_daily_sales_eur ASC
LIMIT 30;


-- =============================================================================
-- QUERY 03 | FASTEST GROWING STORES — INVESTMENT TARGETING
-- Business Question: Which stores show the strongest and most consistent growth?
-- Purpose: Capital allocation — identify stores worth additional investment
-- Technique: LAG() for MoM growth + rolling 3-month trend scoring
-- =============================================================================
WITH monthly_revenue AS (
    SELECT
        store,
        DATE_TRUNC('month', date)       AS month,
        SUM(sales)                      AS monthly_revenue,
        COUNT(*)                        AS open_days
    FROM sales
    WHERE open = 1
    GROUP BY store, DATE_TRUNC('month', date)
),
growth_calc AS (
    SELECT
        store,
        month,
        monthly_revenue,
        LAG(monthly_revenue) OVER (PARTITION BY store ORDER BY month)  AS prev_month_revenue,
        ROUND(
            (monthly_revenue - LAG(monthly_revenue) OVER (PARTITION BY store ORDER BY month))
          / NULLIF(LAG(monthly_revenue) OVER (PARTITION BY store ORDER BY month), 0) * 100
        , 2)                                                            AS mom_growth_pct
    FROM monthly_revenue
),
store_growth_profile AS (
    SELECT
        store,
        ROUND(AVG(mom_growth_pct), 2)                                  AS avg_mom_growth_pct,
        ROUND(STDDEV(mom_growth_pct), 2)                               AS growth_volatility,
        COUNT(*) FILTER (WHERE mom_growth_pct > 0)                     AS positive_growth_months,
        COUNT(*) FILTER (WHERE mom_growth_pct IS NOT NULL)             AS total_growth_months,
        ROUND(AVG(monthly_revenue), 0)                                 AS avg_monthly_revenue_eur
    FROM growth_calc
    GROUP BY store
),
ranked_growth AS (
    SELECT
        *,
        DENSE_RANK() OVER (ORDER BY avg_mom_growth_pct DESC)           AS growth_rank,
        ROUND(
            positive_growth_months::NUMERIC / NULLIF(total_growth_months, 0) * 100
        , 1)                                                            AS growth_consistency_pct
    FROM store_growth_profile
    WHERE total_growth_months >= 12   -- Minimum 12 months of data
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
            THEN 'STAR — Prioritize Expansion'
        WHEN rg.avg_mom_growth_pct > 3 AND rg.growth_consistency_pct > 60
            THEN 'RISING — Increase Investment'
        WHEN rg.avg_mom_growth_pct > 0
            THEN 'STABLE — Maintain Budget'
        ELSE 'DECLINING — Review Strategy'
    END AS investment_signal
FROM ranked_growth rg
JOIN stores s ON rg.store = s.store
ORDER BY rg.growth_rank
LIMIT 25;


-- =============================================================================
-- QUERY 04 | PROMOTION IMPACT ANALYSIS — INCREMENTAL REVENUE QUANTIFICATION
-- Business Question: How much incremental revenue do promotions generate?
-- Purpose: Marketing budget justification + promo calendar optimization
-- Technique: Conditional aggregation + revenue lift calculation
-- =============================================================================
WITH promo_base AS (
    SELECT
        s.store,
        st.storetype,
        st.assortment,
        EXTRACT(DOW FROM s.date)           AS day_of_week,
        s.promo,
        s.sales,
        s.customers,
        ROUND(s.sales / NULLIF(s.customers, 0), 2) AS basket_size
    FROM sales s
    JOIN stores st ON s.store = st.store
    WHERE s.open = 1
),
promo_summary AS (
    SELECT
        storetype,
        assortment,
        -- Revenue metrics
        ROUND(AVG(sales) FILTER (WHERE promo = 1), 2)        AS avg_sales_promo_day,
        ROUND(AVG(sales) FILTER (WHERE promo = 0), 2)        AS avg_sales_non_promo_day,
        -- Customer metrics
        ROUND(AVG(customers) FILTER (WHERE promo = 1), 0)    AS avg_customers_promo,
        ROUND(AVG(customers) FILTER (WHERE promo = 0), 0)    AS avg_customers_non_promo,
        -- Basket size metrics
        ROUND(AVG(basket_size) FILTER (WHERE promo = 1), 2)  AS avg_basket_promo,
        ROUND(AVG(basket_size) FILTER (WHERE promo = 0), 2)  AS avg_basket_non_promo,
        COUNT(*) FILTER (WHERE promo = 1)                    AS total_promo_days,
        COUNT(*) FILTER (WHERE promo = 0)                    AS total_non_promo_days
    FROM promo_base
    GROUP BY storetype, assortment
)
SELECT
    storetype,
    assortment,
    avg_sales_promo_day,
    avg_sales_non_promo_day,
    ROUND(avg_sales_promo_day - avg_sales_non_promo_day, 2)              AS revenue_lift_eur,
    ROUND((avg_sales_promo_day - avg_sales_non_promo_day)
        / NULLIF(avg_sales_non_promo_day, 0) * 100, 1)                  AS revenue_lift_pct,
    avg_customers_promo,
    avg_customers_non_promo,
    ROUND((avg_customers_promo - avg_customers_non_promo)::NUMERIC
        / NULLIF(avg_customers_non_promo, 0) * 100, 1)                  AS customer_lift_pct,
    avg_basket_promo,
    avg_basket_non_promo,
    ROUND(avg_basket_promo - avg_basket_non_promo, 2)                   AS basket_size_delta_eur,
    -- Annualized incremental revenue estimate
    ROUND((avg_sales_promo_day - avg_sales_non_promo_day) * total_promo_days / 1000, 1)
                                                                        AS annualized_promo_lift_k_eur
FROM promo_summary
ORDER BY revenue_lift_pct DESC;


-- =============================================================================
-- QUERY 05 | ASSORTMENT PERFORMANCE BENCHMARK
-- Business Question: Which assortment strategy generates the highest revenue per store?
-- Purpose: Merchandise planning — assortment investment decisions
-- Assortment types: a = basic, b = extra, c = extended
-- =============================================================================
WITH store_metrics AS (
    SELECT
        s.store,
        st.assortment,
        st.storetype,
        SUM(s.sales)                                         AS total_revenue,
        AVG(s.sales)                                         AS avg_daily_sales,
        AVG(s.customers)                                     AS avg_daily_customers,
        ROUND(AVG(s.sales / NULLIF(s.customers, 0)), 2)     AS avg_basket_size,
        COUNT(*)                                             AS open_days,
        AVG(s.sales) FILTER (WHERE s.promo = 1)
            / NULLIF(AVG(s.sales) FILTER (WHERE s.promo = 0), 0) AS promo_multiplier
    FROM sales s
    JOIN stores st ON s.store = st.store
    WHERE s.open = 1
    GROUP BY s.store, st.assortment, st.storetype
),
assortment_agg AS (
    SELECT
        assortment,
        storetype,
        COUNT(DISTINCT store)                                AS store_count,
        ROUND(AVG(avg_daily_sales), 2)                      AS avg_daily_sales_eur,
        ROUND(AVG(avg_daily_customers), 0)                  AS avg_daily_customers,
        ROUND(AVG(avg_basket_size), 2)                      AS avg_basket_size_eur,
        ROUND(AVG(promo_multiplier), 3)                     AS promo_effectiveness_ratio,
        ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP
            (ORDER BY avg_daily_sales), 2)                  AS median_daily_sales_eur,
        ROUND(PERCENTILE_CONT(0.9) WITHIN GROUP
            (ORDER BY avg_daily_sales), 2)                  AS p90_daily_sales_eur
    FROM store_metrics
    GROUP BY assortment, storetype
)
SELECT
    assortment,
    CASE assortment
        WHEN 'a' THEN 'Basic'
        WHEN 'b' THEN 'Extra'
        WHEN 'c' THEN 'Extended'
    END                                                      AS assortment_label,
    storetype,
    store_count,
    avg_daily_sales_eur,
    avg_daily_customers,
    avg_basket_size_eur,
    promo_effectiveness_ratio,
    median_daily_sales_eur,
    p90_daily_sales_eur,
    RANK() OVER (ORDER BY avg_daily_sales_eur DESC)          AS revenue_rank
FROM assortment_agg
ORDER BY avg_daily_sales_eur DESC;


-- =============================================================================
-- QUERY 06 | COMPETITION PROXIMITY IMPACT — SPATIAL REVENUE ANALYSIS
-- Business Question: Does nearby competition hurt our store revenue?
-- Purpose: Site selection intelligence + competitive response strategy
-- Technique: Distance banding + revenue comparison across competitive zones
-- =============================================================================
WITH store_revenue AS (
    SELECT
        s.store,
        AVG(s.sales)                        AS avg_daily_sales,
        AVG(s.customers)                    AS avg_daily_customers,
        SUM(s.sales)                        AS total_revenue,
        COUNT(*)                            AS open_days
    FROM sales s
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
            WHEN st.competitiondistance IS NULL         THEN 'No Competitor Data'
            WHEN st.competitiondistance <= 500          THEN '0–500m (High Competition)'
            WHEN st.competitiondistance <= 1000         THEN '500m–1km (Medium-High)'
            WHEN st.competitiondistance <= 3000         THEN '1km–3km (Medium)'
            WHEN st.competitiondistance <= 10000        THEN '3km–10km (Low)'
            ELSE '10km+ (Very Low / Rural)'
        END AS competition_zone
    FROM stores st
    JOIN store_revenue sr ON st.store = sr.store
)
SELECT
    competition_zone,
    COUNT(DISTINCT store)                           AS store_count,
    ROUND(AVG(avg_daily_sales), 2)                 AS avg_daily_sales_eur,
    ROUND(AVG(avg_daily_customers), 0)             AS avg_daily_customers,
    ROUND(STDDEV(avg_daily_sales), 2)              AS sales_std_dev,
    ROUND(MIN(avg_daily_sales), 2)                 AS min_store_sales,
    ROUND(MAX(avg_daily_sales), 2)                 AS max_store_sales,
    ROUND(AVG(avg_daily_sales)
        / NULLIF((SELECT AVG(avg_daily_sales) FROM competition_bands), 0) * 100, 1)
                                                   AS index_vs_portfolio_avg
FROM competition_bands
GROUP BY competition_zone
ORDER BY AVG(avg_daily_sales) DESC;


-- =============================================================================
-- QUERY 07 | SEASONALITY & HOLIDAY IMPACT MATRIX
-- Business Question: Which periods drive the highest revenue and should inform staffing?
-- Purpose: Workforce planning + inventory procurement calendar
-- Technique: Multi-dimension aggregation with holiday flag analysis
-- =============================================================================
WITH enriched_sales AS (
    SELECT
        s.sales,
        s.customers,
        s.promo,
        s.stateholiday,
        s.schoolholiday,
        EXTRACT(MONTH FROM s.date)           AS month_num,
        TO_CHAR(s.date, 'Month')             AS month_name,
        EXTRACT(DOW FROM s.date)             AS dow_num,
        TO_CHAR(s.date, 'Day')               AS day_name,
        EXTRACT(YEAR FROM s.date)            AS year_num
    FROM sales s
    WHERE s.open = 1
),
month_summary AS (
    SELECT
        month_num,
        TRIM(month_name)                     AS month_name,
        ROUND(AVG(sales), 2)                 AS avg_daily_sales,
        ROUND(AVG(customers), 0)             AS avg_daily_customers,
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
    RANK() OVER (ORDER BY m.avg_daily_sales DESC)            AS revenue_rank,
    CASE
        WHEN m.avg_daily_sales > p.overall_avg * 1.2  THEN 'Peak Season'
        WHEN m.avg_daily_sales > p.overall_avg * 0.9  THEN 'Normal Season'
        ELSE 'Low Season'
    END AS season_flag
FROM month_summary m, portfolio_avg p
ORDER BY m.month_num;


-- =============================================================================
-- QUERY 08 | STORE TIER CLASSIFICATION — PORTFOLIO SEGMENTATION
-- Business Question: How should we segment our 1,115 stores for differentiated strategy?
-- Purpose: Resource allocation framework — tiered investment model
-- Technique: NTILE + composite scoring across revenue, growth, and consistency
-- =============================================================================
WITH store_kpis AS (
    SELECT
        s.store,
        SUM(s.sales)                                              AS total_revenue,
        AVG(s.sales)                                              AS avg_daily_sales,
        STDDEV(s.sales)                                           AS sales_volatility,
        AVG(s.sales) / NULLIF(STDDEV(s.sales), 0)                AS consistency_ratio,
        COUNT(*)                                                  AS open_days,
        AVG(s.sales) FILTER (WHERE EXTRACT(YEAR FROM s.date) = 2014)
            / NULLIF(AVG(s.sales) FILTER (WHERE EXTRACT(YEAR FROM s.date) = 2013), 0)
            - 1                                                   AS yoy_growth_rate
    FROM sales s
    WHERE s.open = 1
    GROUP BY s.store
),
scored AS (
    SELECT
        store,
        avg_daily_sales,
        consistency_ratio,
        yoy_growth_rate,
        NTILE(4) OVER (ORDER BY avg_daily_sales DESC)    AS revenue_quartile,
        NTILE(4) OVER (ORDER BY yoy_growth_rate DESC)    AS growth_quartile,
        NTILE(4) OVER (ORDER BY consistency_ratio DESC)  AS consistency_quartile
    FROM store_kpis
    WHERE yoy_growth_rate IS NOT NULL
),
composite AS (
    SELECT
        store,
        avg_daily_sales,
        yoy_growth_rate,
        consistency_ratio,
        -- Lower quartile number = better (1=top, 4=bottom)
        revenue_quartile + growth_quartile + consistency_quartile AS composite_score
    FROM scored
)
SELECT
    c.store,
    ROUND(c.avg_daily_sales, 2)          AS avg_daily_sales_eur,
    ROUND(c.yoy_growth_rate * 100, 1)    AS yoy_growth_pct,
    ROUND(c.consistency_ratio, 2)        AS consistency_ratio,
    c.composite_score,
    CASE
        WHEN composite_score <= 5   THEN 'TIER 1 — Champions'
        WHEN composite_score <= 7   THEN 'TIER 2 — Performers'
        WHEN composite_score <= 9   THEN 'TIER 3 — Developing'
        ELSE                             'TIER 4 — Turnaround Required'
    END AS store_tier,
    st.storetype,
    st.assortment,
    ROUND(st.competitiondistance, 0)     AS competition_dist_m
FROM composite c
JOIN stores st ON c.store = st.store
ORDER BY c.composite_score, c.avg_daily_sales DESC;


-- =============================================================================
-- QUERY 09 | WEEK-OVER-WEEK SALES MOMENTUM — OPERATIONAL PULSE
-- Business Question: Are we accelerating or decelerating this month vs last?
-- Purpose: Weekly ops meeting — short-term trend visibility
-- Technique: LAG() + LEAD() for momentum detection, rolling 4-week window
-- =============================================================================
WITH weekly_sales AS (
    SELECT
        store,
        DATE_TRUNC('week', date)              AS week_start,
        SUM(sales)                            AS weekly_revenue,
        SUM(customers)                        AS weekly_customers,
        COUNT(*)                              AS open_days
    FROM sales
    WHERE open = 1
    GROUP BY store, DATE_TRUNC('week', date)
),
weekly_momentum AS (
    SELECT
        store,
        week_start,
        weekly_revenue,
        LAG(weekly_revenue, 1) OVER (PARTITION BY store ORDER BY week_start)  AS prev_week_rev,
        LAG(weekly_revenue, 4) OVER (PARTITION BY store ORDER BY week_start)  AS prev_4wk_rev,
        LEAD(weekly_revenue, 1) OVER (PARTITION BY store ORDER BY week_start) AS next_week_rev,
        AVG(weekly_revenue) OVER (
            PARTITION BY store
            ORDER BY week_start
            ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
        )                                                                      AS rolling_4wk_avg
    FROM weekly_sales
)
SELECT
    store,
    week_start,
    weekly_revenue,
    ROUND(weekly_revenue - prev_week_rev, 0)                            AS wow_change_eur,
    ROUND((weekly_revenue - prev_week_rev) / NULLIF(prev_week_rev, 0) * 100, 1)
                                                                        AS wow_growth_pct,
    ROUND((weekly_revenue - prev_4wk_rev) / NULLIF(prev_4wk_rev, 0) * 100, 1)
                                                                        AS vs_4wk_ago_pct,
    ROUND(rolling_4wk_avg, 0)                                           AS rolling_4wk_avg_eur,
    CASE
        WHEN weekly_revenue > rolling_4wk_avg * 1.1  THEN 'Accelerating'
        WHEN weekly_revenue > rolling_4wk_avg * 0.9  THEN 'Stable'
        ELSE                                               'Decelerating'
    END AS momentum_flag
FROM weekly_momentum
WHERE week_start >= '2015-01-01'  -- Focus on most recent period
ORDER BY store, week_start;


-- =============================================================================
-- QUERY 10 | ANOMALY DETECTION — ABNORMAL SALES BEHAVIOR FLAGGING
-- Business Question: Which stores show statistically unusual sales patterns?
-- Purpose: Fraud detection, data quality audit, operational issue identification
-- Technique: Z-score calculation using window functions
-- =============================================================================
WITH store_stats AS (
    SELECT
        store,
        AVG(sales)    AS mean_sales,
        STDDEV(sales) AS std_sales
    FROM sales
    WHERE open = 1
    GROUP BY store
),
daily_zscore AS (
    SELECT
        s.store,
        s.date,
        s.sales,
        st.mean_sales,
        st.std_sales,
        ROUND((s.sales - st.mean_sales) / NULLIF(st.std_sales, 0), 3) AS z_score
    FROM sales s
    JOIN store_stats st ON s.store = st.store
    WHERE s.open = 1
),
anomaly_counts AS (
    SELECT
        store,
        COUNT(*) FILTER (WHERE ABS(z_score) > 3)    AS extreme_anomaly_days,   -- >3σ
        COUNT(*) FILTER (WHERE ABS(z_score) > 2)    AS moderate_anomaly_days,  -- >2σ
        COUNT(*)                                     AS total_open_days,
        ROUND(AVG(z_score), 3)                       AS mean_z,
        ROUND(MAX(z_score), 3)                       AS max_z,
        ROUND(MIN(z_score), 3)                       AS min_z
    FROM daily_zscore
    GROUP BY store
)
SELECT
    a.store,
    a.extreme_anomaly_days,
    a.moderate_anomaly_days,
    ROUND(a.extreme_anomaly_days::NUMERIC / a.total_open_days * 100, 2) AS anomaly_rate_pct,
    a.mean_z,
    a.max_z AS highest_spike_z,
    a.min_z AS deepest_drop_z,
    s.storetype,
    s.assortment,
    CASE
        WHEN a.extreme_anomaly_days > 20   THEN 'HIGH RISK — Audit Required'
        WHEN a.extreme_anomaly_days > 10   THEN 'MEDIUM — Investigate'
        WHEN a.extreme_anomaly_days > 5    THEN 'LOW — Monitor'
        ELSE                                    'NORMAL'
    END AS anomaly_risk_flag
FROM anomaly_counts a
JOIN stores s ON a.store = s.store
WHERE a.extreme_anomaly_days > 5
ORDER BY a.extreme_anomaly_days DESC;


-- =============================================================================
-- QUERY 11 | EXPANSION OPPORTUNITY SCORING — INVESTMENT PRIORITIZATION
-- Business Question: Which stores should be prioritized for expansion/renovation investment?
-- Purpose: CapEx budget allocation for next fiscal year
-- Technique: Composite weighted scoring model
-- =============================================================================
WITH store_performance AS (
    SELECT
        s.store,
        AVG(s.sales)                                                  AS avg_daily_sales,
        AVG(s.customers)                                              AS avg_daily_customers,
        ROUND(AVG(s.sales / NULLIF(s.customers, 0)), 2)              AS avg_basket_size,
        -- YoY Growth
        AVG(s.sales) FILTER (WHERE EXTRACT(YEAR FROM s.date) = 2014)
          / NULLIF(AVG(s.sales) FILTER (WHERE EXTRACT(YEAR FROM s.date) = 2013), 0) - 1
                                                                      AS yoy_growth_2014,
        -- Promo uplift (higher = more responsive to investment in marketing)
        AVG(s.sales) FILTER (WHERE s.promo = 1)
          / NULLIF(AVG(s.sales) FILTER (WHERE s.promo = 0), 0) - 1   AS promo_uplift_ratio
    FROM sales s
    WHERE s.open = 1
    GROUP BY s.store
),
scored AS (
    SELECT
        p.store,
        p.avg_daily_sales,
        p.avg_daily_customers,
        p.avg_basket_size,
        p.yoy_growth_2014,
        p.promo_uplift_ratio,
        st.storetype,
        st.assortment,
        st.competitiondistance,
        -- Weighted scoring (weights reflect business priority)
        ROUND(
            PERCENT_RANK() OVER (ORDER BY p.avg_daily_sales) * 0.30      -- 30% Revenue base
          + PERCENT_RANK() OVER (ORDER BY p.yoy_growth_2014) * 0.35      -- 35% Growth momentum
          + PERCENT_RANK() OVER (ORDER BY p.promo_uplift_ratio) * 0.20   -- 20% Promo responsiveness
          + PERCENT_RANK() OVER (ORDER BY p.avg_basket_size) * 0.15      -- 15% Customer value
        , 4) AS expansion_score
    FROM store_performance p
    JOIN stores st ON p.store = st.store
    WHERE p.yoy_growth_2014 IS NOT NULL
)
SELECT
    store,
    ROUND(avg_daily_sales, 2)        AS avg_daily_sales_eur,
    ROUND(yoy_growth_2014 * 100, 1)  AS yoy_growth_pct,
    ROUND(promo_uplift_ratio * 100, 1) AS promo_uplift_pct,
    ROUND(avg_basket_size, 2)        AS avg_basket_size_eur,
    expansion_score,
    storetype,
    assortment,
    ROUND(competitiondistance, 0)    AS competition_dist_m,
    DENSE_RANK() OVER (ORDER BY expansion_score DESC) AS expansion_priority_rank,
    CASE
        WHEN expansion_score >= 0.80 THEN 'PRIORITY 1 — Expand Now'
        WHEN expansion_score >= 0.65 THEN 'PRIORITY 2 — Plan for Next FY'
        WHEN expansion_score >= 0.50 THEN 'PRIORITY 3 — Monitor Pipeline'
        ELSE 'NOT RECOMMENDED — Stabilize First'
    END AS recommendation
FROM scored
ORDER BY expansion_score DESC
LIMIT 40;


-- =============================================================================
-- QUERY 12 | PROMO2 (CONTINUOUS PROMOTION) EFFECTIVENESS
-- Business Question: Do stores running Promo2 (sustained campaigns) outperform single-day promo stores?
-- Purpose: Long-term promotional strategy assessment
-- =============================================================================
WITH promo2_analysis AS (
    SELECT
        st.store,
        st.promo2,
        st.storetype,
        st.assortment,
        AVG(s.sales)                                    AS avg_daily_sales,
        AVG(s.customers)                                AS avg_daily_customers,
        AVG(s.sales / NULLIF(s.customers, 0))           AS avg_basket_size,
        COUNT(*)                                        AS open_days
    FROM stores st
    JOIN sales s ON st.store = s.store
    WHERE s.open = 1
    GROUP BY st.store, st.promo2, st.storetype, st.assortment
)
SELECT
    promo2,
    CASE promo2 WHEN 1 THEN 'Promo2 Active' ELSE 'No Promo2' END AS promo2_label,
    storetype,
    COUNT(DISTINCT store)                    AS store_count,
    ROUND(AVG(avg_daily_sales), 2)           AS avg_daily_sales_eur,
    ROUND(AVG(avg_daily_customers), 0)       AS avg_daily_customers,
    ROUND(AVG(avg_basket_size), 2)           AS avg_basket_size_eur,
    ROUND(
        AVG(avg_daily_sales) FILTER (WHERE promo2 = 1)
        / NULLIF(AVG(avg_daily_sales) FILTER (WHERE promo2 = 0), 0) * 100 - 100
        OVER (PARTITION BY storetype)
    , 1)                                     AS promo2_lift_pct_by_type
FROM promo2_analysis
GROUP BY promo2, storetype
ORDER BY storetype, promo2 DESC;


-- =============================================================================
-- QUERY 13 | CUSTOMER BASKET TREND ANALYSIS — REVENUE QUALITY
-- Business Question: Is revenue growth driven by more customers or higher spend per visit?
-- Purpose: Revenue quality decomposition for strategic planning
-- Technique: LEAD/LAG for trend analysis + decomposition
-- =============================================================================
WITH monthly_kpis AS (
    SELECT
        DATE_TRUNC('month', date)              AS month,
        EXTRACT(YEAR FROM date)                AS year_num,
        EXTRACT(MONTH FROM date)               AS month_num,
        SUM(sales)                             AS total_revenue,
        SUM(customers)                         AS total_customers,
        COUNT(DISTINCT store)                  AS active_stores,
        ROUND(AVG(sales / NULLIF(customers, 0)), 2) AS avg_basket_size
    FROM sales
    WHERE open = 1 AND customers > 0
    GROUP BY DATE_TRUNC('month', date), EXTRACT(YEAR FROM date), EXTRACT(MONTH FROM date)
),
trend AS (
    SELECT
        month,
        total_revenue,
        total_customers,
        avg_basket_size,
        active_stores,
        LAG(total_revenue)   OVER (ORDER BY month) AS prev_month_revenue,
        LAG(total_customers) OVER (ORDER BY month) AS prev_month_customers,
        LAG(avg_basket_size) OVER (ORDER BY month) AS prev_basket_size
    FROM monthly_kpis
)
SELECT
    TO_CHAR(month, 'YYYY-MM')                                          AS period,
    total_revenue,
    total_customers,
    avg_basket_size,
    ROUND((total_revenue - prev_month_revenue)
        / NULLIF(prev_month_revenue, 0) * 100, 1)                     AS revenue_mom_pct,
    ROUND((total_customers - prev_month_customers)
        / NULLIF(prev_month_customers, 0) * 100, 1)                   AS customer_volume_mom_pct,
    ROUND((avg_basket_size - prev_basket_size)
        / NULLIF(prev_basket_size, 0) * 100, 1)                       AS basket_size_mom_pct,
    -- Revenue decomposition: which component is driving growth?
    CASE
        WHEN (total_customers - prev_month_customers) / NULLIF(prev_month_customers, 0)
           > (avg_basket_size - prev_basket_size) / NULLIF(prev_basket_size, 0)
        THEN 'Volume-Driven Growth'
        WHEN (avg_basket_size - prev_basket_size) / NULLIF(prev_basket_size, 0) > 0
        THEN 'Basket-Driven Growth'
        ELSE 'Declining / Mixed'
    END AS growth_driver
FROM trend
WHERE month IS NOT NULL
ORDER BY month;


-- =============================================================================
-- QUERY 14 | STORE TYPE COMPETITIVE PERFORMANCE MATRIX
-- Business Question: Which store type × assortment combination is most profitable?
-- Purpose: Store format strategy for new openings
-- Technique: Multi-level aggregation + ROW_NUMBER ranking within each type
-- =============================================================================
WITH combination_metrics AS (
    SELECT
        st.storetype,
        st.assortment,
        COUNT(DISTINCT s.store)                         AS store_count,
        ROUND(AVG(s.sales), 2)                          AS avg_daily_sales,
        ROUND(AVG(s.customers), 0)                      AS avg_daily_customers,
        ROUND(AVG(s.sales / NULLIF(s.customers, 0)), 2) AS avg_basket_size,
        ROUND(AVG(s.sales) FILTER (WHERE s.promo = 1)
            / NULLIF(AVG(s.sales) FILTER (WHERE s.promo = 0), 0), 3)
                                                        AS promo_multiplier
    FROM sales s
    JOIN stores st ON s.store = st.store
    WHERE s.open = 1
    GROUP BY st.storetype, st.assortment
)
SELECT
    storetype,
    assortment,
    CASE assortment
        WHEN 'a' THEN 'Basic'
        WHEN 'b' THEN 'Extra'
        WHEN 'c' THEN 'Extended'
    END AS assortment_label,
    store_count,
    avg_daily_sales,
    avg_daily_customers,
    avg_basket_size,
    promo_multiplier,
    ROW_NUMBER() OVER (ORDER BY avg_daily_sales DESC)                AS overall_rank,
    ROW_NUMBER() OVER (PARTITION BY storetype ORDER BY avg_daily_sales DESC) AS rank_within_type,
    ROUND(avg_daily_sales / SUM(avg_daily_sales) OVER () * 100, 2)  AS pct_of_total_avg_sales
FROM combination_metrics
ORDER BY avg_daily_sales DESC;


-- =============================================================================
-- QUERY 15 | COHORT ANALYSIS — STORE AGE vs. COMPETITION ENTRY IMPACT
-- Business Question: How does our store performance change when a competitor opens nearby?
-- Purpose: Competitive response playbook + defensive investment triggers
-- Technique: LAG + date arithmetic to measure pre/post competitor entry performance
-- =============================================================================
WITH stores_with_competition AS (
    SELECT
        store,
        storetype,
        assortment,
        competitiondistance,
        -- Build approximate competitor opening date
        CASE
            WHEN competitionopensincemonth IS NOT NULL
             AND competitionopensinceyear IS NOT NULL
            THEN MAKE_DATE(
                    competitionopensinceyear::INT,
                    competitionopensincemonth::INT,
                    1
                )
            ELSE NULL
        END AS competitor_open_date
    FROM stores
    WHERE competitionopensinceyear IS NOT NULL
      AND competitiondistance <= 3000  -- Focus on close competitors
),
sales_with_competitor_timing AS (
    SELECT
        s.store,
        s.date,
        s.sales,
        s.customers,
        sc.competitor_open_date,
        sc.competitiondistance,
        sc.storetype,
        CASE
            WHEN s.date < sc.competitor_open_date - INTERVAL '6 months'
            THEN 'Pre-Competition (>6m before)'
            WHEN s.date < sc.competitor_open_date
            THEN 'Pre-Competition (<6m before)'
            WHEN s.date < sc.competitor_open_date + INTERVAL '6 months'
            THEN 'Post-Competition (<6m after)'
            ELSE 'Post-Competition (>6m after)'
        END AS competition_phase
    FROM sales s
    JOIN stores_with_competition sc ON s.store = sc.store
    WHERE s.open = 1
)
SELECT
    competition_phase,
    COUNT(DISTINCT store)               AS stores_in_phase,
    ROUND(AVG(sales), 2)               AS avg_daily_sales_eur,
    ROUND(AVG(customers), 0)           AS avg_daily_customers,
    ROUND(AVG(sales / NULLIF(customers, 0)), 2) AS avg_basket_size,
    COUNT(*)                            AS observation_days
FROM sales_with_competitor_timing
GROUP BY competition_phase
ORDER BY
    CASE competition_phase
        WHEN 'Pre-Competition (>6m before)'  THEN 1
        WHEN 'Pre-Competition (<6m before)'  THEN 2
        WHEN 'Post-Competition (<6m after)'  THEN 3
        WHEN 'Post-Competition (>6m after)'  THEN 4
    END;