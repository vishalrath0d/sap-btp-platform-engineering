# Data and SAP HANA Cloud

## HANA Cloud vs. what this project actually runs on today

`procurement-core`'s schema (`db/schema.cds`) runs on SQLite locally — the
`[production]` cds profile added while building `mta.yaml` (see that
file's commit) switches the `db.kind` to `hana` for a real deployment,
with no changes to the CDS model itself. That's the entire point of CAP's
database abstraction: `db/schema.cds` doesn't know or care which database
is actually behind it.

## HDI containers

HANA Cloud's deployment unit for CAP/CDS-defined schemas — a **HANA
Deployment Infrastructure (HDI) container** is an isolated schema plus
the deployer that pushes compiled CDS artifacts into it.
`mta.yaml`'s `procurement-core-db-deployer` module (type `hdb`) is exactly
this deployer, verified with a real `mbt build` to actually produce the
`.hdbtable`/`.hdbtabledata` artifacts it deploys (see that file's commit
message for the concrete before/after — `cds build --production` doesn't
emit these at all until the `[production]` profile targets `hana`).
`infra/terraform/modules/entitlements` provisions the HDI-container-plan
entitlement (`hana`/`hdi-shared` — corrected via a real live `terraform
apply` + `btp list accounts/entitlement` check from an earlier, wrong
`hana-cloud-trial` guess that isn't a real entitlement at all; see
`infra/terraform/README.md`) this all depends on.

## HANA Cloud Vector Engine

A native vector data type (`REAL_VECTOR`) inside HANA Cloud itself — RAG
retrieval without standing up a separate vector database. This is
`ai-copilot`'s intended production-mode retrieval backend, explicitly
contrasted against its current local-mode implementation:

| | Local mode (now) | HANA Vector Engine mode (later) |
|---|---|---|
| Storage | In-memory brute-force cosine similarity (`src/vector-store.js`) | `REAL_VECTOR` columns in HANA Cloud |
| Scale | Fine for 37 chunks, documented as not scale-ready | Production-appropriate |
| Embeddings | Ollama (`all-minilm`, local) | SAP AI Core / Generative AI Hub, or still BYO — see `09-ai-on-btp.md` |

Same trial-mode/BTP-mode duality pattern as everything else AI-touching in
this project (Langfuse tracing, AI Core) — documented explicitly rather
than silently assumed to be "the same thing, basically."

## Known limitations (honesty notes)

No HANA Cloud instance has actually been provisioned or connected to yet
— this doc describes the intended architecture, verified where possible
(the HDI deployer artifacts genuinely build correctly) but not yet
verified end-to-end against a live HANA Cloud instance. That's an
account-gated step (`docs/next/next.md`).
