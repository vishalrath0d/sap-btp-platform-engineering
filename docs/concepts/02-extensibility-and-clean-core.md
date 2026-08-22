# Extensibility and Clean Core

## The principle

Clean Core: never modify SAP's standard code or data model directly.
Extend around it instead, over stable released APIs, from BTP. The
payoff is upgrade safety — SAP can update S/4HANA underneath you without
your customizations breaking, because there are no customizations *inside*
the core to break. Every service in this repo is a Clean Core extension by
construction: none of them would modify a hypothetical S/4HANA
procurement table even if one existed here to point at.

## Two extensibility styles, and how SAP itself frames the choice

- **Side-by-side extensibility** — a separate app on BTP, calling the core
  system's released APIs/events. This is what `procurement-core` is: an
  independent CAP service, not a modification living inside anything.
- **In-app (on-stack) extensibility** — small, governed extension points
  *inside* the S/4HANA Cloud system itself (extension fields, key user
  Fiori apps, in-app CDS extensions) — for changes too tightly coupled to
  core business logic to sensibly live outside it.

SAP's own **Application Extension Methodology** (part of the [BTP Guidance
Framework](https://discovery-center.cloud.sap/guidance-framework)) is the
official decision framework for choosing between these two — this
project's own choice (side-by-side, CAP-based) follows that framework's
default recommendation for a new, independent business capability rather
than a one-off field addition, not an arbitrary preference.

## CAP vs. RAP — the same decision one level down

Once side-by-side is the answer, there's a second choice: which
programming model.

| | CAP | RAP |
|---|---|---|
| Language | Node.js, Java, TypeScript | ABAP |
| Runtime | Cloud Foundry, Kyma | BTP ABAP Environment, S/4HANA Cloud (embedded) |
| Data modeling | CDS (multi-language, framework-agnostic) | CDS (ABAP-flavored) + Behavior Definitions |
| Best fit | New, standalone business capabilities; teams without deep ABAP investment | Extensions that need to sit close to S/4HANA data/logic; ABAP-skilled teams |

`procurement-core` is CAP because procurement is a standalone capability
with no existing ABAP investment to build on. `supplier-master-abap`
(account-gated, not yet built — see `PROJECT_CHARTER.md`) deliberately
picks RAP instead, specifically to demonstrate the *other* half of this
decision, not because the domain required it — a real team would usually
default to one model, not deliberately split like this repo does for
teaching purposes.

## Why this matters for a DevOps/platform engineer specifically

Clean Core isn't just an architectural nicety — it's the reason SAP BTP
DevOps looks the way it does. Side-by-side extensions are independently
deployable (their own CI/CD pipeline, their own release cadence), which is
*why* Piper/CTMS/gCTS exist as a distinct toolchain from classic on-prem
ABAP transport management: Clean Core created a class of software that
needed cloud-native delivery practices, on a platform SAP had to build for
exactly that purpose. Understanding Clean Core is understanding why BTP
DevOps is a distinct discipline from classic SAP Basis work at all — see
`docs/concepts/00-scope-boundaries.md` for exactly where that line is
drawn in this project.
