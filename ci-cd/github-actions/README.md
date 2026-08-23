# GitHub Actions

Real files, all at the repo root (`.github/workflows/` — GitHub only
discovers workflows there, see `ci-cd/README.md`), organized the same way
the Piper track is: test per service, deploy per runtime.

## Test — one workflow per service, path-filtered

`procurement-core-ci.yml`, `ai-copilot-ci.yml`, `api-gateway-ci.yml`,
`legacy-erp-gateway-ci.yml`, `spend-anomaly-detector-ci.yml` — each runs
`npm ci && npm test` (and, for `procurement-core`/`spend-anomaly-detector`,
an extra build-verification job: `cds build --production` → `mbt build`
producing a real `.mtar` artifact; a real container image build+push to
GHCR) on every PR touching that service's own `services/<name>/**` path.
This split is real, standard monorepo CI practice — a change to one
service shouldn't re-run every other service's tests, and each PR gets a
fast, correctly-scoped status check per service.

## Deploy — one workflow per runtime, not per service

- **`cf-deploy.yml`** — deploys all four Cloud Foundry-bound services
  (`procurement-core` via `cf deploy` against its `.mtar`, the other three
  via `cf push`), in dependency order (`api-gateway` last, since it needs
  `procurement-core`'s live route).
- **`kyma-deploy.yml`** — builds and pushes `spend-anomaly-detector`'s
  container image, then applies its BTP Operator + `APIRule` manifests.
- **`deploy-all.yml`** — one `workflow_dispatch` running `terraform apply`
  then both of the above, in order, for a genuinely one-shot "deploy the
  whole landscape" trigger.

All three are real and complete but gated behind a typed `confirm` input
and a per-environment GitHub Environment (which can require reviewers) —
turning on real deployment is a repo-settings change (add reviewers,
trigger the workflow), not a rewrite. `cf-deploy.yml`/`kyma-deploy.yml`
are also real reusable workflows (`workflow_call`) — `deploy-all.yml`
invokes them rather than duplicating their steps a second time.

Deploying by *runtime* rather than by *service* mirrors how these five
services actually relate: the four CF-bound ones are a bound landscape
(`api-gateway` calls `procurement-core`, which calls
`legacy-erp-gateway`), not four independently-released products, so one
pipeline sequencing them correctly is more honest than four separate
gated jobs that happened to live in different files. It's specifically
*testing* that benefits from staying split by service, not deploying.

## Why not SAP's Piper GitHub Action

SAP shipped `project-piper-action` as a GitHub Actions wrapper around
Piper steps, but it's deprecated/archived upstream — Piper's GitHub
Actions story moved to SAP's internal tooling. These workflows call
`mbt`/`cf`/`kubectl` CLIs directly instead, which is the credible,
currently-real path for GitHub Actions + SAP BTP, not a workaround.

## Secrets these need before any deploy workflow can run for real

`CF_USERNAME`/`CF_PASSWORD` (Cloud Foundry), `KYMA_KUBECONFIG`
(base64-encoded kubeconfig for the Kyma cluster), plus the four Terraform
secrets `deploy-all.yml` also needs (see `infra/terraform/README.md`) —
none present in this repo, none needed until deployment is actually
turned on.
