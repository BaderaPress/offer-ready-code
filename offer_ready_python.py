# OFFER READY: The Data Analyst Interview Playbook
# All Python & pandas examples (tested with pandas 2.2 and 3.0)
#
# Run it straight through:   python3 offer_ready_python.py
#
# The example code is exactly as printed in the book. Blocks marked SETUP are
# not in the book — they build the small sample frames the examples read, so
# the file runs end to end instead of stopping at the first missing column.
import pandas as pd
import numpy as np
from scipy import stats

# ── Example 11 ──
import pandas as pd
df = pd.DataFrame({
    "email": [" Alice@Co.com", "bob@co.com", "bob@co.com", None],
    "signup_date": ["2024-01-05", "2024/02/10", "2024-03-01", "2024-04-01"],
    "revenue": ["1,200", "950", "N/A", "3000"],
})
# 1. Normalize text fields: strip whitespace, standardize case
df["email"] = df["email"].str.strip().str.lower()
# 2. Coerce inconsistent date formats; invalid values become NaT, not a crash
df["signup_date"] = pd.to_datetime(df["signup_date"], format="mixed", errors="coerce")
# 3. Strip formatting characters, then coerce to numeric
df["revenue"] = pd.to_numeric(
    df["revenue"].str.replace(",", "", regex=False), errors="coerce"
)
# 4. Audit what's missing before deciding how to handle it
print(df.isna().sum())
print(df.duplicated(subset="email").sum())

# ── Example 11b · Audit the coercion (Chapter 3) ──
import pandas as pd

raw = pd.DataFrame({
    "signup_date": ["2024-01-05", "2024-02-10", "not provided", None],
    "revenue":     ["1,200", "950", "N/A", "3,400"],
})
dates = pd.to_datetime(raw["signup_date"], format="mixed", errors="coerce")
revenue = pd.to_numeric(raw["revenue"].str.replace(",", "", regex=False),
                        errors="coerce")

# Nulls that coercion CREATED: the raw value existed but failed to parse
failed_dates = raw.loc[dates.isna() & raw["signup_date"].notna(), "signup_date"]
failed_revenue = raw.loc[revenue.isna() & raw["revenue"].notna(), "revenue"]
print(failed_dates.tolist())     # -> ['not provided']
print(failed_revenue.tolist())   # -> ['N/A']
# Now decide, and say out loud: drop, impute, or flag these rows?

# ── Example 12 ──
orders = pd.DataFrame({
    "customer_id": [1, 1, 2, 2, 2, 3],
    "order_id":    [100, 101, 102, 103, 104, 105],
    "order_amount":[50, 30, 20, 40, 10, 60],
})
summary = (
    orders.groupby("customer_id")
    .agg(
        total_orders=("order_id", "count"),
        total_spend=("order_amount", "sum"),
    )
    .query("total_orders >= 2")             # pandas equivalent of HAVING
    .sort_values("total_spend", ascending=False)
    .reset_index()
)
print(summary)

# ── Example 13 ──
customers = pd.DataFrame({"customer_id": [1, 2, 3], "name": ["A", "B", "C"]})
orders    = pd.DataFrame({"customer_id": [1, 1, 2, 4], "amount": [10, 20, 30, 40]})
# LEFT JOIN: keep every customer, even those with zero orders
left = customers.merge(orders, on="customer_id", how="left")
# INNER JOIN: keep only customers who actually have matching orders
inner = customers.merge(orders, on="customer_id", how="inner")
# FULL OUTER JOIN + indicator: reveals unmatched rows on both sides,
# which is the fastest way to debug a broken join key in an interview
outer = customers.merge(orders, on="customer_id", how="outer", indicator=True)
print(outer)

# ── Example 14 ──
sales = pd.DataFrame({
    "region":  ["East", "East", "West", "West"],
    "product": ["A", "B", "A", "B"],
    "rev":     [10, 20, 30, 40],
})
# Wide format: one column per product (like a CASE WHEN pivot in SQL)
wide = sales.pivot_table(
    index="region", columns="product", values="rev",
    aggfunc="sum", fill_value=0,
)
# melt() reverses this: wide back to long/tidy format
long = wide.reset_index().melt(
    id_vars="region", var_name="product", value_name="rev"
)

