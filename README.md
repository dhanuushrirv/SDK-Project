# kdb Insights DBRT: Equities Ingestion and Query Validation

## Project Summary
This project documents the end-to-end setup and validation of a kdb Insights Docker Reference Deployment (DBRT) using a custom dataset (`dataSet.csv`) loaded into the `equities` table.

## Environment
- kxi bundle path: `/home/dhanuushri/kxi-db`
- dataset path: `/home/dhanuushri/kxi-db/config/dataSet.csv`
- q publish folder: `/home/dhanuushri/kxi-db/rt`

## 1) Prerequisites and Setup
### Docker registry login
```bash
docker login portal.dl.kx.com -u <user> -p <bearer_token>
```

### Download and extract bundle
```bash
cd /home/dhanuushri
curl -L https://portal.dl.kx.com/assets/raw/kxi-db/~latest~/kxi-db.tar.gz -o kxi-db.tar.gz
tar -xvf kxi-db.tar.gz
cd kxi-db
```

### Add license and CSV
```bash
cp /path/to/kc.lic /home/dhanuushri/kxi-db/lic/
cp /path/to/dataSet.csv /home/dhanuushri/kxi-db/config/dataSet.csv
```

### Linux permissions
```bash
cd /home/dhanuushri/kxi-db
mkdir -p data/logs/rt data/db
sudo chmod -R 777 data
```

## 2) Assembly Schema Changes
Edit `config/assembly.yaml` and define table `equities`.
Important fix applied:
- For partitioned table, `prtnCol` must be `timestamp` type.
- `Date` set to `timestamp`.

## 3) Start Deployment
```bash
cd /home/dhanuushri/kxi-db
sudo docker compose up -d
docker compose ps --services
```
Expected services:
- `kxi-agg`
- `kxi-da`
- `kxi-gw`
- `kxi-rc`
- `kxi-rt`

## 4) Errors Encountered and Resolutions
### Error A: RT replicator inconsistent files
Observed:
- `Inconsistent file detected ... log.2.0`
- `Replicators in error state - statusCode = 67`

Fix:
- Reset local publisher path and client id (`/tmp/rt_pub*`, `pub*`)
- Clean `data/logs/rt/*` and restart compose.

### Error B: Table not found
Observed:
- `Table not found, table=equities`

Fix:
- Added `equities` in `assembly.yaml`.

### Error C: SM schema validation fatal
Observed:
- `assembly.table.equities Date prtnCol is not timestamp type`

Fix:
- Changed `Date` type from `date` to `timestamp`.

### Error D: Type mismatch during ingest
Observed in `kxi-sm` logs:
- Data shape: `Date=d`, numerics=`f`
- Dest shape: `Date=p`, numerics=`e`

Fix:
- Load CSV with real (`e`) numeric type string and cast Date to timestamp before publish.

## 5) Publish via q (Final Working)
From `/home/dhanuushri/kxi-db/rt`:

```q
q startq.q
params:(`path`stream`publisher_id`cluster)!('/tmp/rt_pub3';'data';'pub3';enlist':127.0.0.1:5002')
p:.rt.pub params

equities:("DEEEEEJEEEEEEEEEEEEEEI";enlist",")0:hsym`$"../config/dataSet.csv"
equities:`Date`Open`High`Low`Close`AdjClose`Volume`RSI`UpperBollingerBand`LowerBollingerBand`PctK5d`PctDAvgH3`EMA12`EMA26`VWAP`WilliamPctR`CCI`ROC10d`AroonUp`AroonDown`MACD`BUYSELL xcol equities
equities:update Date:"p"$Date from equities

meta equities
count equities
p(`.b;`equities;equities)
```

## 6) Query Validation (q)
```q
h:hopen 5050
h(`.kxi.sql;enlist[`query]!enlist"SELECT COUNT(*) AS n FROM equities";`;()!())
h(`.kxi.sql;enlist[`query]!enlist"SELECT COUNT(DISTINCT Date) AS d FROM equities";`;()!())
h(`.kxi.sql;enlist[`query]!enlist"SELECT MIN(Date) AS min_dt, MAX(Date) AS max_dt FROM equities";`;()!())
h(`.kxi.sql;enlist[`query]!enlist"SELECT COUNT(*) AS bad FROM equities WHERE Date IS NULL OR Open IS NULL OR Close IS NULL";`;()!())
h(`.kxi.sql;enlist[`query]!enlist"SELECT BUYSELL, COUNT(*) AS c FROM equities GROUP BY BUYSELL ORDER BY BUYSELL";`;()!())
```

## 7) Final Verified Results
- Total rows: `9339`
- Distinct dates: `3113`
- Date range: `2010-02-09` to `2022-09-09`
- Null check (`Date/Open/Close`): `0`
- BUYSELL distribution:
  - `-1`: `3558`
  - `0`: `2673`
  - `1`: `3090`
  - `NULL (0N)`: `18`

## 8) Notes
- `.kxi.sql` and `.kxi.getData` returned consistent populated results.
- `.kxi.qsql` returned inconsistent/empty results in this setup.

## 9) Stop Deployment
```bash
cd /home/dhanuushri/kxi-db
docker compose down
```
## 10) Remove logs while starting the next docker compose
```
sudo rm -rf data/logs/rt/* data/db/*
```
