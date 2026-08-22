'use strict';

const config = require('./config');

/**
 * Thin wrapper over Ollama's HTTP API. Deliberately not a client library —
 * two fetch calls don't need one, and staying dependency-free here keeps
 * this file trivial to re-point at a different local runtime later.
 */

async function embed(text) {
  const res = await fetch(`${config.ollamaBaseUrl}/api/embed`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ model: config.embeddingModel, input: text }),
  });
  if (!res.ok) {
    throw new Error(`Ollama embed failed: ${res.status} ${await res.text()}`);
  }
  const { embeddings } = await res.json();
  return embeddings[0];
}

async function generate(prompt, { temperature = 0.2 } = {}) {
  const res = await fetch(`${config.ollamaBaseUrl}/api/generate`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      model: config.chatModel,
      prompt,
      stream: false,
      options: { temperature },
    }),
  });
  if (!res.ok) {
    throw new Error(`Ollama generate failed: ${res.status} ${await res.text()}`);
  }
  const data = await res.json();
  return {
    text: data.response,
    promptTokens: data.prompt_eval_count ?? null,
    completionTokens: data.eval_count ?? null,
    totalDurationMs: data.total_duration ? Math.round(data.total_duration / 1e6) : null,
  };
}

/** Cheap reachability check — used by health checks and to skip live tests gracefully. */
async function isReachable() {
  try {
    const res = await fetch(`${config.ollamaBaseUrl}/api/tags`, { signal: AbortSignal.timeout(1500) });
    return res.ok;
  } catch {
    return false;
  }
}

module.exports = { embed, generate, isReachable };
