-- OFFER READY: The Data Analyst Interview Playbook
-- All SQL examples (PostgreSQL-style syntax, tested in DuckDB)
--
-- Run setup.sql first — it creates and fills every table used below:
--     duckdb offer_ready.duckdb < setup.sql
--     duckdb offer_ready.duckdb < offer_ready_sql.sql
--
-- The queries below are exactly as printed in the book.

-- ── Example 1 ──
-- Correct usage: finding high-value customers with 5+ orders post-2023
SELECT
    customer_id,
    COUNT(order_id) AS total_orders,
    SUM(order_amount) AS total_spend
FROM orders
WHERE order_date >= '2024-01-01'   -- row-level filter BEFORE grouping
GROUP BY customer_id
HAVING COUNT(order_id) >= 5         -- aggregate-level filter AFTER grouping
ORDER BY total_spend DESC;

-- ── Example 2 ──
-- CTE pattern: calculating average user monthly spend
WITH monthly_user_spend AS (
    SELECT
        user_id,
        DATE_TRUNC('month', order_date) AS order_month,
        SUM(amount) AS monthly_total
    FROM transactions
    GROUP BY 1, 2
)
SELECT
    order_month,
    AVG(monthly_total) AS avg_customer_spend
FROM monthly_user_spend
GROUP BY 1
ORDER BY 1 ASC;

-- ── Example 3 ──
-- Goal: find the highest-paid employee in EACH department
WITH ranked_salaries AS (
    SELECT
        employee_id,
        department_id,
        salary,
        DENSE_RANK() OVER (
            PARTITION BY department_id
            ORDER BY salary DESC
        ) AS salary_rank
    FROM employees
)
SELECT department_id, employee_id, salary
FROM ranked_salaries
WHERE salary_rank = 1;

-- ── Example 4 ──
-- Goal: calculate month-over-month (MoM) revenue growth
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', payment_date) AS month,
        SUM(amount) AS current_month_revenue
    FROM payments
    GROUP BY 1
)
SELECT
    month,
    current_month_revenue,
    LAG(current_month_revenue, 1) OVER (ORDER BY month) AS prev_month_revenue,
    ROUND(
        100.0 * (current_month_revenue - LAG(current_month_revenue, 1) OVER (ORDER BY month))
        / NULLIF(LAG(current_month_revenue, 1) OVER (ORDER BY month), 0), 2
    ) AS mom_growth_percentage
FROM monthly_revenue;

-- ── Example 5 ──
-- Goal: summarize order statuses by payment method in one view
SELECT
    payment_method,
    COUNT(order_id) AS total_orders,
    SUM(CASE WHEN status = 'Completed' THEN 1 ELSE 0 END) AS completed_orders,
    SUM(CASE WHEN status = 'Refunded' THEN 1 ELSE 0 END) AS refunded_orders,
    ROUND(
        100.0 * SUM(CASE WHEN status = 'Refunded' THEN 1 ELSE 0 END) / COUNT(order_id), 2
    ) AS refund_rate
FROM orders
GROUP BY payment_method;

-- ── Example 6 ──
SELECT email, COUNT(*)
FROM users
GROUP BY email
HAVING COUNT(*) > 1;

-- ── Example 7 ──
WITH ranked_salaries AS (
    SELECT
        employee_id,
        department_id,
        salary,
        DENSE_RANK() OVER (
            PARTITION BY department_id
            ORDER BY salary DESC
        ) AS salary_rank
    FROM employees
)
SELECT
    department_id,
    employee_id,
    salary
FROM ranked_salaries
WHERE salary_rank = 2;

-- ── Example 8 ──
WITH monthly_active_users AS (
    -- Step 1: one row per active user per month
    SELECT DISTINCT
        user_id,
        DATE_TRUNC('month', activity_date) AS active_month
    FROM user_activity
),
monthly_counts AS (
    SELECT
        active_month,
        COUNT(DISTINCT user_id) AS active_users
    FROM monthly_active_users
    GROUP BY 1
),
retained_users AS (
    -- Step 2: users active in both the current and prior calendar month
    SELECT
        curr.active_month AS current_month,
        COUNT(DISTINCT curr.user_id) AS retained_from_prev_month
    FROM monthly_active_users curr
    INNER JOIN monthly_active_users prev
        ON  curr.user_id = prev.user_id
        AND prev.active_month = curr.active_month - INTERVAL '1 month'
    GROUP BY 1
)
SELECT
    mc.active_month AS current_month,
    mc.active_users,
    COALESCE(ru.retained_from_prev_month, 0) AS retained_from_prev_month,
    ROUND(
        100.0 * COALESCE(ru.retained_from_prev_month, 0)
        / NULLIF(prev_mc.active_users, 0),
        2
    ) AS retention_rate_percentage
