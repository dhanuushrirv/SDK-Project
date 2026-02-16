# Publish via q (Quick Reference)

From:
`/home/dhanuushri/kxi-db/rt`

```q
q startq.q
params:(`path`stream`publisher_id`cluster)!('/tmp/rt_pub3';'data';'pub3';enlist':127.0.0.1:5002')
p:.rt.pub params

equities:("DEEEEEJEEEEEEEEEEEEEEI";enlist",")0:hsym`$"../config/dataSet.csv"
equities:`Date`Open`High`Low`Close`AdjClose`Volume`RSI`UpperBollingerBand`LowerBollingerBand`PctK5d`PctDAvgH3`EMA12`EMA26`VWAP`WilliamPctR`CCI`ROC10d`AroonUp`AroonDown`MACD`BUYSELL xcol equities
equities:update Date:"p"$Date from equities
p(`.b;`equities;equities)
```
