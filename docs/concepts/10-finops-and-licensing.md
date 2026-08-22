# FinOps, licensing, and compliance design notes

## BTP consumption pricing and CPEA

BTP's commercial model is consumption-based: a **CPEA (Cloud Platform
Enterprise Agreement)** is a pre-purchased credit pool drawn down by
actual service usage, rather than fixed per-seat/per-instance licensing.
The trial and free tier (see `01-sap-btp-fundamentals.md`) sit outside
this — free tier specifically is quota-capped rather than metered, with
only a card-verification hold, no CPEA credit consumption. This project
hasn't touched a CPEA-billed account at all (trial + free tier only), so
this section is deliberately brief — real CPEA cost governance (rate
cards, consumption alerts, chargeback) is a distinct topic this project's
scope doesn't reach.

## Digital Access licensing — a short, honest note

SAP's **Digital Access** model licenses indirect/digital access to
S/4HANA based on the *documents created* (sales orders, purchase orders,
etc.), regardless of which system or user created them. Relevant here
because ProcureIQ's whole domain is literally document creation — Purchase
Requisitions converting into Purchase Orders. In a genuine S/4HANA-
integrated deployment (not this project's current standalone scope),
every PO `procurement-core` generates could be a Digital Access-licensable
document, which is exactly the kind of cost consideration a real BTP
extension project has to account for and this project's scope doesn't
currently touch (there's no real S/4HANA system behind `procurement-core`
to generate licensable documents against). Named here so the concept is
documented, not because this project has done Digital Access licensing
analysis for real.

## A compliance design note: NISPG, DPDP Act, CERT-In

**Explicitly a design-awareness note, not a claim of built capability** —
see `docs/concepts/00-scope-boundaries.md`'s discipline: this project does
not simulate sovereign-cloud infrastructure, and this section should never
be read as claiming it does.

For context: **NISPG** (National Information Security Policy & Guidelines,
India's Ministry of Home Affairs) and the **DPDP Act** (Digital Personal
Data Protection Act, 2023) are the India-specific regulatory frameworks
that govern data residency/handling for a genuinely sovereign-cloud SAP
deployment. **CERT-In** additionally mandates a strict **6-hour incident
reporting window** for security incidents — far tighter than most
generic SRE incident-response SLAs, and worth knowing as a real constraint
if this project's SRE runbooks (`docs/operations/sre-practices.md`) were
ever extended toward an India-sovereign-cloud context specifically.

If this Terraform landing zone were provisioned under real sovereign-cloud
requirements, the concrete controls that would apply: region-locked
subaccounts (`infra/terraform`'s `region` variable already expresses this
mechanically — real sovereign-cloud governance goes considerably further,
e.g. dedicated infrastructure and personnel with security clearance, none
of which this project has or claims to have), DPDP Act data-localization
principles applied to wherever `procurement-core`'s data actually lives,
and a CERT-In-style 6-hour reporting SLA folded into incident runbooks
instead of a generic one. That's the extent of this project's engagement
with sovereign cloud: naming what would be different, not building it.

## Known limitations (honesty notes)

This entire doc is lighter than most others in this project on purpose —
FinOps and compliance depth genuinely requires a live, billed account to
demonstrate for real (rate cards, actual consumption data, an actual
compliance audit), none of which a trial account provides. Padding this
doc with more generic content than that would contradict the project's
own "verified, not aspirational" standard.