FROM monthly_counts mc
LEFT JOIN retained_users ru
    ON mc.active_month = ru.current_month
LEFT JOIN monthly_counts prev_mc
    ON prev_mc.active_month = mc.active_month - INTERVAL '1 month'
ORDER BY mc.active_month ASC;

-- ── Example 9 ──
SELECT
    transaction_date,
    revenue,
    -- Cumulative running total from the start of the dataset
    SUM(revenue) OVER (
        ORDER BY transaction_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_revenue,
    -- 7-day moving average
    ROUND(
        AVG(revenue) OVER (
            ORDER BY transaction_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ), 2
    ) AS rolling_avg_7day
FROM daily_sales
ORDER BY transaction_date ASC;

-- ── Example 10 ──
WITH funnel AS (
    SELECT
        user_id,
        MAX(CASE WHEN event_name = 'viewed_item'    THEN 1 ELSE 0 END) AS viewed,
        MAX(CASE WHEN event_name = 'added_to_cart'  THEN 1 ELSE 0 END) AS added_cart,
        MAX(CASE WHEN event_name = 'purchased'      THEN 1 ELSE 0 END) AS purchased
    FROM events
    GROUP BY user_id
)
SELECT
    SUM(viewed)     AS step1_viewed,
    SUM(added_cart) AS step2_added_cart,
    SUM(purchased)  AS step3_purchased,
    ROUND(100.0 * SUM(added_cart) / NULLIF(SUM(viewed), 0), 2)
        AS view_to_cart_pct,
    ROUND(100.0 * SUM(purchased) / NULLIF(SUM(added_cart), 0), 2)
        AS cart_to_purchase_pct
FROM funnel;

-- ── Ordered funnel ──
-- Ordered funnel: counts a step only if it happened AFTER the previous step
WITH first_times AS (
    SELECT
        user_id,
        MIN(CASE WHEN event_name = 'viewed_item'   THEN event_time END) AS t_view,
        MIN(CASE WHEN event_name = 'added_to_cart' THEN event_time END) AS t_cart,
        MIN(CASE WHEN event_name = 'purchased'     THEN event_time END) AS t_buy
    FROM events
    GROUP BY user_id
)
SELECT
    COUNT(t_view)                                                  AS step1_viewed,
    COUNT(CASE WHEN t_cart >= t_view THEN 1 END)                   AS step2_added_cart,
    COUNT(CASE WHEN t_buy >= t_cart AND t_cart >= t_view THEN 1 END) AS step3_purchased
FROM first_times;

-- ── Example 28 ──
-- Step 1: identify duplicate records
SELECT
    email_address,
    COUNT(*) AS record_count
FROM user_registrations
GROUP BY email_address
HAVING COUNT(*) > 1;
-- Step 2: keep only the earliest record per user
WITH DeduplicatedUsers AS (
    SELECT
        registration_id,
        email_address,
        created_at,
        ROW_NUMBER() OVER (
            PARTITION BY email_address
            ORDER BY created_at ASC
        ) AS row_num
    FROM user_registrations
)
SELECT
    registration_id,
    email_address,
    created_at
FROM DeduplicatedUsers
WHERE row_num = 1;

-- ── Example 29 ──
WITH DistinctLogins AS (
    SELECT DISTINCT
        user_id,
        CAST(login_timestamp AS DATE) AS login_date
    FROM user_logs
),
GroupedLogins AS (
    SELECT
        user_id,
        login_date,
        login_date - (
            ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY login_date) * INTERVAL '1 day'
        ) AS streak_group
    FROM DistinctLogins
)
SELECT
    user_id,
    MIN(login_date) AS streak_start,
    MAX(login_date) AS streak_end,
    COUNT(*) AS consecutive_days_count
FROM GroupedLogins
GROUP BY user_id, streak_group
HAVING COUNT(*) >= 3
ORDER BY consecutive_days_count DESC;

-- ── Example 30 ──
SELECT
    user_id,
    COUNT(order_id) AS total_orders,
    SUM(CASE WHEN order_status = 'Completed' THEN amount ELSE 0 END) AS completed_spend,
    SUM(CASE WHEN order_status = 'Refunded'  THEN amount ELSE 0 END) AS refunded_spend,
    ROUND(
        100.0 * SUM(CASE WHEN order_status = 'Refunded' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(order_id), 0),
        2
    ) AS refund_rate_pct
FROM orders
GROUP BY user_id;
