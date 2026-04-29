# Performance Regression Debugging

## Overview

Performance bugs are different from correctness bugs. The system works, but it works too slowly. Standard debugging techniques (reading error messages, checking stack traces) don't apply because there's no error — just slowness.

**Core principle:** Never optimize without measurements. Never guess what's slow. Always establish a baseline before investigating.

## Why Log-Driven Performance Debugging Fails

Adding log lines to find performance problems is the most common mistake:

| Approach | Problem |
|----------|---------|
| Log timestamps around suspect code | You guess where the problem is — you're usually wrong |
| Log "operation took Xms" for every operation | Flood of data, signal buried in noise |
| Add timing after seeing slowness | Observing changes timing (Heisenbug) |
| Compare log timestamps manually | Not reproducible, not automated |

**Why it fails:** You're adding observation to your assumption, not measuring the actual bottleneck. The slow code is almost always somewhere you didn't think to log.

## Baseline-First Debugging (5 Steps)

### Step 1: Establish a Baseline

Before investigating, measure the current performance objectively.

```bash
#!/usr/bin/env bash
set -euo pipefail

# baseline.sh — Establish performance baseline
# Run the operation 10 times, capture timing

echo "=== Establishing baseline ==="
for i in $(seq 1 10); do
  START=$(date +%s%N)
  curl -s http://localhost:8080/api/orders -o /dev/null
  END=$(date +%s%N)
  ELAPSED=$(( (END - START) / 1000000 ))
  echo "Run $i: ${ELAPSED}ms"
done
```

**Output you need:** Median time, p95 time, standard deviation. A single run tells you nothing.

### Step 2: Identify the Regression Window

Find when performance changed.

```bash
# Use git bisect with a timing threshold
git bisect start
git bisect bad HEAD              # Current: slow
git bisect good v2.3.0          # Known: fast

# bisect-timing.sh — Script for git bisect run
#!/usr/bin/env bash
npm run build 2>/dev/null
SECONDS_START=$SECONDS
curl -s http://localhost:8080/api/orders > /dev/null
ELAPSED=$(( SECONDS - SECONDS_START ))
echo "Time: ${ELAPSED}s"
if (( ELAPSED > 2 )); then
  exit 1  # bad — slow
else
  exit 0  # good — fast
fi
```

### Step 3: Profile, Don't Guess

Use a profiler to find where time is actually spent.

```bash
# CPU profiling with perf (Linux)
perf record -g -- curl -s http://localhost:8080/api/orders > /dev/null
perf report --stdio

# Node.js profiling
node --prof app.js &
# ... trigger the slow operation ...
node --prof-process isolate-*.log > profile.txt

# Python profiling
python -m cProfile -o profile.stats app.py
python -c "import pstats; p=pstats.Stats('profile.stats'); p.sort_stats('cumulative'); p.print_stats(20)"

# Database query profiling
EXPLAIN ANALYZE SELECT * FROM orders JOIN customers ON ...
```

### Step 4: Form Hypothesis with Measurements

Your hypothesis must include a specific metric and expected change.

**Bad hypothesis:** "The database is slow."
**Good hypothesis:** "The orders query without an index on `created_at` is doing a full table scan. Adding the index should reduce query time from 800ms to under 50ms."

**Verify the hypothesis:**
```bash
# Before fix
time psql -c "SELECT * FROM orders WHERE created_at > NOW() - INTERVAL '1 day'"
# psql output: 823ms, Seq Scan on orders

# Add index
psql -c "CREATE INDEX idx_orders_created_at ON orders(created_at)"

# After fix
time psql -c "SELECT * FROM orders WHERE created_at > NOW() - INTERVAL '1 day'"
# psql output: 12ms, Index Scan using idx_orders_created_at
```

### Step 5: Verify the Fix

Run the same baseline measurement again. Compare numbers.

```bash
# Same script as Step 1
echo "=== Post-fix measurement ==="
for i in $(seq 1 10); do
  START=$(date +%s%N)
  curl -s http://localhost:8080/api/orders -o /dev/null
  END=$(date +%s%N)
  ELAPSED=$(( (END - START) / 1000000 ))
  echo "Run $i: ${ELAPSED}ms"
done
```

