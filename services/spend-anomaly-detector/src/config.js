'use strict';

module.exports = {
  port: process.env.PORT || 4006,
  largeOrderThreshold: Number(process.env.LARGE_ORDER_THRESHOLD || 30_000),
  unitPriceOutlierMultiple: Number(process.env.UNIT_PRICE_OUTLIER_MULTIPLE || 3),
  anomaliesFile: process.env.ANOMALIES_FILE || require('path').join(__dirname, '..', 'data', 'anomalies.jsonl'),
};
