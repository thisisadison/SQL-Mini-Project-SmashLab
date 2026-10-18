# Index benchmark results

SQLite 3.51.0. Median milliseconds per query on synthetic data, warm cache, file-backed database. Regenerate with `python3 benchmark/bench.py`.

Index sets:

- **none**: no secondary indexes
- **original**: the first version's indexes on `string_job(order_id)`, `string_job(job_status)` and `orders(collection_status)`
- **current**: the indexes in `schema.sql`

## Small shop (~1 year): 1,500 customers, 5,000 orders, 8,975 string jobs

| Query | none | original | current | Rows |
|---|---:|---:|---:|---:|
| Q1 lockers in use | 0.291 | 0.036 | 0.035 | 50 |
| Q2 lockers to reclaim | 2.722 | 2.793 | 2.805 | 4,850 |
| Q3 orders ready for collection | 40.108 | 0.072 | 0.071 | 29 |
| Q4 pending job queue | 0.609 | 0.090 | 0.089 | 94 |
| Q5 job specs by order | 0.387 | 0.012 | 0.012 | 3 |
| Q6 total cost of an order | 0.379 | 0.010 | 0.010 | 1 |
| Q7 cost breakdown of an order | 0.384 | 0.012 | 0.012 | 3 |
| **Total** | **44.879** | **3.024** | **3.034** | |
| Speedup vs none | 1.0x | 14.8x | 14.8x | |

## Busy shop (~5 years): 8,000 customers, 50,000 orders, 90,034 string jobs

| Query | none | original | current | Rows |
|---|---:|---:|---:|---:|
| Q1 lockers in use | 2.848 | 0.283 | 0.283 | 500 |
| Q2 lockers to reclaim | 28.475 | 29.144 | 28.946 | 48,500 |
| Q3 orders ready for collection | 5,532 | 0.749 | 0.741 | 353 |
| Q4 pending job queue | 7.027 | 0.797 | 0.799 | 857 |
| Q5 job specs by order | 4.791 | 0.011 | 0.011 | 2 |
| Q6 total cost of an order | 4.832 | 0.010 | 0.010 | 1 |
| Q7 cost breakdown of an order | 5.208 | 0.011 | 0.011 | 2 |
| **Total** | **5,585** | **31.005** | **30.800** | |
| Speedup vs none | 1.0x | 180.1x | 181.3x | |

## Stress test: 30,000 customers, 200,000 orders, 360,513 string jobs

| Query | none | original | current | Rows |
|---|---:|---:|---:|---:|
| Q1 lockers in use | 13.211 | 1.096 | 1.097 | 2,000 |
| Q2 lockers to reclaim | 123 | 122 | 123 | 194,000 |
| Q3 orders ready for collection | 93,883 | 3.004 | 3.010 | 1,285 |
| Q4 pending job queue | 29.278 | 3.339 | 3.350 | 3,587 |
| Q5 job specs by order | 19.880 | 0.010 | 0.010 | 1 |
| Q6 total cost of an order | 20.751 | 0.010 | 0.010 | 1 |
| Q7 cost breakdown of an order | 20.467 | 0.010 | 0.010 | 1 |
| **Total** | **94,109** | **130** | **130** | |
| Speedup vs none | 1.0x | 725.5x | 722.1x | |

## Query plans (busy shop)

**Q1 lockers in use**

- none: `SCAN orders`
- original: `SEARCH orders USING INDEX search_by_collectionstatus (collection_status=?)`
- current: `SEARCH orders USING INDEX search_by_collectionstatus (collection_status=?)`

**Q2 lockers to reclaim**

- none: `SCAN orders`
- original: `SEARCH orders USING INDEX search_by_collectionstatus (collection_status=?)`
- current: `SEARCH orders USING INDEX search_by_collectionstatus (collection_status=?)`

**Q3 orders ready for collection**

- none: `SCAN o; CORRELATED SCALAR SUBQUERY 1; SCAN j`
- original: `SEARCH o USING COVERING INDEX search_by_collectionstatus (collection_status=?); CORRELATED SCALAR SUBQUERY 1; SEARCH j USING INDEX search_by_orderid (order_id=?)`
- current: `SEARCH o USING COVERING INDEX search_by_collectionstatus (collection_status=?); CORRELATED SCALAR SUBQUERY 1; SEARCH j USING INDEX search_by_orderid (order_id=?)`

**Q4 pending job queue**

- none: `SCAN j; SEARCH o USING INTEGER PRIMARY KEY (rowid=?)`
- original: `SEARCH j USING INDEX search_by_jobstatus (job_status=?); SEARCH o USING INTEGER PRIMARY KEY (rowid=?)`
- current: `SEARCH j USING INDEX search_by_jobstatus (job_status=?); SEARCH o USING INTEGER PRIMARY KEY (rowid=?)`

**Q5 job specs by order**

- none: `SCAN j; SEARCH s USING INTEGER PRIMARY KEY (rowid=?)`
- original: `SEARCH j USING INDEX search_by_orderid (order_id=?); SEARCH s USING INTEGER PRIMARY KEY (rowid=?)`
- current: `SEARCH j USING INDEX search_by_orderid (order_id=?); SEARCH s USING INTEGER PRIMARY KEY (rowid=?)`

**Q6 total cost of an order**

- none: `SEARCH o USING INTEGER PRIMARY KEY (rowid=?); SCAN j`
- original: `SEARCH o USING INTEGER PRIMARY KEY (rowid=?); SEARCH j USING INDEX search_by_orderid (order_id=?)`
- current: `SEARCH o USING INTEGER PRIMARY KEY (rowid=?); SEARCH j USING INDEX search_by_orderid (order_id=?)`

**Q7 cost breakdown of an order**

- none: `SCAN j; SEARCH s USING INTEGER PRIMARY KEY (rowid=?)`
- original: `SEARCH j USING INDEX search_by_orderid (order_id=?); SEARCH s USING INTEGER PRIMARY KEY (rowid=?)`
- current: `SEARCH j USING INDEX search_by_orderid (order_id=?); SEARCH s USING INTEGER PRIMARY KEY (rowid=?)`

