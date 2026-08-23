# Project Piper (Jenkins) — and, separately, on GitHub Actions

Piper isn't Jenkins-only. Its real steps (`mtaBuild`, `cloudFoundryDeploy`,
`kanikoExecute`, ...) are implemented once, in Go, and shipped two ways:
the `piper-lib-os` Jenkins shared library (this page, `Jenkinsfile.cf`/
`Jenkinsfile.kyma`), and a standalone Go binary anyone can run from any
CI system — including GitHub Actions, via
`.github/workflows/piper-cf-deploy.yml` (see `ci-cd/github-actions/
README.md`'s "Is Project Piper still real..." section for the full
Jenkins-vs-GitHub-Actions story, and why `project-piper-action`, SAP's
old GitHub Actions *wrapper*, is deprecated but the binary itself isn't).

## The Jenkins track

Real files: `.pipeline/config.yml` (repo root, shared), `Jenkinsfile.cf`,
`Jenkinsfile.kyma` (also repo root) — see `ci-cd/README.md` for why they
live there, not here, and for why two Jenkinsfiles rather than one.

## Two pipelines, split by runtime, not by service

- **`Jenkinsfile.cf`** — the whole Cloud Foundry-bound landscape:
  `procurement-core` (MTA, via `mtaBuild` + `cloudFoundryDeploy` with
  `mtaDeployPlugin`), `ai-copilot`/`api-gateway`/`legacy-erp-gateway`
  (plain `cf push`, via `cloudFoundryDeploy` with `deployTool: cf_native`).
  Explicit scripted stages, not the implicit `piperPipeline script: this`
  form alone — this pipeline calls `cloudFoundryDeploy` four times with
  three different parameter sets, which the implicit form (one global
  parameter set per step name, from config.yml) can't express. This
  project's own note in `Jenkinsfile.cf` covers the reasoning in full;
  explicit stages are real, valid Piper usage, not a workaround.
- **`Jenkinsfile.kyma`** — `spend-anomaly-detector`: `kanikoExecute` for a
  daemonless container build+push (the standard choice on a Jenkins agent
  without Docker-in-Docker), then plain `kubectl`/`envsubst` steps for the
  BTP Operator `ServiceInstance`/`ServiceBinding` + `APIRule` sequence —
  no single Piper step expresses "provision, wait for the binding, read a
  real value out of its Secret, template it into another manifest, apply
  that," the same reasoning `.github/workflows/kyma-deploy.yml` documents
  for using raw `kubectl` there too.

Both read the same shared `.pipeline/config.yml` (Piper's steps
default-load one config file per checkout, whether called via the
implicit orchestrator or explicit stages) for what's genuinely common
(`general.buildTool`, lint/test toggles); per-module deploy parameters
that differ between apps live in each Jenkinsfile's explicit stage calls.

Both pipelines' `Test` stage(s) also use Jenkins Declarative Pipeline's
own real `when { changeset "services/<name>/**" }` directive — a change
to one service's files doesn't trigger every other service's test stage,
the same real change-detection property `.github/workflows/test.yml`'s
`dorny/paths-filter` job gives on the GitHub Actions side, expressed in
Jenkins's own native syntax rather than a third-party action.

## Verified, not guessed

Every step name and parameter (`mtaBuild`, `cloudFoundryDeploy`'s
`deployTool: cf_native` shape — `cloudFoundry.org`/`space`/
`credentialsId`/`apiEndpoint`, `manifest` defaulting to `manifest.yml` —
`kanikoExecute`) was checked against `SAP/jenkins-library`'s real step
metadata and the current project-piper.io docs while building this
project, not written from memory.

## The GitHub Actions track

`.github/workflows/piper-cf-deploy.yml` — installs the real `piper`
binary (`wget https://github.com/SAP/jenkins-library/releases/latest/
download/piper`, confirmed real and current) and calls `piper mtaBuild` /
`piper cloudFoundryDeploy` directly as CLI subcommands, scoped to
`procurement-core`/CF only (matching `Jenkinsfile.cf`'s own scope - no
Kyma-via-Piper-on-GitHub-Actions path, `kyma-deploy.yml` already covers
Kyma via plain `kubectl` for the same reasoning `Jenkinsfile.kyma` gives).
Its CLI flag names are sourced from `piper mtaBuild --help`/
`cloudFoundryDeploy --help` and project-piper.io's docs, not yet
confirmed against a live run (no Jenkins/Piper-CLI execution has happened
in this project so far) — flagged the same way this project flags every
not-yet-live-verified piece, not asserted with false confidence.

## Not yet wired up

- No Jenkins server exists for this project yet — there's nothing to
  actually run either Jenkins pipeline against. The files are real and
  complete; running them is an account-and-infrastructure-gated next step.
- Both Jenkinsfiles' deploy stages are gated behind `when { expression {
  false } }` — this project's Groovy equivalent of every GitHub Actions
  workflow's `if: false`, same build-first, deploy-after-review posture.
- `piper-cf-deploy.yml`'s CLI invocation hasn't been run live yet either -
  see "The GitHub Actions track" above.
- `tmsUpload` (Cloud Transport Management promotion) is commented out in
  `.pipeline/config.yml` — see `transport/cloud-transport-management`.
