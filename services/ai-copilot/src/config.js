'use strict';

/**
 * Every knob the AI layer needs, in one place, env-overridable. Kept
 * deliberately small — this is the seam that will grow a `PROVIDER=ai-core`
 * branch once the BTP free tier is available (see README's "trial vs
 * free-tier" section), so it shouldn't accumulate unrelated config.
 */
module.exports = {
  port: process.env.PORT || 4005,
  ollamaBaseUrl: process.env.OLLAMA_BASE_URL || 'http://localhost:11434',
  embeddingModel: process.env.EMBEDDING_MODEL || 'all-minilm',
  chatModel: process.env.CHAT_MODEL || 'qwen2.5:1.5b',
  topK: Number(process.env.RAG_TOP_K || 4),
  corpusDir: process.env.CORPUS_DIR || require('path').join(__dirname, '..', 'corpus'),
  tracesFile: process.env.TRACES_FILE || require('path').join(__dirname, '..', 'data', 'traces.jsonl'),
};
