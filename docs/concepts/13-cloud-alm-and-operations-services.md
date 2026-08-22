# Cloud ALM and operations services

Four BTP operations services, two of which are actually built and tested
in this project (Alert Notification, Job Scheduling), two of which are
documented-only (Cloud ALM, Automation Pilot) for reasons explained below.

## SAP Cloud ALM — chosen deliberately over classic Solution Manager

Cloud ALM is SAP's own forward path for application lifecycle management
on cloud-first landscapes — SAP is actively moving customers off classic
Solution Manager onto it (there's a dedicated "Transforming for Success
with SAP Cloud ALM" learning journey specifically for that migration).
This project's `docs/operations/observability.md` uses Cloud ALM as its
monitoring/ITSM-lite story for exactly that reason — see
`docs/concepts/00-scope-boundaries.md` for why classic Solution Manager
(ChaRM, Focused Build, EarlyWatch Alert) is explicitly out of scope
instead. Unit 5 of SAP's official "Discovering DevOps with SAP BTP"
learning journey is literally "Integrating DevOps Services into SAP Cloud
ALM" — this isn't a project-specific preference, it's SAP's own stated
DevOps integration point.

Not yet connected to anything real — Cloud ALM needs a live subaccount
subscription, documented here as intent, not built.

## SAP Alert Notification Service + Job Scheduling Service — actually built

`services/spend-anomaly-detector` implements both, for real:

- **`src/alert-notification.js`** — publishes ANS-shaped alert events
  (`eventType`, `resource`, `severity`, `subject`/`body`, `tags`) when a
  HIGH-severity spend review needs escalation. The real ANS ingestion API
  shape should be re-verified before an actual production integration —
  documented as a simulation close to, not identical to, the real API.
- **`src/job-scheduler.js`** — deliberately has **no in-app
  cron/setInterval**. This is the one genuinely important conceptual point
  here: SAP Job Scheduling Service doesn't run code inside your app on a
  timer — it's an external BTP service that HTTP-calls a *registered
  endpoint* on your app per a cron-like job definition configured on the
  BTP side. So the correct thing to build in-app is the target endpoint
  (`POST /jobs/nightly-digest`), not a scheduler. Getting this backwards —
  building an in-app scheduler — would be simulating the wrong half of the
  system.

Verified live: a digest run with zero HIGH-severity reviews in its window
publishes no alert; a HIGH-severity review triggers a real published
alert; a second consecutive run only looks at the new time window, not the
same review twice (19/19 tests, see that service's test suite).

## SAP Feature Flags service — also actually built

`src/feature-flags.js` — same service, same pattern: `ROUND_NUMBER_AMOUNT_RULE`
toggleable at runtime via `PUT /admin/flags/:name`, with a same-process
before/after test proving the toggle changes behavior without a restart
(the entire point of a feature-flag service — an env var can't do that).

## SAP Automation Pilot

A named BTP service (300+ built-in operational-automation procedures) —
real jobs.sap.com DevOps postings name it directly. Not built here; the
honest connection to make is that this project's own manual troubleshooting
work (documented real bugs across every service's README — the macOS
toolchain issue, the CAP action-naming collision, the `cf push`-poisons-
process-command gotcha noted in `08-devops-toolchain.md`) is exactly the
kind of repeatable operational procedure Automation Pilot exists to codify
and automate. A concrete future exercise: pick one of those documented
manual fixes and write the Automation Pilot procedure that would apply it
automatically, as a design note under `docs/operations/sre-practices.md`
— not done yet, named here as the natural next step.

## Known limitations (honesty notes)

Cloud ALM and Automation Pilot are genuinely undemonstrated — no BTP
subscription/procedure has been created for either. Alert Notification
and Job Scheduling are real, tested code, but their event shapes are
close-approximations of the real APIs, not verified against live SAP
service documentation for exact field-name correctness.
