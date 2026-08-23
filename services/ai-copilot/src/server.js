'use strict';

const express = require('express');
const config = require('./config');
const ollama = require('./ollama-client');
const tracer = require('./tracer');
const ragService = require('./rag-service');
const { VectorStore } = require('./vector-store');
const metrics = require('./metrics');

function createApp(vectorStore) {
  const app = express();
  app.use(metrics.httpMiddleware);
  app.use(express.json());

  app.get('/copilot/health', async (req, res) => {
    const ollamaUp = await ollama.isReachable();
    metrics.ollamaReachable.set(ollamaUp ? 1 : 0);
    res.json({
      status: ollamaUp ? 'ok' : 'degraded',
      ollamaReachable: ollamaUp,
      embeddingModel: config.embeddingModel,
      chatModel: config.chatModel,
      corpusChunks: vectorStore.size(),
    });
  });

  app.get('/metrics', metrics.handler);

  app.post('/copilot/ask', async (req, res) => {
    try {
      const result = await ragService.ask(vectorStore, req.body?.question);
      metrics.questionsTotal.inc({ status: 'ok' });
      res.json(result);
    } catch (err) {
      metrics.questionsTotal.inc({ status: 'error' });
      res.status(err.status || 500).json({ error: err.message });
    }
  });

  app.get('/copilot/traces', (req, res) => {
    res.json({ traces: tracer.listTraces(Number(req.query.limit) || 20) });
  });

  app.get('/copilot/traces/:id', (req, res) => {
    const trace = tracer.getTrace(req.params.id);
    if (!trace) return res.status(404).json({ error: 'trace not found (traces are in-memory, cleared on restart)' });
    res.json(trace);
  });

  return app;
}

async function main() {
  const vectorStore = new VectorStore();

  // Real bug hit live: ingest() embeds every corpus chunk via Ollama, and
  // previously ran unconditionally and unguarded here - on any deploy
  // target without a reachable Ollama (every CF push so far; this
  // service's own manifest.yml comment already says the real target is
  // SAP AI Core, not a self-hosted Ollama), embed()'s fetch throws, main()
  // rejects, and the bottom of this file calls process.exit(1) before the
  // app ever binds a port - CF then reports a crash loop (0/1 instances),
  // not a real infra failure. /copilot/health already has a `degraded`
  // concept for exactly "Ollama's unreachable" - startup should degrade
  // the same way, not crash before that endpoint can ever serve.
  const ollamaUp = await ollama.isReachable();
  if (ollamaUp) {
    console.log(`[ai-copilot] ingesting corpus from ${config.corpusDir} ...`);
    try {
      const stats = await vectorStore.ingest();
      console.log(`[ai-copilot] ingested ${stats.files} document(s) into ${stats.chunks} chunk(s)`);
    } catch (err) {
      console.error('[ai-copilot] corpus ingestion failed, starting degraded (empty vector store):', err.message);
    }
  } else {
    console.warn(`[ai-copilot] Ollama unreachable at ${config.ollamaBaseUrl}, starting degraded (empty vector store) - /copilot/ask will error per-request until it's reachable`);
  }

  const app = createApp(vectorStore);
  app.listen(config.port, () => {
    console.log(`[ai-copilot] listening on http://localhost:${config.port}`);
  });
}

if (require.main === module) {
  main().catch((err) => {
    console.error('[ai-copilot] failed to start:', err);
    process.exit(1);
  });
}

module.exports = { createApp };
