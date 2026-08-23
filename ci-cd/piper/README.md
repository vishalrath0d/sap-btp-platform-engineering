# Project Piper (Jenkins)

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

## Verified, not guessed

Every step name and parameter (`mtaBuild`, `cloudFoundryDeploy`'s
`deployTool: cf_native` shape — `cloudFoundry.org`/`space`/
`credentialsId`/`apiEndpoint`, `manifest` defaulting to `manifest.yml` —
`kanikoExecute`) was checked against `SAP/jenkins-library`'s real step
metadata and the current project-piper.io docs while building this
project, not written from memory.

## Not yet wired up

- No Jenkins server exists for this project yet — there's nothing to
  actually run either pipeline against. The files are real and complete;
  running them is an account-and-infrastructure-gated next step.
- Both Jenkinsfiles' deploy stages are gated behind `when { expression {
  false } }` — this project's Groovy equivalent of every GitHub Actions
  workflow's `if: false`, same build-first, deploy-after-review posture.
- `tmsUpload` (Cloud Transport Management promotion) is commented out in
  `.pipeline/config.yml` — see `transport/cloud-transport-management`.
