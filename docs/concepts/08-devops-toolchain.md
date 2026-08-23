# The SAP-native DevOps toolchain

## CALMS, briefly — the framework this toolchain actually serves

**C**ulture, **A**utomation, **L**ean, **M**easurement, **S**haring — the
standard framework for what "DevOps maturity" concretely means, and one
SAP's own BTP interview/learning material leans on repeatedly. Worth
stating plainly rather than assumed: everything below (Piper, MTA Build
Tool, CTMS, gCTS) is the **Automation** pillar. This project's staged git
commits, honesty-notes documentation pattern, and cross-referenced concept
docs are attempts at the **Sharing**/**Measurement** pillars — a toolchain
alone isn't DevOps maturity, the practices around it are.

## The toolchain, real and verified in this project

| Tool | What it does | Verified how |
|---|---|---|
| **Cloud MTA Build Tool (`mbt`)** | Reads `mta.yaml`, builds each module, packages a `.mtar` | Ran `mbt build --platform cf` for real — produced actual HDI artifacts and a working `.mtar` (see `mta.yaml`'s commit) |
| **Project Piper** | CI/CD steps (`mtaBuild`, `cloudFoundryDeploy`, `tmsUpload`, `abapEnvironmentPipeline`) — a Jenkins shared library, also the engine under the managed SAP CI/CD service | `.pipeline/config.yml`'s step parameters checked against `SAP/jenkins-library`'s real step metadata, not memory |
| **SAP Continuous Integration and Delivery service** | Managed, cockpit-configured Piper — no Jenkins to host | Documented (`ci-cd/sap-cicd-service/README.md`), not yet activated — needs the account |
| **Cloud Transport Management (CTMS)** | Promotes an `.mtar` (or ABAP transport, via gCTS) across Dev→QA→Prod nodes/routes | Scoped, account-gated (`transport/cloud-transport-management`) |
| **gCTS / abapGit** | Git-backed ABAP transport — see `04-abap-cloud-and-rap.md` for which applies where | Documented, account-gated |

## MTA resource types: a distinction worth getting right

`mta.yaml`'s `procurement-core-xsuaa` resource uses
`org.cloudfoundry.managed-service` — a fresh service instance, created and
owned by this MTA. The alternative, **`org.cloudfoundry.existing-service`**,
binds to a service instance that *already exists*, created outside this
MTA — the real pattern for a **shared/central XSUAA instance** used across
multiple independently-deployed MTAs in the same landscape (common in a
multi-app subaccount, so every app trusts the same identity zone rather
than each minting its own). `procurement-core` uses `managed-service`
because it's the only app in this subaccount right now; a second app
joining the landscape later would be the trigger to reconsider this,
switching that second app's XSUAA resource to `existing-service` pointing
at `procurement-core`'s instance rather than each app creating its own.

## Quality gates beyond tests

Piper's `stages`/`steps` toggles in `.pipeline/config.yml` currently run
`npmExecuteLint` (non-blocking — no lint config committed yet, flagged
honestly rather than left silently toothless, see that file's comment)
and `npmExecuteScripts` (the real Jest suite). Two real, named Piper steps
not yet wired in, worth knowing about: **`sonarExecuteScan`** (SonarQube —
static analysis, code smells, security hotspots) and
**`whitesourceExecuteScan`** (dependency/SCA scanning — the modern
successor is Mend, still often referenced by its old WhiteSource step
name in Piper). Both are real SAP job-posting-mentioned quality gates for
SAP DevOps roles, not generic filler.

## A concrete gap: no e2e test stage yet

SAP's own `devops-cap-pipeline-openSAP` companion repo (the "Efficient
DevOps with SAP" learning material) demonstrates wiring **UIVeri5** e2e
tests into a Piper pipeline stage, switchable between a local
`localhost:4004` target and the real deployed URL. `.pipeline/config.yml`
has no equivalent stage yet — a real gap versus that reference pattern,
worth adding once there's a deployed environment for e2e tests to actually
run against (testing e2e against nothing deployed would be theater, not a
real gate).

## Known limitations (honesty notes)

Piper/MTA Build Tool are verified by actually running them; CTMS and
gCTS/abapGit are written (`transport/cloud-transport-management`'s real
node/route config, `services/supplier-master-abap`'s real RAP source) but
not run — both are genuinely account-gated for the *provisioning/apply*
step, see `docs/next/next.md` and `PROJECT_CHARTER.md`'s "Scope expansion
(session 7/8)" sections.
