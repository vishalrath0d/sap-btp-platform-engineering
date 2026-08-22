# Security: XSUAA, role collections, and identity

Destination service and Cloud Connector get their own deep dive in
`11-connectivity-cloud-connector.md` (with a sequence diagram and a real,
verified `syncLegacySuppliers` example) — this doc covers the other half
of BTP security: **who you are** (XSUAA, Cloud Identity Services) rather
than **what you're allowed to reach** (Destination/Cloud Connector).

## XSUAA in this project, concretely

Every piece of the RBAC story in this project is real, not simulated —
the only thing that's simulated is *how identity gets asserted* (mocked
locally, real XSUAA once deployed):

- **`services/procurement-core/xs-security.json`** — the actual security
  descriptor: three scopes (`Requester`, `Approver`, `IntegrationAdmin`),
  matching role-templates, and role-collections declared inline (XSUAA can
  auto-provision these at bind time on some plans).
- **`srv/service.cds`**'s `@requires: 'Requester'` / `'Approver'` /
  `'IntegrationAdmin'` annotations — enforced by CAP *before* any handler
  code runs, whether the identity behind them came from mocked auth
  (`alice`/`bob`/`carol`/`dave`, locally) or a real XSUAA JWT (once
  deployed). Verified concretely: `alice` (Requester only) gets a real
  `403` calling `approve()`; the exact same annotation, unchanged, would
  produce the exact same `403` against a real XSUAA token lacking the
  `Approver` scope.
- **`infra/terraform/modules/xsuaa`** and **`modules/role-collections`** —
  provisions the real XSUAA service instance/binding and (once the
  genuinely two-phase apply completes — see that module's comments) the
  real role collections, from the same `xs-security.json`.

Nothing about the RBAC *model* changes between local dev and a real
deployment — only how identity is asserted changes, and that's entirely
inside CAP's auth-strategy config (`mocked` → `xsuaa`), not in the
`@requires` annotations or the handler code at all.

## Principal propagation

The mechanism by which an end user's identity flows through a chain of
calls — app → another BTP service → (via Cloud Connector) an on-prem
system — so the on-prem system sees the real end user, not a generic
technical user. Relevant to `syncLegacySuppliers`
(`11-connectivity-cloud-connector.md`) in principle: a real production
version reaching a genuinely access-controlled legacy system would use
principal propagation rather than the `NoAuthentication` the local
simulation uses (fine there, since `legacy-erp-gateway` has no auth of its
own to propagate into).

## Cloud Identity Services vs. XSUAA — two different layers

Easy to conflate, genuinely different scopes:

- **XSUAA** — app-level. OAuth2/JWT, scopes, role collections — governs
  what an authenticated user can *do* inside a specific app (exactly what
  `xs-security.json` above defines).
- **SAP Cloud Identity Services** (Identity Authentication + Identity
  Authorization) — tenant-level. The actual identity provider/SSO layer:
  where user accounts live, how they authenticate (password, SAML,
  corporate IdP federation), before XSUAA ever gets involved in deciding
  what they're allowed to do.

This project's local dev uses CAP's mocked auth for the XSUAA layer and
has no Cloud Identity Services story at all (not simulated, not built) —
a real deployment would sit XSUAA behind a real Cloud Identity Services
tenant, which is genuinely out of this project's local-testable reach
(it's a tenant-level BTP configuration, not something an app's own code
or Terraform module meaningfully simulates) — named here so the
distinction is documented, not silently missing.

## Kyma's connectivity model differs from Cloud Foundry's — a real trap

Cloud Foundry apps get an **App Router** by default, which handles
Destination-service lookups and routing transparently. **Kyma doesn't
ship an App Router by default** — reaching a Destination-service-backed
target from a Kyma workload needs an explicit **Connectivity Proxy /
Transparent Proxy** sidecar wired in, or the call silently fails to
resolve the way it would from a CF app. This is a real, documented "it
worked on Cloud Foundry, why doesn't it work on Kyma" trap, not a
theoretical concern — worth remembering specifically because
`spend-anomaly-detector` (this project's Kyma-targeted service, currently
account-gated) will need this wired correctly once it's actually deployed
to Kyma rather than run locally as a plain Node process.
