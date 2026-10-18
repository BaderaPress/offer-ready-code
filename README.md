# Offer Ready — code companion

Every SQL query and Python example from **Offer Ready: The Data Analyst Interview Playbook**
by Kamlesh Verma (Badera Press), with a small sample database so you can run them
instead of reading them.

You don't need the book to use this, but the examples are numbered to match it.

---

## Quick start

```bash
git clone <this repo>
cd offer-ready-code
pip install duckdb pandas numpy scipy
python3 verify.py          # runs everything and checks the results
```

### SQL

```bash
duckdb offer_ready.duckdb < setup.sql
duckdb offer_ready.duckdb < offer_ready_sql.sql
```

`setup.sql` creates and fills ten tables. The queries are PostgreSQL-style and run
unchanged on DuckDB; on Postgres itself, run the same two files through `psql`.

### Python

```bash
python3 offer_ready_python.py
```

Tested on pandas 2.2 and 3.0.

---

## What's here

| File | What it is |
|---|---|
| `setup.sql` | Creates and populates the ten tables the queries read |
| `offer_ready_sql.sql` | All 14 SQL examples, exactly as printed in the book |
| `offer_ready_python.py` | All 26 Python examples, plus clearly marked `SETUP` blocks |
| `verify.py` | Runs everything; fails loudly if an example breaks |

The example code is **unchanged from the book**. The only additions are blocks
labelled `SETUP (not in the book)`, which build the sample frames an example
needs. You can delete them and paste the example straight into your own notebook.

---

## The sample data is deliberately awkward

Clean data teaches you nothing, so the seed tables contain the problems the book
talks about:

- **`users` and `user_registrations`** have duplicate emails, including one address
  registered three times — two of them seconds apart.
- **`employees`** has salary ties inside departments, so `DENSE_RANK`, `RANK` and
  `ROW_NUMBER` give you three different answers. Interviewers ask about exactly this.
- **`events`** contains a user who purchased without ever adding to cart, and another
  who added to cart *before* viewing the item. The naive funnel (Example 10) reports
  7 → 4 → 4, a 100% cart-to-purchase rate. The ordered funnel underneath it reports
  7 → 3 → 2. If you can explain that gap out loud, you can handle a funnel question.
- **`user_logs`** has a five-day login streak, a three-day streak with a duplicate
  login inside it, and a user who never reaches three in a row.
- **`payments`** dips in February, so month-over-month growth goes negative.
- **`user_activity`** gives a retention rate that is neither 0% nor 100%, and a first
  month with no prior month to compare against — the null you have to decide what
  to do with.

---

## Two things the book gets slightly wrong

Worth knowing if you're reading along.

**The pandas cheat sheet (Examples 31–36) is a reference, not a sequence.** It fills
`df["col"]` with a median and runs `pd.to_numeric` on it, then calls `.str.strip()`
on the same column a line later. Both lines are good advice; they just can't both
apply to one column in order. In `offer_ready_python.py` there's a one-line `SETUP`
block at that point that swaps in a text column, so the file runs. Treat those six
blocks as a lookup table, not a script.

**Example 8's retention query** returns `NULL` for the first month, because there's
no prior month to divide by. That's correct behaviour, not a bug — but if you paste
it into an interview, say so before they ask.

---

## Licence

The code is free to use in your own work, interviews included. The book's text is not.

*Offer Ready: The Data Analyst Interview Playbook* — Kamlesh Verma, Badera Press.
