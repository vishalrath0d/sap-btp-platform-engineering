'use strict';

const store = require('./store');
const alertNotification = require('./alert-notification');

/**
 * Simulates what SAP Job Scheduling Service triggers, NOT a scheduler
 * itself. This is a common misconception worth getting right: Job
 * Scheduling Service doesn't run code inside your app on a timer — it's an
 * external BTP service that HTTP-calls a registered endpoint on your app
 * per a cron-like job definition. So the correct thing to build in-app is
 * just the target endpoint (POST /jobs/nightly-digest below); "scheduling"
 * it is a job definition on the BTP service side, which this project
 * doesn't have an account to configure yet. No setInterval/cron library
 * here on purpose — that would be simulating the wrong half of the system.
 */

let lastDigestRunAt = 0;

function runNightlyDigest() {
  const since = lastDigestRunAt;
  const now = Date.now();
  const highSeverityReviews = store.listSince(since, { severity: 'HIGH' });

  let alert = null;
  if (highSeverityReviews.length > 0) {
    alert = alertNotification.publishAlert({
      severity: 'WARNING',
      subject: `${highSeverityReviews.length} HIGH-severity spend anomaly review(s) since last digest`,
      body: highSeverityReviews
        .map((r) => `${r.poNumber}: ${r.flags.map((f) => f.rule).join(', ')}`)
        .join('\n'),
      tags: { poNumbers: highSeverityReviews.map((r) => r.poNumber) },
    });
  }

  lastDigestRunAt = now;
  return {
    windowStart: since,
    windowEnd: now,
    reviewedCount: highSeverityReviews.length,
    alertPublished: Boolean(alert),
    alert,
  };
}

/** Test-only: resets the digest window so tests don't depend on run order. */
function _resetForTests() {
  lastDigestRunAt = 0;
}

module.exports = { runNightlyDigest, _resetForTests };
