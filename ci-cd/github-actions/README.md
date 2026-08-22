# GitHub Actions

Real file: `.github/workflows/procurement-core-ci.yml` (repo root — GitHub
only discovers workflows there, see `ci-cd/README.md`).

## Jobs

1. **`test`** — checkout, `npm ci`, `npm test`. Same 17 tests that pass
   locally, run in CI.
2. **`build-mta`** — `cds build --production` → `mbt build --platform cf`
   → uploads the resulting `.mtar` as a workflow artifact. Runs the exact
   same commands verified locally while building `mta.yaml` (see that
   file's commit history) — nothing new invented for CI specifically.
3. **`deploy-dev`** — real, complete, but **`if: false`** and gated behind
   a GitHub Environment requiring manual approval. Turning on real
   deployment later is a repo-settings change (add required reviewers to
   the `dev` environment, flip the `if`), not a rewrite — deliberate, so
   this workflow doesn't need touching again once the account review
   happens.

## Why not SAP's Piper GitHub Action

SAP shipped `project-piper-action` as a GitHub Actions wrapper around
Piper steps, but it's deprecated/archived upstream — Piper's GitHub
Actions story moved to SAP's internal tooling. This workflow calls
`mbt`/`cf` CLI directly instead, which is the credible, currently-real path
for GitHub Actions + SAP BTP, not a workaround.

## Secrets this needs before `deploy-dev` can run for real

`CF_USERNAME`, `CF_PASSWORD` as GitHub Actions secrets (or a service
account's credentials, for a real non-trial landscape) — not present in
this repo, not needed until deployment is actually turned on.
