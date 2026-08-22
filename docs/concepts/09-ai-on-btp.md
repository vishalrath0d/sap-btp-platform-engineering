# AI on SAP BTP

## The official reference architecture — and how closely `ai-copilot` already matches it

SAP's own [Architecture Center](https://github.com/SAP/architecture-center)
publishes **RA0005 — "Generative AI on SAP BTP"**: a CAP-based backend +
HANA Cloud Vector Engine for retrieval + Generative AI Hub for the LLM
call. That's the *exact* three-component shape `ai-copilot` already
implements in trial mode (CAP-adjacent service + local vector store +
Ollama), one layer removed from the real thing. Worth citing directly —
this project didn't invent a plausible-sounding AI architecture, it built
toward SAP's own published one, documented honestly about which layer is
simulated (see the trial-vs-BTP-mode table below).

Also relevant: **RA0033 — "SAP Document AI"** — OCR + extraction +
LLM-based reasoning turning unstructured documents into structured data.
The SAP-native alternative to `ai-copilot`'s current flat markdown-corpus
ingestion (`corpus/*.md`) — worth a look once/if document ingestion needs
to handle real scanned contracts rather than clean markdown.

## AI Core, AI Launchpad, Generative AI Hub — what each actually is

- **AI Core** — the execution engine. Resource groups (isolated
  workspaces), Git-backed workflow templates, a tenant-specific Docker
  registry for custom model images, a standardized "AI API" that AI
  Launchpad (or any external tool) talks to.
- **AI Launchpad** — the SaaS management/monitoring layer on top of AI
  Core (and other runtimes) — deployment status, MLOps metrics, and (a
  newer addition) where Generative AI Hub gets activated.
- **Generative AI Hub** — access to multiple foundation models (SAP-hosted
  and hyperscaler models — GPT/Gemini/Claude/Llama family) via one
  governed orchestration layer: templating, grounding, data masking,
  content filtering, quota/audit.

## Trial vs. BTP mode — the seam, restated concretely for `ai-copilot`

| | Trial mode (now, verified) | Free-tier/BTP mode (later, documented not built) |
|---|---|---|
| Embeddings | Ollama `all-minilm`, local | AI Core / Generative AI Hub embeddings, or still local — not mutually exclusive |
| Generation | Ollama `qwen2.5:1.5b`, local (upgraded from 0.5b after a real documented finding — see `ai-copilot`'s README) | Generative AI Hub model call |
| Vector store | In-memory brute-force (`src/vector-store.js`) | HANA Cloud Vector Engine (`07-data-and-hana-cloud.md`) |
| Tracing | Local Langfuse-shaped shim (`src/tracer.js`) | Real Langfuse (self-hosted or cloud) |

AI Core specifically is **not available on the plain 90-day trial** — it
needs BTP free tier (a card-verification-only PAYG account, no expiry).
This project starts trial-only per `PROJECT_CHARTER.md`'s account
strategy; every AI-touching doc/README states plainly which mode it's
describing, never silently assuming one.

## The real SDK/package names for when this actually gets built

- **`@sap-ai-sdk/foundation-models`** — the real Node.js package for
  calling AI Core / Generative AI Hub chat completion from a CAP service.
  Not yet a dependency of `ai-copilot` (still Ollama-only) — the name to
  reach for when the free-tier upgrade phase starts.
- **`cap-llm-plugin`** (confirmed via `SAP-samples/cap-ai-vector-engine-sample`'s
  real `package.json`) — the higher-level CAP plugin pattern:
  `cds.connect.to('cap-llm-plugin')` then `.getRagResponse()` /
  `.getEmbedding()` / `.similaritySearch()`, wired to a HANA Vector
  Engine table + a `GENERATIVE_AI_HUB`-named Destination. This is a
  *different, higher-level* integration path than hand-rolling calls the
  way `ai-copilot`'s `src/ollama-client.js` currently does — worth
  evaluating both when the real migration happens rather than assuming
  the hand-rolled approach is simply carried over unchanged.
- **`SAP-samples/btp-genai-starter-kit`** — Terraform-provisions AI Core
  (extended plan) + HANA Vector Engine together, the closest existing SAP
  sample to this project's own eventual "Terraform + AI Core upgrade"
  combination. Archived (frozen snapshot), still a useful reference.

## Joule

SAP's enterprise GenAI copilot, embedded across S/4HANA/SuccessFactors/
Ariba/BTP, itself built on Generative AI Hub underneath. **Joule Studio**
(a newer addition) lets you build custom Joule agents/skills — a plausible
extension surface for `ai-copilot`'s capabilities to eventually surface
*inside* Joule rather than only as a standalone service, though this
leans more toward app-dev than DevOps and isn't currently planned as a
concrete build item here.

## Known limitations (honesty notes)

Nothing in this doc beyond the trial-mode `ai-copilot` implementation has
been run against real SAP AI infrastructure — AI Core, Generative AI Hub,
and HANA Vector Engine integration are all documented intent, not
verified code, until the free-tier phase actually happens.
