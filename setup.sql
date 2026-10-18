-- OFFER READY: The Data Analyst Interview Playbook
-- setup.sql — creates and populates every table the SQL examples read.
--
-- Run this FIRST, then run offer_ready_sql.sql. With DuckDB:
--     duckdb offer_ready.duckdb < setup.sql
--     duckdb offer_ready.duckdb < offer_ready_sql.sql
--
-- The data is deliberately small and deliberately messy: there are duplicate
-- emails, a login streak, a month with no growth, and a user who bought without
-- ever adding to cart. Every example returns rows — several return rows that
-- are worth arguing about, which is the point of the book.

DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS user_activity;
DROP TABLE IF EXISTS daily_sales;
DROP TABLE IF EXISTS events;
DROP TABLE IF EXISTS user_registrations;
DROP TABLE IF EXISTS user_logs;

-- ─────────────────────────────────────────────────────────────────────────────
-- orders
-- Examples 1, 5 and 30 each read `orders` with a different set of columns, so
-- this table carries all of them. order_amount/amount and status/order_status
-- are kept as separate columns on purpose: the examples are printed in the book
-- exactly as they appear here, and the data bends to the code rather than the
-- other way round.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE orders (
    order_id       INTEGER,
    customer_id    INTEGER,
    user_id        INTEGER,
    order_date     DATE,
    order_amount   DECIMAL(10, 2),
    amount         DECIMAL(10, 2),
    status         VARCHAR,
    order_status   VARCHAR,
    payment_method VARCHAR
);

INSERT INTO orders (order_id, customer_id, user_id, order_date, order_amount, amount, status, order_status, payment_method) VALUES
    (1001, 1, 1, DATE '2024-01-08',  120.00, 120.00, 'Completed', 'Completed', 'Card'),
    (1002, 1, 1, DATE '2024-01-22',   89.50,  89.50, 'Completed', 'Completed', 'Card'),
    (1003, 1, 1, DATE '2024-02-03',  240.00, 240.00, 'Completed', 'Completed', 'UPI'),
    (1004, 1, 1, DATE '2024-02-19',   45.00,  45.00, 'Refunded',  'Refunded',  'Card'),
    (1005, 1, 1, DATE '2024-03-07',  310.00, 310.00, 'Completed', 'Completed', 'Card'),
    (1006, 1, 1, DATE '2024-03-28',   75.25,  75.25, 'Completed', 'Completed', 'Wallet'),
    (1007, 2, 2, DATE '2024-01-14',  560.00, 560.00, 'Completed', 'Completed', 'Card'),
    (1008, 2, 2, DATE '2024-02-02',  410.00, 410.00, 'Completed', 'Completed', 'Card'),
    (1009, 2, 2, DATE '2024-02-26',  130.00, 130.00, 'Refunded',  'Refunded',  'UPI'),
    (1010, 2, 2, DATE '2024-03-11',  295.00, 295.00, 'Completed', 'Completed', 'UPI'),
    (1011, 2, 2, DATE '2024-03-30',  180.00, 180.00, 'Completed', 'Completed', 'Card'),
    (1012, 3, 3, DATE '2024-01-19',   60.00,  60.00, 'Completed', 'Completed', 'Wallet'),
    (1013, 3, 3, DATE '2024-02-14',   95.00,  95.00, 'Refunded',  'Refunded',  'Wallet'),
    (1014, 3, 3, DATE '2024-03-02',   48.00,  48.00, 'Completed', 'Completed', 'Wallet'),
    (1015, 4, 4, DATE '2024-02-08', 1250.00,1250.00, 'Completed', 'Completed', 'Card'),
    (1016, 4, 4, DATE '2024-03-15',  980.00, 980.00, 'Completed', 'Completed', 'Card'),
    (1017, 5, 5, DATE '2023-11-30',  220.00, 220.00, 'Completed', 'Completed', 'UPI'),
    (1018, 5, 5, DATE '2023-12-21',  175.00, 175.00, 'Completed', 'Completed', 'UPI'),
    (1019, 5, 5, DATE '2024-01-05',  140.00, 140.00, 'Completed', 'Completed', 'UPI'),
    (1020, 6, 6, DATE '2024-03-21',   32.00,  32.00, 'Pending',   'Pending',   'Wallet');

-- ─────────────────────────────────────────────────────────────────────────────
-- transactions  (Example 2 — average monthly spend per user)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE transactions (
    transaction_id INTEGER,
    user_id        INTEGER,
    order_date     DATE,
    amount         DECIMAL(10, 2)
);