# ── Example 15 ──
employees = pd.DataFrame({
    "employee_id":   [1, 2, 3, 4, 5, 6],
    "department_id": [10, 10, 10, 20, 20, 20],
    "salary":        [120000, 120000, 95000, 80000, 80000, 60000],
})
employees["salary_rank"] = (
    employees.groupby("department_id")["salary"]
    .rank(method="dense", ascending=False)
)
result = employees.loc[
    employees["salary_rank"] == 2,
    ["department_id", "employee_id", "salary"],
]
print(result)

# ── Example 16 ──
user_activity = pd.DataFrame({
    "user_id": [1, 1, 1, 2, 2, 3, 3, 3],
    "activity_date": pd.to_datetime([
        "2024-01-05", "2024-02-10", "2024-03-01",
        "2024-01-15", "2024-02-20",
        "2024-01-10", "2024-02-05", "2024-03-05",
    ]),
})

# Step 1: one row per user per active month
mau = (
    user_activity
    .assign(active_month=user_activity["activity_date"].dt.to_period("M"))
    .drop_duplicates(["user_id", "active_month"])[["user_id", "active_month"]]
)

# Step 2: shift each user's month forward by one and merge it back onto itself
prev = mau.assign(active_month=mau["active_month"] + 1, retained=1)
merged = mau.merge(prev, on=["user_id", "active_month"], how="left")

retention = (
    merged.groupby("active_month")
    .agg(active_users=("user_id", "nunique"),
         retained_users=("retained", "sum"))
)

# Step 3: denominator = active users in the TRUE prior calendar month
retention["prev_month_active"] = retention["active_users"].reindex(
    retention.index - 1
).to_numpy()
retention["retention_rate_pct"] = (
    100 * retention["retained_users"] / retention["prev_month_active"]
).round(2)
print(retention.reset_index())

# ── Example 17 ──
daily_sales = pd.DataFrame({
    "transaction_date": pd.date_range("2024-01-01", periods=10, freq="D"),
    "revenue": [100, 120, 90, 150, 200, 175, 160, 140, 130, 190],
}).sort_values("transaction_date")
daily_sales["cumulative_revenue"] = daily_sales["revenue"].cumsum()
daily_sales["rolling_avg_7day"] = (
    daily_sales["revenue"].rolling(window=7, min_periods=1).mean().round(2)
)
print(daily_sales)

# ── Example 18 ──
# Resample daily data into weekly totals — the pandas equivalent of
# DATE_TRUNC('week', date) + GROUP BY in SQL
weekly = daily_sales.set_index("transaction_date")["revenue"].resample("W").sum()
# Extract calendar features for seasonality analysis
daily_sales["day_of_week"] = daily_sales["transaction_date"].dt.day_name()
daily_sales["is_weekend"] = daily_sales["transaction_date"].dt.weekday >= 5
# .diff() and .pct_change() replace a manual LAG() subtraction
daily_sales["day_over_day_change"] = daily_sales["revenue"].diff()
daily_sales["day_over_day_pct"] = daily_sales["revenue"].pct_change().round(4)

# ── SETUP for Examples 19-21 (not in the book) ──────────────────────────────
# A profiling frame with the columns the next three examples reach for.
rng = np.random.default_rng(7)
df = pd.DataFrame({
    "region":  rng.choice(["North", "South", "East", "West"], 40, p=[.4, .3, .2, .1]),
    "revenue": rng.integers(50, 5000, 40),
    "orders":  rng.integers(1, 12, 40),
})
products = pd.DataFrame({
    "product_id": range(1, 13),
    "category":   ["Audio"] * 4 + ["Laptops"] * 4 + ["Phones"] * 4,
    "revenue":    [900, 450, 1200, 300, 5400, 7100, 3900, 2600, 2200, 4800, 1500, 3300],
})
customers = pd.DataFrame({
    "customer_id": range(1, 9),
    "total_spend": [1450, 980, 120, 2300, 45, 760, 1990, 210],
})

