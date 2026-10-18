"""Check that everything in this folder actually runs.

    python3 verify.py

Runs each SQL example against the seed database, then runs the Python file end
to end and confirms the results printed in the book still come out. Exits
non-zero if anything fails.
"""
import os
import re
import subprocess
import sys

import duckdb

HERE = os.path.dirname(os.path.abspath(__file__))
failures = []

# ───────────────────────────────────────────────────────────────── SQL
print('SQL examples')
con = duckdb.connect(':memory:')
con.execute(open(f'{HERE}/setup.sql').read())
sql = open(f'{HERE}/offer_ready_sql.sql').read()
blocks = re.split(r'\n(?=-- ── )', sql)[1:]

for block in blocks:
    name = block.split('\n', 1)[0].strip('- ─ ')
    statements = [s.strip() for s in block.split(';') if s.strip() and
                  not all(l.strip().startswith('--') or not l.strip()
                          for l in s.splitlines())]
    for i, stmt in enumerate(statements, 1):
        label = name if len(statements) == 1 else f'{name} [stmt {i}]'
        try:
            rows = con.execute(stmt).fetchall()
        except Exception as e:
            failures.append((label, f'{type(e).__name__}: {str(e).splitlines()[0]}'))
            print(f'  FAIL  {label}')
            continue
        if not rows:
            failures.append((label, 'returned 0 rows'))
            print(f'  EMPTY {label}')
        else:
            print(f'  ok    {label:26} {len(rows):3d} row(s)')

# ────────────────────────────────────────────────────────────── Python
print('\nPython examples')
proc = subprocess.run([sys.executable, f'{HERE}/offer_ready_python.py'],
                      capture_output=True, text=True, cwd=HERE)
if proc.returncode != 0:
    failures.append(('offer_ready_python.py', proc.stderr.strip().splitlines()[-1]))
    print('  FAIL  the file raised:', proc.stderr.strip().splitlines()[-1])
else:
    print('  ok    runs end to end')

# the figures the book states in its comments
EXPECTED = {
    'Bayes worked example':      'P(has condition | positive test) = 16.1%',
    'Expected value':            'Expected value per user: $2.80',
    'A/B sample size':           'Required sample size per group: 3,841',
    'Two-proportion z-test':     'z = 2.307, p-value = 0.0211',
    'Coercion audit (dates)':    "['not provided']",
    'Coercion audit (revenue)':  "['N/A']",
    'One- vs two-tailed':        'two-tailed p = 0.0719, one-tailed p = 0.0359',
}
for label, needle in EXPECTED.items():
    if needle in proc.stdout:
        print(f'  ok    {label:26} matches the book')
    else:
        failures.append((label, f'book states "{needle}", not found in output'))
        print(f'  FAIL  {label}')

# ───────────────────────────────────────────────────────────── verdict
print()
if failures:
    print(f'{len(failures)} problem(s):')
    for label, why in failures:
        print(f'  {label}: {why}')
    sys.exit(1)
print(f'All {len(blocks)} SQL examples and the full Python file run clean.')
