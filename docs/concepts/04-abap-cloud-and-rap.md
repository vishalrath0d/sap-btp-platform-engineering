# ABAP Cloud and RAP

Theory-first doc — `supplier-master-abap` is account-gated (needs a live
BTP ABAP Environment, no local runtime exists for this at all, see
`docs/next/next.md`), so this is written from research, not from having
built the module yet. Will be revised once that's actually built.

## RAP in one paragraph

The RESTful ABAP Programming Model — the ABAP-side equivalent of CAP.
Three layers: **CDS entities** (data modeling, same CDS language family
CAP uses, ABAP-flavored), a **Behavior Definition** (declares what
operations — create/update/delete/actions — are allowed and how, plus
validations/determinations), and **Service Definition + Binding** (exposes
the result as OData v2/v4). Two implementation flavors: **managed** (RAP
generates the CRUD persistence logic — the default for something built
from scratch, which is what `supplier-master-abap` would be) and
**unmanaged** (wraps existing legacy ABAP — not relevant here, there's no
legacy system to wrap).

## Where RAP runs

- **BTP ABAP Environment** ("Steampunk") — ABAP-as-a-service, no on-prem
  NetWeaver system. This is where `supplier-master-abap` would deploy.
- **S/4HANA Cloud (embedded Steampunk)** and **S/4HANA on-prem (1909+)** —
  RAP also runs inside a real S/4HANA system, for in-app extensibility
  (see `02-extensibility-and-clean-core.md`) — not this project's path,
  named here only to be precise about where RAP applies beyond BTP.

## Development tooling

**ABAP Development Tools (ADT)** in Eclipse — already installed on this
machine (confirmed present with ADT plugins during session 1's tool
inventory, before this project even needed them). This is the real,
standard way to write RAP — not a web IDE, a proper Eclipse-based tool
with the usual ABAP debugging/testing experience.

## Version control: gCTS vs. abapGit

Both connect ABAP development to Git, but for different environments:

- **gCTS (Git-enabled Change and Transport System)** — connects the
  *classic* ABAP Change and Transport System to an external Git remote.
  Releasing a Transport Request serializes ABAP objects into files and
  pushes a commit automatically. For on-prem/private-cloud S/4HANA
  (1909+), not the BTP ABAP Environment.
- **abapGit** — the open-source Git client built specifically for the
  **BTP ABAP Environment** — this is what `supplier-master-abap` would
  actually use, not gCTS, despite gCTS being the more commonly-cited name
  in generic "SAP + Git" content. Getting this distinction right matters:
  citing gCTS for a BTP ABAP Environment project would be citing the wrong
  tool for the environment.

## Quality gates: ATC and AUnit

**ABAP Test Cockpit (ATC)** — static code analysis (naming conventions,
performance anti-patterns, security checks) run as a CI/CD quality gate,
the ABAP-side equivalent of `npmExecuteLint`/SonarQube in the Node.js
pipelines this project already has (see `08-devops-toolchain.md`).
**AUnit** — ABAP's unit test framework, the equivalent of this project's
Jest suites. Both are real, named Piper steps
(`abapEnvironmentPipeline`'s `ATC`/`AUnit` stages, confirmed against
`SAP-samples/abap-platform-ci-cd-samples`' real `config.yml` — see
`08-devops-toolchain.md` for the actual YAML).

A real, worth-knowing operational detail: ATC findings aren't always
hard-blocking. Production-grade ABAP CI/CD pipelines commonly include an
**exemption workflow** — a governed, time-limited, RAP-based Fiori tool
for temporarily suppressing a specific ATC finding with a documented
reason and an approval step, rather than either blocking every release on
every finding or disabling the check entirely. Neither extreme (zero
tolerance vs. no gate at all) is how this actually works in a mature SAP
delivery org.

## Known limitations (honesty notes)

This doc is genuinely theory-only right now — no RAP code has been
written or tested in this project. Revisit once `supplier-master-abap` is
actually built against a real BTP ABAP Environment (see
`docs/next/next.md`'s account-gated backlog) — at that point this doc
should gain the same "verified, not guessed" treatment every other
concept doc in this project already has.