INSERT INTO transactions VALUES
    (1, 1, DATE '2024-01-08', 120.00), (2, 1, DATE '2024-01-22',  89.50),
    (3, 1, DATE '2024-02-03', 240.00), (4, 1, DATE '2024-03-07', 310.00),
    (5, 2, DATE '2024-01-14', 560.00), (6, 2, DATE '2024-02-02', 410.00),
    (7, 2, DATE '2024-02-26', 130.00), (8, 2, DATE '2024-03-11', 295.00),
    (9, 3, DATE '2024-01-19',  60.00), (10, 3, DATE '2024-02-14', 95.00),
    (11, 3, DATE '2024-03-02', 48.00), (12, 4, DATE '2024-02-08',1250.00),
    (13, 4, DATE '2024-03-15', 980.00), (14, 5, DATE '2024-01-05',140.00);

-- ─────────────────────────────────────────────────────────────────────────────
-- employees  (Examples 3 and 7 — DENSE_RANK with deliberate ties)
-- Department 10 has a tie at the top, so rank 1 returns two rows and rank 2
-- returns the third salary. That difference between DENSE_RANK, RANK and
-- ROW_NUMBER is the thing interviewers actually probe.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE employees (
    employee_id   INTEGER,
    department_id INTEGER,
    salary        DECIMAL(10, 2)
);

INSERT INTO employees VALUES
    (1, 10, 120000), (2, 10, 120000), (3, 10, 95000), (4, 10, 88000),
    (5, 20,  80000), (6, 20,  80000), (7, 20, 60000),
    (8, 30, 150000), (9, 30, 132000), (10, 30, 132000), (11, 30, 99000);

-- ─────────────────────────────────────────────────────────────────────────────
-- payments  (Example 4 — month-over-month growth; February dips on purpose)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE payments (
    payment_id   INTEGER,
    payment_date DATE,
    amount       DECIMAL(10, 2)
);

INSERT INTO payments VALUES
    (1, DATE '2023-11-04',  8200.00), (2, DATE '2023-11-21',  5400.00),
    (3, DATE '2023-12-02', 11900.00), (4, DATE '2023-12-19',  7600.00),
    (5, DATE '2024-01-07', 13400.00), (6, DATE '2024-01-25',  6100.00),
    (7, DATE '2024-02-09', 12200.00), (8, DATE '2024-02-23',  4300.00),
    (9, DATE '2024-03-05', 15800.00), (10, DATE '2024-03-27',  9050.00);

-- ─────────────────────────────────────────────────────────────────────────────
-- users  (Example 6 — duplicate emails)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE users (
    user_id INTEGER,
    email   VARCHAR
);

INSERT INTO users VALUES
    (1, 'alice@co.com'), (2, 'bob@co.com'),   (3, 'bob@co.com'),
    (4, 'carol@co.com'), (5, 'dan@co.com'),   (6, 'dan@co.com'),
    (7, 'dan@co.com'),   (8, 'erin@co.com');

-- ─────────────────────────────────────────────────────────────────────────────
-- user_activity  (Example 8 — monthly retention)
-- User 1 is active every month, user 2 lapses and returns, user 5 appears only
-- in March, so the retention rate is neither 0% nor 100% in any month.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE user_activity (
    user_id       INTEGER,
    activity_date DATE
);

INSERT INTO user_activity VALUES
    (1, DATE '2024-01-05'), (1, DATE '2024-01-26'), (1, DATE '2024-02-11'),
    (1, DATE '2024-03-03'),
    (2, DATE '2024-01-15'), (2, DATE '2024-02-20'), (2, DATE '2024-02-28'),
    (3, DATE '2024-01-10'), (3, DATE '2024-03-18'),
    (4, DATE '2024-02-06'), (4, DATE '2024-03-09'),
    (5, DATE '2024-03-22'),
    (6, DATE '2024-01-30'), (6, DATE '2024-02-14'), (6, DATE '2024-03-27');

-- ─────────────────────────────────────────────────────────────────────────────
-- daily_sales  (Examples 9 — running total and 7-day moving average)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE daily_sales (
    transaction_date DATE,
    revenue          DECIMAL(10, 2)
);

INSERT INTO daily_sales VALUES
    (DATE '2024-03-01', 100.00), (DATE '2024-03-02', 120.00),
    (DATE '2024-03-03',  90.00), (DATE '2024-03-04', 150.00),
    (DATE '2024-03-05', 200.00), (DATE '2024-03-06', 175.00),
    (DATE '2024-03-07', 160.00), (DATE '2024-03-08', 140.00),
    (DATE '2024-03-09', 130.00), (DATE '2024-03-10', 190.00),
    (DATE '2024-03-11', 210.00), (DATE '2024-03-12', 185.00),
    (DATE '2024-03-13', 165.00), (DATE '2024-03-14', 230.00);

