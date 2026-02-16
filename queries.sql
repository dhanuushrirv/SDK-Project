-- queries.sql
-- Purpose: Reusable SQL validation queries for the kdb Insights SDK project.
-- Scope: Verifies equities data ingestion quality and basic analytics after q-based publish.
-- Includes checks for row counts, distinct dates, date range, nulls, duplicates, distribution, and sample indicators.
-- Table expected: equities


-- Core checks
SELECT COUNT(*) AS n FROM equities;
SELECT COUNT(DISTINCT Date) AS d FROM equities;
SELECT MIN(Date) AS min_dt, MAX(Date) AS max_dt FROM equities;
SELECT COUNT(*) AS bad FROM equities WHERE Date IS NULL OR Open IS NULL OR Close IS NULL;
SELECT BUYSELL, COUNT(*) AS c FROM equities GROUP BY BUYSELL ORDER BY BUYSELL;

-- Sampling
SELECT Date, Open, Close, Volume, BUYSELL FROM equities LIMIT 20;

-- Dupes
SELECT Date, Open, Close, COUNT(*) AS c
FROM equities
GROUP BY Date, Open, Close
HAVING COUNT(*) > 1
LIMIT 20;

-- Indicators
SELECT Date, RSI, MACD, BUYSELL
FROM equities
WHERE RSI > 70 OR RSI < 30
LIMIT 20;
