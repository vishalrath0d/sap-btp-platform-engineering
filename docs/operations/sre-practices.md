# SRE practices

## Incident runbooks

### 1. `spend-anomaly-detector` unreachable — verified real behavior, not a hypothetical

**Symptom**: `procurement-core`'s `approve()` action logs
`[events] could not reach spend-anomaly-detector (...) - PO <number> was
still created` (see `srv/lib/events.js`).

**What actually happens** (verified, not assumed): PO creation
**succeeds regardless**. `procurement-core`'s full test suite (17/17)
passes with `spend-anomaly-detector` not running at all — proven, not
just designed that way. The event publish is fire-and-forget by design,
matching how a real pub/sub producer behaves toward an unreachable
consumer.

**Response**: not an emergency — no PO creation is blocked. Restart
`spend-anomaly-detector`; it has no replay/backfill mechanism for missed
events (a real limitation, documented in that service's README), so any
POs created during the outage window won't retroactively get an anomaly
review. Worth knowing before treating this as fully self-healing: it's
resilient to the *producer* side, not automatically consistent on the
*consumer* side.

### 2. Unexpected 403s on a procurement action

**Symptom**: a user who should be able to perform an action (submit,
approve, sync) gets `403`.

**Diagnosis path**: check the mocked-auth user's roles
(`package.json`'s `cds.requires.auth.users`, locally) or, once deployed,
the real XSUAA role collection assignment. Verified real example from
this project's own testing: `alice` (Requester-only) correctly gets `403`
attempting `approve()` — the RBAC model is doing its job; the fix in that
case is assigning the right role collection, not debugging the app.

**Real trap once deployed for real**: XSUAA's `xsappname` gets suffixed
at runtime (`procurement-core!t12345`, not the bare `xsappname` from
`xs-security.json`) — a role collection referencing the wrong
(un-suffixed) app ID would silently never grant anything. See
`infra/terraform/modules/xsuaa`'s comments for why this project's
Terraform handles this as a deliberate two-phase apply rather than
guessing the suffix.

### 3. Failed CTMS transport import (documented intent, account-gated)

Not yet verified against a real transport, since `transport/cloud-
transport-management` is account-gated. Documented from a real bug in a
reference project's troubleshooting notes (see `08-devops-toolchain.md`
and `mtaext-dev.mtaext`'s own header comment): a missing or duplicate
`ID` field in an `.mtaext` file fails `cf deploy`/CTMS import at
*validation*, not at runtime — this project's `mtaext-dev.mtaext` already
has a unique `ID` (`procurement-core-dev`, distinct from the base MTA's
`procurement-core`) specifically because this was a known real failure
mode to design around up front, not discover the hard way.

### 4. `cf push` after MTA deploy poisons the process command (documented intent, account-gated)

A real, documented bug from reference-project research (`08-devops-
toolchain.md`): running `cf push` with a manual manifest *after* an MTA
deploy is already set up doesn't get cleanly overwritten by the next MTA
deploy — CF's process command sticks. **The runbook here is prevention,
not recovery**: once `procurement-core` is deployed via MTA for the first
time, never `cf push` it manually again — always `cf deploy`/MTA.

## MTTD/MTTR tracking template

| Incident | Detected via | MTTD | MTTR | Root cause |
|---|---|---|---|---|
| _(none yet — no incidents have occurred against a real deployment)_ | | | | |

Left empty deliberately rather than populated with invented numbers —
this table gets real rows once real incidents happen against a real
deployment, matching this project's standard elsewhere of never asserting
a measured number that wasn't actually measured.

## HA/DR — a named gap, not silently missing

SAP's own "Operating SAP Business Technology Platform" learning journey
dedicates a unit specifically to High Availability and Disaster Recovery
— this project has no HA/DR design at all yet (a single Cloud Foundry
org/space, a single HDI container, no cross-region replication story).
Worth stating as an explicit gap rather than letting the absence go
unremarked: a real production SAP BTP deployment would need a documented
RTO/RPO target and a concrete DR approach (HANA Cloud has native
cross-region replication options) before going live, none of which this
project has designed yet.

## SAP Automation Pilot — a future exercise, not built

Runbooks #3 and #4 above are exactly the kind of repeatable manual
procedure **SAP Automation Pilot** (300+ built-in operational-automation
procedures, named directly in real SAP DevOps job postings) exists to
codify and run automatically instead of manually. A concrete next step,
not done yet: pick runbook #2's "check role collection assignment,
correct the XSUAA suffix mismatch" and write it as an Automation Pilot
procedure definition — smaller and more concrete than trying to automate
everything in this doc at once.
