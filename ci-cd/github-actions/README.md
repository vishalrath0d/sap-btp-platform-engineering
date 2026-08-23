# GitHub Actions

Real files, all at the repo root (`.github/workflows/` — GitHub only
discovers workflows there, see `ci-cd/README.md`).

## Test — one file, real change-detection, not five files

`test.yml` — a `changes` job (`dorny/paths-filter@v3`, a real, widely-used
action for exactly this) inspects which paths actually changed, then each
service's own job runs conditionally on that. This replaces five earlier
per-service files that each differed only in which path/working-directory
they used — the actual property that mattered (a change to one service
doesn't re-run every other service's tests, each PR gets a fast,
correctly-scoped status check per service) is preserved; the file count
isn't. `procurement-core` and `spend-anomaly-detector`'s jobs also carry
an extra build-verification step (`cds build` → `mbt build` producing a
real `.mtar`; a real container image build+push to GHCR) — proving the
deployable artifact actually builds, independent of whether anyone is
deploying right now.

## Deploy — one file, routes to the right mechanism

**`deploy.yml`** — a single `workflow_dispatch` with a `target` choice
input (`all` / `cf` / `kyma` / `piper-cf` / `piper-kyma`) that routes to
the right reusable workflow instead of always running everything:

- **`cf-deploy.yml`** — all four Cloud Foundry-bound services (plain `cf`
  CLI), in dependency order (`api-gateway` last, since it needs
  `procurement-core`'s live route).
- **`kyma-deploy.yml`** — `spend-anomaly-detector`'s image build+push,
  then its BTP Operator + `APIRule` manifests (plain `kubectl`).
- **`piper-cf-deploy.yml`** — the same CF deploy as `cf-deploy.yml`, but
  through the real **Piper CLI binary** instead of plain `cf`/`mbt`
  commands — see "Is Piper still real, and is it Jenkins-only?" below.
- **`piper-kyma-deploy.yml`** — the same Kyma deploy as `kyma-deploy.yml`,
  but the image build uses `piper kanikoExecute` (the real Piper CLI)
  instead of `docker/build-push-action`.

Each Piper file is an alternate *mechanism* for the same runtime target,
not a fifth/sixth thing that runs alongside the others — choosing
`piper-cf` runs instead of `cf`, not in addition to it (same for
`piper-kyma`/`kyma`).

`target: all` runs `cf-deploy.yml` + `kyma-deploy.yml` (the two primary,
plain-CLI paths, covering the whole landscape) — either Piper path is
always an explicit, separate choice, never bundled into `all`.

**`terraform apply` is not a step in `deploy.yml`.** It has its own
standalone workflow, `infra/terraform`'s `terraform-apply.yml` — see that
file's own header comment (and `deploy.yml`'s) for the full reasoning:
infrastructure (subaccount, entitlements, the CF org/space and Kyma
cluster themselves, XSUAA) changes rarely and is applied manually,
standalone, whenever the landscape itself changes; application code
(what `deploy.yml` pushes) changes on every commit that's ready to ship.
Chaining `terraform apply` automatically into every code deploy would
conflate two different lifecycles and needlessly re-touch infrastructure
state for a change that's only about code. The real dependency is a
**precondition**, not automatic chaining: `terraform-apply.yml` must have
run at least once for a given environment before `deploy.yml` can
meaningfully target it — `deploy.yml` will fail fast (cf/kubectl target a
space/cluster that doesn't exist) if run out of order, which is the
correct failure mode for a missing precondition.

All deploy workflows are real and complete but gated behind a typed
`confirm` input and a per-environment GitHub Environment (which can
require reviewers) — turning on real deployment is a repo-settings
change, not a rewrite.

## Is Project Piper still real, and is it a Jenkins thing or a GitHub Actions thing?

**Both, genuinely** — Piper's actual steps (`mtaBuild`, `cloudFoundryDeploy`,
`kanikoExecute`, ...) aren't Jenkins-specific logic; they're implemented
once, in Go, and distributed two ways: as the `piper-lib-os` **Jenkins
shared library** (Groovy wrapper calling into the same Go steps —
`Jenkinsfile.cf`/`Jenkinsfile.kyma`'s track), and as a **standalone Go
binary** published on `SAP/jenkins-library`'s own GitHub releases
(confirmed real: `wget https://github.com/SAP/jenkins-library/releases/latest/download/piper`),
runnable from anywhere a CI runner can execute a binary — GitHub Actions
included. What's genuinely **deprecated** is `project-piper-action`, SAP's
old GitHub Actions *wrapper* around that binary — archived upstream, which
is why `cf-deploy.yml`/`kyma-deploy.yml` call `mbt`/`cf`/`kubectl`
directly rather than trying to run Piper steps through it.
`piper-cf-deploy.yml`/`piper-kyma-deploy.yml` are the credible current
replacement: install the real binary, call its subcommands (`piper
mtaBuild`, `piper cloudFoundryDeploy`, `piper kanikoExecute`) directly as
CLI flags — genuinely running Piper, from GitHub Actions, post-deprecation,
one file per runtime, mirroring `Jenkinsfile.cf`/`Jenkinsfile.kyma`'s own
split on the Jenkins side.

## Secrets these need before any deploy workflow can run for real

`CF_USERNAME`/`CF_PASSWORD` (Cloud Foundry — used by both `cf-deploy.yml`
and `piper-cf-deploy.yml`), `KYMA_KUBECONFIG` (base64-encoded kubeconfig
for the Kyma cluster — used by both `kyma-deploy.yml` and
`piper-kyma-deploy.yml`), plus the four Terraform secrets
`terraform-apply.yml`/`terraform-plan.yml` need (see
`infra/terraform/README.md`) — none present in this repo, none needed
until deployment is actually turned on.
