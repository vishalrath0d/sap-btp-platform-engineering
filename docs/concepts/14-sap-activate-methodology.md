# SAP Activate methodology

Why this doc exists: a pure-code portfolio project can demonstrate
technical skill, but nothing about running code demonstrates "does this
person understand how a real SAP project is actually delivered." SAP
Activate is the answer to that question, and its content is now literally
embedded in SAP Cloud ALM's own task guidance (per SAP's own
"Discovering SAP Activate" learning journey) — not a legacy methodology
being force-fit here, the current one.

## The six phases, and how this project's own phases map onto them

| SAP Activate phase | What it means | This project's matching phase (`PROJECT_CHARTER.md`) |
|---|---|---|
| **Discover** | Establish the business case, initial scoping | Phase 0 — charter, repo scaffold, domain choice (procurement) |
| **Prepare** | Project setup, environment provisioning kickoff | Phase 1 — `procurement-core` CAP service, local dev loop, Fiori UI |
| **Explore** (incl. **Fit-to-Standard** workshops) | Validate the standard/planned solution fits the real business scenario before committing infrastructure | Phases 2-3 — `ai-copilot`, `spend-anomaly-detector`, connectivity simulation, comprehensiveness gap-check — proving the business scenario and domain breadth work before committing to real infra |
| **Realize** | Build and configure the actual solution | Phase 4-5 — Terraform landing zone, XSUAA, HANA Cloud, ABAP/RAP, Kyma, CTMS |
| **Deploy** | Cutover, go-live readiness | Phase 6 — Integration Suite, Cloud ALM wiring, test hardening against real deployments |
| **Run** | Operate, optimize, continuously improve | Phase 7 — documentation polish, publishing, ongoing iteration |

The mapping isn't decorative: **Explore-before-Realize is a genuine
design decision this project made**, not just Activate-flavored labeling
after the fact. Building and locally verifying `procurement-core`,
`ai-copilot`, and `spend-anomaly-detector` — proving the business logic,
the AI feature, and the event-driven integration all work — *before*
committing to real Terraform-provisioned infrastructure is exactly the
Fit-to-Standard principle: validate the solution fits before you spend
real infrastructure cost proving it. The account strategy in
`PROJECT_CHARTER.md` ("start on trial, build everything trial-compatible
first") is Fit-to-Standard applied to a portfolio project's constraints
rather than a client's.

## Fit-to-Standard, specifically

The Explore-phase practice of validating a standard/planned solution
against real business scenarios through structured workshops, surfacing
gaps *before* build work starts on them — rather than building first and
discovering misalignment during Realize. The comprehensiveness gap-check
this project did (comparing against `ai-ml-llm-ops`, SAP's own Learning
Journeys, and real job postings, producing `docs/concepts/00-scope-boundaries.md`)
is structurally the same exercise: validate scope against real
requirements before continuing to build, rather than building on
uninterrogated assumptions about what "comprehensive" means.

## Known limitations (honesty notes)

This mapping is retrospective — the project's phases weren't originally
planned *as* Activate phases, they were reframed onto Activate once the
research surfaced how central the methodology is to how SAP itself talks
about project delivery. That's an honest thing to state plainly: the
mapping is accurate and the parallel (especially Explore/Fit-to-Standard)
is genuine, but it wasn't the starting design lens.