**Fix only counts if the baseline measurement improved.** Subjective "feels faster" is not verification.

## Common Performance Anti-Patterns

| Anti-Pattern | Symptom | How to Confirm | Fix |
|---|---|---|---|
| N+1 queries | Linear slowdown with data size | Enable SQL logging, count queries per request | Batch queries, eager loading |
| Missing index | Slow reads, fast writes | `EXPLAIN ANALYZE` shows Seq Scan | Add appropriate index |
| Unbounded result set | Degrades as data grows | Check query LIMIT, row counts in response | Pagination, streaming |
| Synchronous serial I/O | Latency multiplies per call | Profile shows sequential wait times | Parallelize with Promise.all / async |
| Large object in memory | GC pauses, OOM | Heap dump / memory profiling | Stream processing, pagination |
| Redundant computation | CPU-bound but same result each time | Profile shows repeated identical work | Caching, memoization |
| Tight poll loop | High CPU, low throughput | `top` shows 100% CPU, low actual work | Event-driven, condition-based waiting |
| Unoptimized serialization | CPU spike on serialization | Profile time in JSON.stringify / marshal | Selective field serialization, binary format |
| Connection pool exhaustion | Requests queue up under load | Connection count at pool limit | Increase pool size, fix connection leaks |
| Lock contention | Slows with concurrency | Profile shows thread wait time | Reduce lock scope, lock-free algorithms |

## Non-Deterministic Performance Bugs

Performance bugs that only appear sometimes are the hardest class. Strategy:

### 1. Raise the Reproduction Rate

The goal is making a flaky performance bug happen reliably.

```bash
# Stress the system to amplify the race condition
for i in $(seq 1 100); do
  curl -s http://localhost:8080/api/orders -o /dev/null -w "%{time_total}\n" &
done
wait

# Or use a load testing tool
ab -n 1000 -c 50 http://localhost:8080/api/orders
```

### 2. Freeze Randomness

If timing-dependent, remove the timing variability:

```bash
# Pin to single CPU to eliminate scheduler variance
taskset -c 0 node app.js

# Disable CPU frequency scaling
sudo cpupower frequency-set -g performance

# Set fixed seed for any random behavior
export RANDOM_SEED=42
```

### 3. Bisect on Conditions

Binary search through conditions to find the trigger:

```bash
#!/usr/bin/env bash
# Is it concurrency? Try different levels
for c in 1 2 5 10 25 50 100; do
  echo -n "Concurrency $c: "
  ab -n 100 -c "$c" http://localhost:8080/api/orders 2>&1 | grep "Time per request"
done

# Is it data volume? Try different sizes
for size in 10 100 1000 10000; do
  echo -n "Records $size: "
  # Seed database with $size records, then measure
  ./seed-data.sh "$size"
  curl -s -o /dev/null -w "%{time_total}s\n" http://localhost:8080/api/orders
done
```

### 4. Continuous Profiling

For bugs that only appear in production, use continuous profiling:

```bash
# Linux perf (always-on)
perf record -F 99 -a -g -- sleep 60
perf report --stdio

# eBPF-based (lower overhead)
bcc/tools/profile.py -F 99 60 > profile.txt
```

## Decision Flow

```
Performance regression detected?
  -> Establish baseline (Step 1)
  -> Know when it started?
    Yes -> Bisect to find introducing commit (Step 2)
    No  -> Profile to find bottleneck (Step 3)
  -> Form measurable hypothesis (Step 4)
  -> Implement fix
  -> Re-run baseline to verify (Step 5)
  -> Did it improve?
    Yes -> Done. Commit with before/after numbers.
    No  -> Wrong hypothesis. Return to Step 3.
```

## Key Insight

Performance debugging is a measurement problem, not a debugging problem. The profiler tells you where the time goes — your job is to reduce it there, not to guess where it might be going. Every optimization without a before/after measurement is waste.
