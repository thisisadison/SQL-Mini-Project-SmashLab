"""Benchmark Smash Lab's common queries under different index sets.

Loads the tables from sql/schema.sql, fills them with synthetic data at three
sizes, and times every query in sql/queries.sql against:

  none      -- no secondary indexes
  original  -- the first version's indexes (order_id, job_status, collection_status)
  current   -- the indexes currently in sql/schema.sql

Usage (from the repo root):
    python3 benchmark/bench.py
Writes benchmark/RESULTS.md. Needs only the Python standard library.
"""
import os
import random
import re
import sqlite3
import statistics
import sys
import tempfile
import time

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

ORIGINAL_INDEXES = [
    'CREATE INDEX "search_by_orderid" ON "string_job" ("order_id");',
    'CREATE INDEX "search_by_jobstatus" ON "string_job" ("job_status");',
    'CREATE INDEX "search_by_collectionstatus" ON "orders" ("collection_status");',
]

SCALES = [
    # label, customers, orders
    ("Small shop (~1 year)", 1_500, 5_000),
    ("Busy shop (~5 years)", 8_000, 50_000),
    ("Stress test", 30_000, 200_000),
]

SHORT = [
    "Q1 lockers in use",
    "Q2 lockers to reclaim",
    "Q3 orders ready for collection",
    "Q4 pending job queue",
    "Q5 job specs by order",
    "Q6 total cost of an order",
    "Q7 cost breakdown of an order",
]


def load_sql():
    schema = open(os.path.join(REPO, "sql", "schema.sql")).read()
    queries_sql = open(os.path.join(REPO, "sql", "queries.sql")).read()
    index_ddl = re.findall(r'CREATE INDEX[^;]+;', schema)
    table_ddl = schema
    for d in index_ddl:
        table_ddl = table_ddl.replace(d, "")
    # Each query is a "-- Check ..." comment followed by one SELECT
    queries = [m.group(1).strip()
               for m in re.finditer(r'--\s*Check[^\n]*\n(SELECT.*?;)', queries_sql, re.S)]
    assert len(queries) == len(SHORT), f"expected {len(SHORT)} queries, found {len(queries)}"
    return table_ddl, index_ddl, queries


def populate(conn, n_customers, n_orders, seed=42):
    rnd = random.Random(seed)
    conn.executemany(
        'INSERT INTO customers(first_name, last_name, contact_number, start_date) VALUES (?, ?, ?, ?)',
        [(f"F{i}", f"L{i}", 80000000 + i, "2023-01-01") for i in range(n_customers)])
    conn.executemany(
        'INSERT INTO staff(first_name, last_name, contact_number) VALUES (?, ?, ?)',
        [(f"S{i}", f"T{i}", 90000000 + i) for i in range(5)])
    conn.executemany(
        'INSERT INTO strings(brand, name, price) VALUES (?, ?, ?)',
        [("Yonex", f"String{i}", 23.0) for i in range(20)])

    # The newest ~2% of orders are still in the shop, ~1% are waiting in
    # lockers, and the rest were collected long ago.
    orders, jobs = [], []
    for oid in range(1, n_orders + 1):
        age = n_orders - oid
        if age < n_orders * 0.02:
            status = "In-Store"
        elif age < n_orders * 0.03:
            status = "Ready For Collection"
        else:
            status = "Collected"
        cust = rnd.randint(1, n_customers)
        locker = rnd.randint(1, 30) if status != "In-Store" else None
        orders.append((cust, locker, rnd.randint(0, 999999) if locker else None, status))
        for _ in range(rnd.choice([1, 1, 2, 2, 3])):
            job_status = rnd.choice(["Pending", "Completed"]) if status == "In-Store" else "Completed"
            jobs.append((cust, rnd.randint(1, 5), oid, rnd.randint(1, 20),
                         rnd.choice(["White", "Red", "Yellow", "Blue"]),
                         rnd.randint(22, 34), "Yonex Astrox 99", 23.0, job_status))
    conn.executemany(
        'INSERT INTO orders(customer_id, locker_id, locker_password, collection_status) VALUES (?, ?, ?, ?)',
        orders)
    conn.executemany(
        'INSERT INTO string_job(customer_id, staff_id, order_id, string_id, string_colour, '
        'string_tension, comments, job_cost, job_status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', jobs)
    conn.commit()
    return len(jobs)


