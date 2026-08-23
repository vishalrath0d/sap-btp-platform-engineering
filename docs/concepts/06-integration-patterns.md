# Integration patterns: Integration Suite, Event Mesh, API Management

## The decision framework

SAP's **Integration Solution Advisory Methodology** (part of the [BTP
Guidance Framework](https://discovery-center.cloud.sap/guidance-framework),
alongside the Application Extension Methodology cited in
`02-extensibility-and-clean-core.md`) is the official decision tree for
*which* integration pattern fits a given scenario — point-to-point API
call, event-driven, batch, or a full iPaaS flow. This project's own choices
below follow that framework's logic even though the framework itself
wasn't consulted mechanically for each one — noted here because citing the
real decision framework is more credible than presenting each choice as
ad hoc.

## Three integration shapes, three places they show up in this project

| Shape | SAP-native tool | Where it appears here |
|---|---|---|
| **Event-driven, async** | Event Mesh (topic pub/sub) | `spend-anomaly-detector` — `procurement-core` publishes `PurchaseOrderCreated`, `spend-anomaly-detector` reacts. Currently an HTTP webhook locally (see that service's README for exactly why and what changes for real Event Mesh) |
| **Point-to-point, sync, on-prem-adjacent** | Destination service + Cloud Connector | `syncLegacySuppliers` — see `11-connectivity-cloud-connector.md` |
| **iPaaS flow (orchestration, mapping, protocol translation)** | Integration Suite / Cloud Integration (CPI), iFlows | `services/integration-flow` — real BPMN2 `.iflw` + Groovy mapping script written, not yet importable-verified: Cloud Integration's iFlow designer is a cloud-only tool with no local authoring/testing story at all, unlike the other two shapes above which could be meaningfully simulated locally |

## Integration Suite / Cloud Integration (CPI), briefly

An iPaaS: visual iFlow designer for connecting SAP and non-SAP systems —
adapters (OData, SOAP, REST, IDoc, RFC/BAPI, SFTP, JDBC, AMQP), Groovy/
JavaScript scripting for message mapping, plus **API Management** for
exposing/governing APIs (rate limiting, API keys, usage analytics, an API
Business Hub-style catalog) as a related but distinct capability within
the same Suite.

`services/integration-flow`'s intended scenario (per
`PROJECT_CHARTER.md`): an iFlow simulating ingestion from the same kind of
legacy/non-SAP supplier feed `legacy-erp-gateway` already represents for
the Destination/Cloud Connector story — the difference being *orchestration
and mapping happening inside CPI itself*, vs. `syncLegacySuppliers`'s
mapping logic living in `procurement-core`'s own code
(`srv/lib/legacy-supplier-mapper.js`). Both are legitimate integration
patterns for the same underlying problem; which one a real project picks
depends on exactly the kind of tradeoff the Integration Solution Advisory
Methodology exists to formalize (does the mapping logic belong in the
app, or in a dedicated integration layer a non-developer can maintain?).

## API Management

The governance layer for exposing an API to consumers outside the app
that owns it — API keys, rate limiting/quota policies, request/response
transformation, and an API Business Hub-style discoverable catalog entry.
`procurement-core`'s OData service is currently consumed directly, with no
API Management layer in front of it — see `docs/next/next.md`'s backlog
for this as a planned addition (a documented catalog entry + policy
description, not a full API Management service instance, which needs the
account).

## Event Mesh, briefly

BTP's managed AMQP-based pub/sub broker. `spend-anomaly-detector`'s
README already documents in detail why this project uses a plain HTTP
webhook locally instead of standing up a real broker, and what specifically
changes (transport only, not the event-driven design itself) once a real
Event Mesh instance is available — not repeated here, see that service's
README for the full reasoning and a sequence-level walkthrough.

## Known limitations (honesty notes)

`services/integration-flow` remains genuinely unbuilt — this doc describes
the *intended* scenario, not a working iFlow. Unlike the connectivity
story (`11-connectivity-cloud-connector.md`), there's no meaningful local
simulation possible here: CPI's iFlow designer has no local/offline
authoring mode at all.