-- ─────────────────────────────────────────────────────────────────────────────
-- events  (Example 10 and the ordered funnel)
-- User 104 purchased without ever adding to cart, and user 105 added to cart
-- BEFORE viewing. The naive funnel counts them; the ordered funnel does not.
-- That gap between the two queries is the lesson.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE events (
    event_id   INTEGER,
    user_id    INTEGER,
    event_name VARCHAR,
    event_time TIMESTAMP
);

INSERT INTO events VALUES
    (1,  101, 'viewed_item',   TIMESTAMP '2024-03-01 09:00:00'),
    (2,  101, 'added_to_cart', TIMESTAMP '2024-03-01 09:04:00'),
    (3,  101, 'purchased',     TIMESTAMP '2024-03-01 09:11:00'),
    (4,  102, 'viewed_item',   TIMESTAMP '2024-03-01 10:15:00'),
    (5,  102, 'added_to_cart', TIMESTAMP '2024-03-01 10:22:00'),
    (6,  103, 'viewed_item',   TIMESTAMP '2024-03-01 11:40:00'),
    (7,  104, 'viewed_item',   TIMESTAMP '2024-03-02 08:05:00'),
    (8,  104, 'purchased',     TIMESTAMP '2024-03-02 08:09:00'),
    (9,  105, 'added_to_cart', TIMESTAMP '2024-03-02 14:00:00'),
    (10, 105, 'viewed_item',   TIMESTAMP '2024-03-02 14:30:00'),
    (11, 105, 'purchased',     TIMESTAMP '2024-03-02 14:45:00'),
    (12, 106, 'viewed_item',   TIMESTAMP '2024-03-03 16:20:00'),
    (13, 106, 'added_to_cart', TIMESTAMP '2024-03-03 16:31:00'),
    (14, 106, 'purchased',     TIMESTAMP '2024-03-03 16:58:00'),
    (15, 107, 'viewed_item',   TIMESTAMP '2024-03-03 18:02:00');

-- ─────────────────────────────────────────────────────────────────────────────
-- user_registrations  (Example 28 — de-duplication, keep earliest)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE user_registrations (
    registration_id INTEGER,
    email_address   VARCHAR,
    created_at      TIMESTAMP
);

INSERT INTO user_registrations VALUES
    (1, 'alice@co.com', TIMESTAMP '2024-01-04 10:00:00'),
    (2, 'bob@co.com',   TIMESTAMP '2024-01-06 11:30:00'),
    (3, 'bob@co.com',   TIMESTAMP '2024-02-02 09:15:00'),
    (4, 'carol@co.com', TIMESTAMP '2024-01-11 14:45:00'),
    (5, 'dan@co.com',   TIMESTAMP '2024-01-19 08:05:00'),
    (6, 'dan@co.com',   TIMESTAMP '2024-01-19 08:06:00'),
    (7, 'dan@co.com',   TIMESTAMP '2024-03-01 17:40:00'),
    (8, 'erin@co.com',  TIMESTAMP '2024-02-27 12:00:00');

-- ─────────────────────────────────────────────────────────────────────────────
-- user_logs  (Example 29 — consecutive-day login streaks)
-- User 1 has a 5-day streak, user 2 a 3-day streak with a duplicate login on
-- one day, user 3 never reaches three in a row.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE user_logs (
    log_id          INTEGER,
    user_id         INTEGER,
    login_timestamp TIMESTAMP
);

INSERT INTO user_logs VALUES
    (1,  1, TIMESTAMP '2024-03-01 08:12:00'),
    (2,  1, TIMESTAMP '2024-03-02 09:40:00'),
    (3,  1, TIMESTAMP '2024-03-03 20:05:00'),
    (4,  1, TIMESTAMP '2024-03-04 07:55:00'),
    (5,  1, TIMESTAMP '2024-03-05 21:30:00'),
    (6,  1, TIMESTAMP '2024-03-09 10:00:00'),
    (7,  2, TIMESTAMP '2024-03-02 11:00:00'),
    (8,  2, TIMESTAMP '2024-03-02 19:20:00'),
    (9,  2, TIMESTAMP '2024-03-03 12:10:00'),
    (10, 2, TIMESTAMP '2024-03-04 13:45:00'),
    (11, 3, TIMESTAMP '2024-03-01 15:00:00'),
    (12, 3, TIMESTAMP '2024-03-03 16:00:00'),
    (13, 3, TIMESTAMP '2024-03-06 17:00:00');
