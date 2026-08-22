# Environment posture: dev, qa, prod

## What actually exists today

One real environment: **local dev**, running all four services
(`procurement-core`, `ai-copilot`, `spend-anomaly-detector`,
`legacy-erp-gateway`) as plain Node processes, SQLite/in-memory storage,
mocked auth. `infra/terraform/environments/dev` is the BTP-hosted `dev`
environment, written and validated, not yet applied.

`qa` and `prod` are honest stubs (`infra/terraform/environments/{qa,prod}`)
— the BTP **trial** provides exactly one subaccount total, so there's no
second or third subaccount to promote into yet. This is a real, structural
constraint, not an oversight: real Dev→QA→Prod promotion needs a paid (or
free-tier) landscape with multiple subaccounts, which is why
`transport/cloud-transport-management` (the thing that would actually
promote content between them) stays account-gated too.

## What each environment's posture would be, once it exists for real

| Concern | dev | qa | prod |
|---|---|---|---|
| Auth | Real XSUAA (once deployed), permissive CORS | Real XSUAA | Real XSUAA, locked-down CORS |
| Database | HANA Cloud trial HDI container | Separate HDI container | Separate HDI container, real backup posture |
| AI layer | Ollama or free-tier AI Core (either, per `PROJECT_CHARTER.md`'s account strategy) | Same as prod, smaller quota | AI Core / Generative AI Hub, real quota management |
| Deploy trigger | Every merge to `main` (once CI is turned on — see `ci-cd/github-actions/README.md`) | Manual promotion via CTMS | Manual promotion via CTMS, approval-gated |
| Feature flags | All on (spend-anomaly-detector's `feature-flags.js`) | Mirrors prod | Conservative defaults, toggled per incident |

## Known limitations (honesty notes)

This table is intent, not observed behavior — no environment beyond local
dev has actually been stood up, so none of the above has been verified
against real deployed instances yet.
