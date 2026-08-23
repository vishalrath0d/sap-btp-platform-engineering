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
  console.log(`[ai-copilot] ingesting corpus from ${config.corpusDir} ...`);
  const stats = await vectorStore.ingest();
  console.log(`[ai-copilot] ingested ${stats.files} document(s) into ${stats.chunks} chunk(s)`);

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