# ── Example 19 ──
# One-line profiling — always run this before analyzing a new dataset
print(df.describe(include="all"))
print(df.dtypes)
print(df["region"].value_counts(normalize=True))   # class balance / distribution
print(df[["revenue", "orders"]].corr())             # quick correlation matrix

# ── Example 20 ──
top3 = (
    products.sort_values("revenue", ascending=False)
    .groupby("category")
    .head(3)
)

# ── Example 21 ──
import numpy as np
conditions = [
    customers["total_spend"] >= 1000,
    customers["total_spend"] >= 200,
]
choices = ["High", "Medium"]
customers["value_tier"] = np.select(conditions, choices, default="Low")

# ── Example 22 ──
# Bayes' theorem worked with concrete counts (easier to reason about live than symbols)
population = 10_000
base_rate = 0.01          # 1% actually have the condition
sensitivity = 0.95        # P(test positive | has condition)
false_positive_rate = 0.05  # P(test positive | does NOT have condition)
has_condition = population * base_rate
no_condition = population - has_condition
true_positives = has_condition * sensitivity
false_positives = no_condition * false_positive_rate
p_condition_given_positive = true_positives / (true_positives + false_positives)
print(f"P(has condition | positive test) = {p_condition_given_positive:.1%}")
# -> ~16.1%, NOT 95%

# ── Example 23 ──
# Should we launch a promotion that costs $2 per user to send,
# with a 12% chance each recipient converts at $40 profit?
cost_per_user = 2
conversion_rate = 0.12
profit_per_conversion = 40
expected_value_per_user = (conversion_rate * profit_per_conversion) - cost_per_user
print(f"Expected value per user: ${expected_value_per_user:.2f}")
# -> $2.80 per user: positive EV, worth launching (before considering variance/risk)

# ── Example 24 ──
import numpy as np
from scipy import stats
def sample_size_two_proportion(baseline_rate, mde, alpha=0.05, power=0.80):
    """
    Required sample size PER GROUP for a two-proportion z-test.
    baseline_rate: current conversion rate (e.g., 0.10 for 10%)
    mde: absolute minimum detectable effect (e.g., 0.02 for a +2pp lift)
    """
    p1 = baseline_rate
    p2 = baseline_rate + mde
    z_alpha = stats.norm.ppf(1 - alpha / 2)   # two-tailed critical value
    z_beta = stats.norm.ppf(power)
    pooled_p = (p1 + p2) / 2
    numerator = (
        z_alpha * np.sqrt(2 * pooled_p * (1 - pooled_p))
        + z_beta * np.sqrt(p1 * (1 - p1) + p2 * (1 - p2))
    ) ** 2
    n = numerator / (mde ** 2)
    return int(np.ceil(n))
n_per_group = sample_size_two_proportion(baseline_rate=0.10, mde=0.02)
print(f"Required sample size per group: {n_per_group:,}")
# -> 3,841 per group (7,682 total) to detect a 10% -> 12% lift at 80% power

# ── Example 25 ──
import numpy as np
from scipy import stats

def two_proportion_ztest(conversions_a, visitors_a, conversions_b, visitors_b):
    p_a = conversions_a / visitors_a
    p_b = conversions_b / visitors_b
    p_pool = (conversions_a + conversions_b) / (visitors_a + visitors_b)
    se = np.sqrt(p_pool * (1 - p_pool) * (1 / visitors_a + 1 / visitors_b))
    z = (p_b - p_a) / se
    p_value = 2 * (1 - stats.norm.cdf(abs(z)))    # two-tailed
    return z, p_value
z_stat, p_value = two_proportion_ztest(1000, 10000, 1100, 10000)
print(f"z = {z_stat:.3f}, p-value = {p_value:.4f}")
# -> z = 2.307, p-value = 0.0211 (statistically significant at alpha = 0.05)

# ── Example 26 ──
from scipy import stats
observed = [48_200, 51_800]       # actual visitor counts, variant A vs. B
expected = [50_000, 50_000]       # expected 50/50 split
chi2, p_value = stats.chisquare(observed, expected)
print(f"chi2 = {chi2:.3f}, p-value = {p_value:.5f}")
# A p-value below 0.01 on this check is a strong SRM signal — stop and
# investigate the assignment/logging pipeline before trusting the results

