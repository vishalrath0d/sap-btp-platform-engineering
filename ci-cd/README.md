# ci-cd

Three parallel CI/CD tracks for the whole landscape (five services), all
real, none of them run automatically against the live BTP account yet
(build-first, deploy-after-review — see `PROJECT_CHARTER.md`'s account
strategy). **Testing** is organized by *service* (each service's own
job/stage, only running when that service's own path actually changed —
real change-detection, not five separate files). **Deploying** is
organized by *runtime* (Cloud Foundry vs. Kyma) and *mechanism* (plain
CLI vs. the real Piper CLI) — see `github-actions/README.md`'s "Deploy"
section for the full routing.

**The actual pipeline files don't live in this folder** — each CI/CD system
has its own real, non-negotiable discovery location, and putting the files
here instead would mean they'd never actually be found and run:

| Track | Real files | Why they live there, not here |
|---|---|---|
| **Project Piper (Jenkins)** | `.pipeline/config.yml` (shared), `Jenkinsfile.cf`, `Jenkinsfile.kyma` | Piper looks for `.pipeline/config.yml` and a `Jenkinsfile` in the repo/branch a Jenkins job is pointed at — the repo root here, since two separate Jenkins pipeline jobs point at this one repo with different Script Paths (`Jenkinsfile.cf` / `Jenkinsfile.kyma`), a real, standard Jenkins multibranch feature for running more than one pipeline against one repo. Each pipeline's `Test` stage(s) use Jenkins's own real `when { changeset "..." }` directive to only test the service that actually changed — the same property `test.yml`'s `dorny/paths-filter` job gives on the GitHub Actions side, in Jenkins's native syntax. |
| **Project Piper (GitHub Actions)** | `.github/workflows/piper-cf-deploy.yml` | Piper isn't Jenkins-only — its steps are also a standalone Go binary (real, published on `SAP/jenkins-library`'s own GitHub releases), runnable from any CI system. `project-piper-action` (SAP's old GitHub Actions *wrapper* around that binary) is deprecated/archived upstream; this workflow installs and calls the real binary directly instead — genuinely running Piper, from GitHub Actions, post-deprecation. See `github-actions/README.md`. |
| **GitHub Actions (plain CLI)** | `.github/workflows/test.yml` (test, all 5 services, one file with real per-service change-detection), `cf-deploy.yml` (deploy, all CF services, plain `cf`), `kyma-deploy.yml` (deploy, the Kyma service, plain `kubectl`), `deploy.yml` (routes to whichever of the above, plus `piper-cf-deploy.yml`, based on a `target` input) | GitHub only discovers workflows in `.github/workflows/` at the repository root — no exceptions, so none of this can live in `ci-cd/` either. |
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
  actually use. Two real sub-paths here, not one: plain CLI calls
  (`cf`/`mbt`/`kubectl` directly — most of this track), and the real
  Piper binary (`piper-cf-deploy.yml`) for anyone who specifically wants
  to see genuine Piper steps running outside Jenkins.
- **SAP Continuous Integration and Delivery service** — the "no
  infrastructure to run at all" option: BTP-hosted, UI-configured, same
  Piper engine underneath. There's genuinely very little of this that's
  *code* — it's mostly BTP-side subscription/auth/webhook configuration
  layered on top of the same `.pipeline/config.yml` already in this repo,
  which is why `sap-cicd-service/README.md` is a setup runbook, not a
  folder of pipeline files. Worth knowing exists and how it differs, even
  though this project's actual CI runs happen via GitHub Actions.

All three read/build against the same `mta.yaml` and the same three
`.mtaext` files (`mtaext-dev.mtaext`, `mtaext-qa.mtaext`,
`mtaext-prod.mtaext`) — the deployable artifact and its environment-
specific overrides are the single source of truth; only the orchestration
differs.

## How Terraform relates to all of this

None of the three tracks above ever runs `terraform apply` themselves.
Infrastructure provisioning (`infra/terraform/terraform-apply.yml`) and
application deployment (everything in this folder) are deliberately
decoupled — see `.github/workflows/deploy.yml`'s own header comment for
the full mapping of why, and what depends on what.
