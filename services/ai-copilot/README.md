# ai-copilot

A RAG copilot over ProcureIQ's supplier policies and contracts — "what are
this supplier's payment terms," "what does the Code of Conduct say about
gifts," "how is a HIGH-risk supplier's approval routed differently" — with
every retrieval and generation step traced so an answer's provenance is
always inspectable, not just its text.

Runs entirely locally today: Ollama for both embeddings and generation, an
in-memory brute-force vector search over a small markdown corpus, and a
local tracer shaped like Langfuse's trace/span/generation model. No BTP
account, no cloud API key, no cost, needed to run or test this service.

## Why it's built this way (trial-mode vs. the eventual BTP mode)

This service is deliberately written in two layers with a narrow seam
between them, matching the account strategy in the repo-root
`PROJECT_CHARTER.md`:

| Concern | Trial mode (now) | BTP free-tier mode (later, not built yet) |
|---|---|---|
| Embeddings + generation | Ollama (`all-minilm` + `qwen2.5:1.5b`, local) | SAP AI Core / Generative AI Hub |
| Vector store | In-memory brute-force cosine similarity (`src/vector-store.js`) | HANA Cloud Vector Engine |
| Tracing | Local shim (`src/tracer.js`), Langfuse-shaped API | Real Langfuse (self-hosted or cloud) |

`rag-service.js` only calls the `tracer.*` and `ollama-client.*` interfaces —
swapping either implementation later doesn't touch the RAG logic or the HTTP
layer at all.

## Run it locally

Needs [Ollama](https://ollama.com) running with two small models pulled:

```bash
ollama serve &                    # if not already running
ollama pull all-minilm            # 45MB, embeddings
ollama pull qwen2.5:1.5b          # 986MB, generation

npm install
npm start                          # ingests corpus/, listens on :4005
```

```bash
curl -X POST http://localhost:4005/copilot/ask \
  -H 'Content-Type: application/json' \
  -d '{"question":"What payment terms apply to a HIGH-risk supplier?"}'

# inspect exactly what was retrieved and what prompt produced the answer:
curl http://localhost:4005/copilot/traces/<traceId>
```

### Tests

```bash
npm test
```

11/11 passing: 6 pure unit tests (cosine similarity, chunking, ranking — no
Ollama needed) + 5 live integration tests against a real running Ollama
instance and the real corpus (no mocking). The integration suite checks
Ollama reachability in `beforeAll` and **skips itself with a clear console
message** if Ollama isn't running, instead of either failing red on an
environment problem or silently reporting green with nothing actually run.

## A real finding from building this: model size matters more than prompt engineering

The first version used `qwen2.5:0.5b` (397MB). Single-fact lookups worked
well ("what payment terms apply to a HIGH-risk supplier" → correct,
grounded answer, first try). A **cross-document synthesis** question —
"what is the termination notice period for Acme Components versus Global
Circuit Supply" — failed: the model answered "I don't have information
about that," even though both facts were verifiably present in its prompt
(confirmed by inspecting the trace — both relevant chunks were retrieved,
in the top 2 by score).

Rather than fight this with prompt engineering, I tested the same question
directly against `qwen2.5:1.5b` (986MB, still small) and it synthesized the
answer correctly on the first try — with the exact same prompt structure.
Switched the default model and re-verified both the fix (synthesis question)
and that the out-of-scope guardrail ("what is the capital of France?" →
correctly declines) still held with the bigger model. **Retrieval was never
the problem here** — the trace made that unambiguous — generation capacity
was. Left `CHAT_MODEL` as an env override (`src/config.js`) so this is a
one-line change if a use case needs to trade model size for latency again.

## Known limitations (honesty notes)

- **Brute-force vector search doesn't scale.** Fine for 37 chunks across 5
  documents; would need a real ANN index or HANA Cloud Vector Engine well
  before a production-sized document set (see `src/vector-store.js`'s
  comment on this boundary).
- **The tracer is a local shim, not real Langfuse.** Traces are in-memory
  (cleared on restart) plus append-only JSONL (`data/traces.jsonl`,
  gitignored — it's runtime data). Standing up self-hosted Langfuse was
  deliberately deferred: this machine's Docker Desktop has only 3.8GB RAM
  allocated, and Langfuse's own stack (Postgres+ClickHouse+Redis+MinIO) is
  tight enough in that budget to risk an unstable demo. Documented as a
  next step, not silently worked around forever.
- **Chunking is paragraph-boundary-based**, not token-count-based with
  overlap — good enough for short policy documents, not how a production
  ingestion pipeline should chunk longer or less structured source material.
- **No citation enforcement.** The prompt asks the model to cite sources
  inline; it doesn't always comply (see `sources` in the API response for
  the citations that are actually guaranteed — those come from retrieval
  scoring, not from parsing the model's own text).
