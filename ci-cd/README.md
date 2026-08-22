# ci-cd

Three parallel CI/CD tracks for `procurement-core`, all real, none of them
run automatically against the live BTP account yet (build-first,
deploy-after-review — see `PROJECT_CHARTER.md`'s account strategy).

**The actual pipeline files don't live in this folder** — each CI/CD system
has its own real, non-negotiable discovery location, and putting the files
here instead would mean they'd never actually be found and run:

| Track | Real files | Why they live there, not here |
|---|---|---|
| **Project Piper (Jenkins)** | `services/procurement-core/.pipeline/config.yml`, `services/procurement-core/Jenkinsfile` | Piper looks for `.pipeline/config.yml` and a `Jenkinsfile` in the repo/branch a Jenkins job is pointed at — that's the app's own repo root (or, in this monorepo, the service's own folder), not a shared top-level `ci-cd/` directory. |
| **GitHub Actions** | `.github/workflows/procurement-core-ci.yml` | GitHub only discovers workflows in `.github/workflows/` at the repository root — no exceptions, so this can't live in `ci-cd/` either. |
| **SAP Continuous Integration and Delivery service** | Configured in the BTP cockpit UI (job editor), *using the same `.pipeline/config.yml`* Piper already reads | This is a managed, UI-configured wrapper around the same Piper engine — there's no separate config file to place anywhere; see `sap-cicd-service/README.md`. |

This folder exists to document the three tracks side by side and explain
*why* three, not to hold duplicate copies of files that need to live
elsewhere to actually function.

## Why three tracks, not one

- **Piper on Jenkins** — the most flexible and the credible default for a
  real SAP shop (Jenkins shared library `piper-lib-os`, self-hosted or on a
  managed Jenkins). What `leverx`-style real SAP DevOps engagements
  actually run day to day, per the research behind this project's scope.
- **GitHub Actions** — no Jenkins infrastructure to host/maintain; good for
  a project this size, and what a lot of newer, smaller SAP BTP teams
  actually use. Note: SAP's own `project-piper-action` GitHub Action
  wrapper is deprecated upstream — this workflow calls `mbt`/`cf` CLI
  directly instead of trying to run Piper steps *inside* GitHub Actions.
- **SAP Continuous Integration and Delivery service** — the "no
  infrastructure to run at all" option: BTP-hosted, UI-configured, same
  Piper engine underneath. Worth knowing exists and how it differs, even
  though this project's actual CI runs happen via GitHub Actions.

All three read/build against the same `mta.yaml` and
`mtaext-dev.mtaext` — the deployable artifact and its environment-specific
overrides are the single source of truth; only the orchestration differs.