# ── Example 26b · Test duration (Chapter 4) ──
import math

def test_duration_days(required_total, daily_eligible_visitors, full_weeks=True):
    """Days needed to reach the pre-computed sample size.
    required_total: visitors needed across ALL variants (from the power calculation)."""
    days = math.ceil(required_total / daily_eligible_visitors)
    return math.ceil(days / 7) * 7 if full_weeks else days

print(test_duration_days(100_000, 10_000, full_weeks=False))  # -> 10 (mathematical minimum)
print(test_duration_days(100_000, 10_000))                    # -> 14 (two full weekly cycles)
print(test_duration_days(100_000, 2_500))                     # -> 42 (low traffic: six weeks)

# ── Example 26c · One-tailed vs two-tailed (Chapter 4) ──
from scipy import stats

for z in (1.80, 2.307):
    p_two = 2 * stats.norm.sf(abs(z))   # two-tailed: "is B different from A?"
    p_one = stats.norm.sf(z)            # one-tailed: "is B better than A?"
    print(f"z = {z}: two-tailed p = {p_two:.4f}, one-tailed p = {p_one:.4f}")
# -> z = 1.8: two-tailed p = 0.0719, one-tailed p = 0.0359
# -> z = 2.307: two-tailed p = 0.0211, one-tailed p = 0.0105
# At z = 1.80 the two-tailed test is NOT significant. Switching to one-tailed
# after seeing the data makes it "significant": that is the post-hoc trap.

# ── SETUP for Example 27 (not in the book) ──────────────────────────────────
# Write the CSV the notebook workflow reads, with a few missing keys on purpose.
pd.DataFrame({
    "user_id":    [1, 2, None, 4, 5, 6, None, 8],
    "event_date": ["2024-03-01", "2024-03-02", "2024-03-02", None,
                   "2024-03-04", "2024-03-05", "2024-03-06", "2024-03-07"],
    "amount":     [120, 80, 45, 300, 90, 150, 60, 210],
}).to_csv("data.csv", index=False)

# ── Example 27 ──
# 1. Load and inspect
import pandas as pd
df = pd.read_csv("data.csv")
print(df.shape)
print(df.dtypes)
print(df.isna().sum())
# 2. Document data quality issues found (write this as a markdown cell,
# not just a comment — reviewers skim markdown, not code)
# 3. Clean with explicit, auditable steps — never silently drop rows
before = len(df)
df_clean = df.dropna(subset=["user_id", "event_date"])
dropped_pct = (before - len(df_clean)) / before
print(f"Dropped {before - len(df_clean)} rows ({dropped_pct:.1%}) missing key fields")
# 4. Answer the core question — keep this section focused
# 5. Close with a markdown cell: TL;DR recommendation + next steps

# ── SETUP for Examples 31-36, the cheat sheet (not in the book) ─────────────
# One sample table carrying every column the cheat-sheet lines touch, saved as
# both a CSV and a SQLite table so read_csv() and read_sql() both work.
import sqlite3

rng = np.random.default_rng(11)
n = 24
sample = pd.DataFrame({
    # `col` is numeric here because the cheat sheet fills it with a median
    # further down; `col_text` holds the text version the later .str lines need.
    "col":          [None if i % 7 == 0 else float(rng.integers(10, 99)) for i in range(n)],
    "col_text":     [f" Value{i % 5} " for i in range(n)],
    "col1":         rng.integers(0, 100, n),
    "col2":         rng.normal(50, 12, n).round(2),
    "x":            rng.integers(0, 12, n),
    "status":       rng.choice(["active", "churned"], n, p=[.7, .3]),
    "amount":       rng.integers(20, 400, n),
    "user_id":      rng.integers(1, 12, n),
    "order_id":     range(1000, 1000 + n),
    "category":     rng.choice(["Audio", "Laptops", "Phones"], n),
    "date":         pd.date_range("2024-01-01", periods=n, freq="D").astype(str),
    "value":        rng.integers(50, 250, n),
    "required_col": [None if i % 9 == 0 else f"r{i}" for i in range(n)],
    "spend":        rng.integers(0, 2000, n),
    "age":          rng.integers(14, 80, n),
    "region":       rng.choice(["East", "West"], n),
    "product":      rng.choice(["A", "B"], n),
    "rev":          rng.integers(10, 90, n),
})
sample.to_csv("file.csv", index=False)
connection = sqlite3.connect(":memory:")
sample.to_sql("sample", connection, index=False, if_exists="replace")
query = "SELECT * FROM sample"