def build(path, table_ddl, index_ddl, n_customers, n_orders):
    conn = sqlite3.connect(path)
    conn.executescript(table_ddl)
    n_jobs = populate(conn, n_customers, n_orders)
    for d in index_ddl:
        conn.execute(d)
    conn.commit()
    return conn, n_jobs


def time_query(conn, sql, reps):
    """Median wall time in ms over `reps` warm runs, plus the row count."""
    t = time.perf_counter()
    n_rows = len(conn.execute(sql).fetchall())  # warm the cache
    first = time.perf_counter() - t
    if first > 5.0:  # pathological plan: one timed run is enough
        return first * 1000, n_rows
    if first > 1.0:
        reps = 3
    times = []
    for _ in range(reps):
        t = time.perf_counter()
        conn.execute(sql).fetchall()
        times.append(time.perf_counter() - t)
    return statistics.median(times) * 1000, n_rows


def run(variants, scales=SCALES):
    table_ddl, _, queries = load_sql()
    results = []
    with tempfile.TemporaryDirectory() as tmp:
        for label, n_customers, n_orders in scales:
            conns = []
            for name, ddl in variants:
                conn, n_jobs = build(os.path.join(tmp, f"{name}-{n_orders}.db"),
                                     table_ddl, ddl, n_customers, n_orders)
                conns.append(conn)
            reps = 20 if n_orders >= 200_000 else 50
            rows = []
            for short, sql in zip(SHORT, queries):
                # Look up a recent order instead of the sample data's order 2/3
                sql = re.sub(r'"order_id" = \d+', f'"order_id" = {n_orders - 5}', sql)
                timings, n_rows = [], None
                for conn in conns:
                    ms, n = time_query(conn, sql, reps)
                    assert n_rows is None or n == n_rows, f"{short}: row counts differ"
                    n_rows = n
                    timings.append(ms)
                plans = ["; ".join(r[3] for r in c.execute("EXPLAIN QUERY PLAN " + sql)) for c in conns]
                rows.append((short, timings, n_rows, plans))
                print(f"  [{label}] {short}: " + ", ".join(f"{t:.3f} ms" for t in timings),
                      file=sys.stderr, flush=True)
            results.append((label, n_customers, n_orders, n_jobs, rows))
            for conn in conns:
                conn.close()
    return results


def fmt_ms(ms):
    return f"{ms:,.0f}" if ms >= 100 else f"{ms:.3f}"


def report(variants, results):
    names = [name for name, _ in variants]
    out = ["# Index benchmark results", "",
           f"SQLite {sqlite3.sqlite_version}. Median milliseconds per query on synthetic data, "
           "warm cache, file-backed database. Regenerate with `python3 benchmark/bench.py`.", "",
           "Index sets:", "",
           "- **none**: no secondary indexes",
           "- **original**: the first version's indexes on `string_job(order_id)`, "
           "`string_job(job_status)` and `orders(collection_status)`",
           "- **current**: the indexes in `sql/schema.sql`", ""]
    for label, n_customers, n_orders, n_jobs, rows in results:
        out += [f"## {label}: {n_customers:,} customers, {n_orders:,} orders, {n_jobs:,} string jobs", "",
                "| Query | " + " | ".join(names) + " | Rows |",
                "|---|" + "---:|" * (len(names) + 1)]
        totals = [0.0] * len(names)
        for short, timings, n_rows, _ in rows:
            totals = [a + b for a, b in zip(totals, timings)]
            out.append(f"| {short} | " + " | ".join(fmt_ms(t) for t in timings) + f" | {n_rows:,} |")
        out.append("| **Total** | " + " | ".join(f"**{fmt_ms(t)}**" for t in totals) + " | |")
        out.append("| Speedup vs none | " + " | ".join(f"{totals[0] / t:.1f}x" for t in totals) + " | |")
        out.append("")
    out += ["## Query plans (busy shop)", ""]
    for short, _, _, plans in results[1][4]:
        out.append(f"**{short}**")
        out.append("")
        for name, plan in zip(names, plans):
            out.append(f"- {name}: `{plan}`")
        out.append("")
    return "\n".join(out)


def main():
    _, current, _ = load_sql()
    variants = [("none", []), ("original", ORIGINAL_INDEXES), ("current", current)]
    results = run(variants)
    text = report(variants, results)
    path = os.path.join(REPO, "benchmark", "RESULTS.md")
    with open(path, "w") as f:
        f.write(text + "\n")
    print(f"Wrote {path}", file=sys.stderr)


if __name__ == "__main__":
    main()
