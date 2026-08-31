# SQL Patterns 

A comprehensive collection of intermediate to advanced SQL patterns used  in data engineering and FDE's in developing Agentic AI 
Business question → SQL pattern → result → Agentic AI / data workflow

## Patterns included

1. **Window Functions** — ROW_NUMBER, RANK, LAG, LEAD, running totals
2. **Common Table Expressions (CTEs)** — multi-step queries with readable logic
3. **Aggregation with HAVING** — filtering groups based on aggregated conditions
4. **Subqueries** — scalar and correlated subqueries
5. **UNION / UNION ALL** — combining result sets
6. **Self-join** — comparing a table to itself
7. **CASE statements** — conditional logic in SQL
8. **Date filtering** — BETWEEN, date functions
9. **GROUP BY with multiple aggregations** — rich summaries
10. **Recursive CTEs** — hierarchical data and sequences

## Data Flow
                         BUSINESS QUESTION
                                │
              ┌─────────────────┼─────────────────┐
              │                 │                 │
              ▼                 ▼                 ▼
        "Rank customers"   "Compare periods"   "Org hierarchy"
              │                 │                 │
              ▼                 ▼                 ▼
       Window Functions      LAG / LEAD       Recursive CTE
              │                 │                 │
              └─────────────────┼─────────────────┘
                                ▼
                       SQL RESULT / METRIC
                                │
                                ▼
                  DATA ENGINEERING WORKFLOW
                                │
                                ▼
                       AGENTIC AI SYSTEM

## How to use

All queries are written in SQLite (portable, no external database needed). Run them directly:

```bash
sqlite3 < sql_patterns.sql
```

Or open the file in your favorite SQL editor and execute queries individually.

## Interview talking points

- "Window functions are essential for time-series and ranking problems"
- "CTEs make complex queries readable and maintainable"
- "Always think about filtering on aggregates (HAVING) vs. row-level filters (WHERE)"
- "UNION deduplicates; UNION ALL preserves duplicates — choose wisely"
- "Self-joins are powerful for comparative analysis"

## Why these patterns matter

At the data engineering / FDE level, you'll encounter these patterns constantly:
- **Window functions** — real-time metrics, rankings, running totals
- **CTEs** — breaking down complex business logic into readable steps
- **Subqueries** — building blocks for dynamic filtering
- **Date filtering** — time-series analysis, retention cohorts
- **Recursive CTEs** — hierarchical data, organizational structures