# two small frames for the merge/concat lines
df1 = pd.DataFrame({"key": [1, 2, 3], "left_val": ["a", "b", "c"]})
df2 = pd.DataFrame({"key": [2, 3, 4], "right_val": ["X", "Y", "Z"]})

# ── Example 31 ──
import pandas as pd
df = pd.read_csv("file.csv")            # from CSV
df = pd.read_sql(query, connection)     # from a SQL connection
df.shape                                 # (rows, columns)
df.dtypes                                # column data types
df.head(10)                              # first 10 rows
df.describe(include="all")               # summary stats for all columns
df.isna().sum()                          # null counts per column
df[["col1", "col2"]]                     # select columns
df.loc[df["x"] > 5, ["col1", "col2"]]    # filter rows + select columns (label-based)
df.iloc[0:5, 0:3]                        # position-based slicing

# ── Example 32 ──
df[df["status"] == "active"]                         # boolean mask
df.query("status == 'active' and amount > 100")       # query-string syntax
df.sort_values(["amount"], ascending=False)
df.drop_duplicates(subset=["user_id"], keep="first")
df["col"].unique()                                     # distinct values
df["col"].nunique()                                     # count of distinct values

# ── Example 33 ──
df.groupby("category").agg(
    total=("amount", "sum"),
    avg=("amount", "mean"),
    n=("order_id", "count"),
)
df.groupby("category").filter(lambda g: len(g) > 5)   # HAVING equivalent
df.groupby("category")["amount"].idxmax()               # index of max row per group
df.sort_values("amount", ascending=False).groupby("category").head(3)  # top-N per group

# ── Example 34 ──
pd.merge(df1, df2, on="key", how="left")               # how: left/right/inner/outer
pd.concat([df1, df2], axis=0)                            # stack rows (UNION ALL)
pd.concat([df1, df2], axis=1)                            # stack columns
wide = df.pivot_table(index="region", columns="product",
                      values="rev", aggfunc="sum", fill_value=0)   # long -> wide
long = wide.reset_index().melt(id_vars="region",
                               var_name="product", value_name="rev")  # wide -> long

# ── Example 35 ──
df["date"] = pd.to_datetime(df["date"], errors="coerce")
df["date"].dt.year                                         # also .dt.month, .dt.day_name(), .dt.weekday
df.set_index("date")["value"].resample("W").sum()        # DATE_TRUNC + GROUP BY
df["value"].shift(1)                                       # LAG(value, 1)
df["value"].diff()                                          # value - LAG(value, 1)
df["value"].pct_change()                                    # period-over-period % change
df["value"].rolling(window=7, min_periods=1).mean()          # 7-day moving average
df["value"].cumsum()                                         # running total

# ── Example 36 ──
df["col"].fillna(0)
df["col"].fillna(df["col"].median())
df.dropna(subset=["required_col"])
df["col"] = pd.to_numeric(df["col"], errors="coerce")
# ── SETUP (not in the book) ──
# The cheat sheet treats `col` as numeric in the lines above (fillna with a
# median, to_numeric) and as text in the lines below (.str.strip). Both are
# valid advice, but not for the same column in sequence, so swap in the text
# version here. Worth fixing in the next edition — see README.
df["col"] = sample["col_text"]
df["col"] = df["col"].str.strip().str.lower()
df["col"].astype("category")                             # memory-efficient for low-cardinality text
import numpy as np
df["tier"] = np.select(
    [df["spend"] >= 1000, df["spend"] >= 200],
    ["High", "Medium"], default="Low",
)                                                          # vectorized CASE WHEN
df["bucket"] = pd.cut(df["age"], bins=[0, 18, 35, 60, 100],
                       labels=["<18", "18-34", "35-59", "60+"])
