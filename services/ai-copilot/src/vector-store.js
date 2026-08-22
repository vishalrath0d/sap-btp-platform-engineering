'use strict';

const fs = require('fs');
const path = require('path');
const config = require('./config');
const { embed } = require('./ollama-client');

/**
 * Brute-force, in-memory cosine-similarity search over markdown chunks.
 *
 * This stands in for SAP HANA Cloud's Vector Engine, which is the intended
 * production store (see docs/concepts/07-data-and-hana-cloud.md, not yet
 * written — HANA Vector Engine work is scoped once a BTP account exists).
 * Brute force is fine here: the whole corpus is a handful of policy/contract
 * documents (see corpus/), not a production-scale document set. It would
 * not scale past maybe a few thousand chunks before an actual ANN index
 * (or just moving to HANA) becomes necessary — that's a documented boundary,
 * not an oversight.
 */

function chunkMarkdown(source, text) {
  // Paragraph-level chunking: split on blank lines, drop empty/heading-only
  // fragments shorter than a real sentence. Good enough for documents this
  // size; a production ingestion pipeline would chunk by token count with
  // overlap, not paragraph boundaries.
  return text
    .split(/\n\s*\n/)
    .map((p) => p.trim())
    .filter((p) => p.length > 40)
    .map((text, i) => ({ id: `${source}#${i}`, source, text }));
}

function cosineSimilarity(a, b) {
  let dot = 0;
  let normA = 0;
  let normB = 0;
  for (let i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  return dot / (Math.sqrt(normA) * Math.sqrt(normB));
}

class VectorStore {
  constructor() {
    this.chunks = []; // [{ id, source, text, embedding }]
  }

  /** Reads every .md file in corpusDir, chunks it, embeds each chunk via Ollama. */
  async ingest(corpusDir = config.corpusDir) {
    const files = fs.readdirSync(corpusDir).filter((f) => f.endsWith('.md'));
    const chunks = files.flatMap((file) => {
      const text = fs.readFileSync(path.join(corpusDir, file), 'utf8');
      return chunkMarkdown(file, text);
    });

    for (const chunk of chunks) {
      chunk.embedding = await embed(chunk.text);
    }
    this.chunks = chunks;
    return { files: files.length, chunks: chunks.length };
  }

  /** Pure, synchronous ranking — the part that's actually unit-testable without Ollama. */
  rank(queryEmbedding, topK = config.topK) {
    return this.chunks
      .map((c) => ({ ...c, score: cosineSimilarity(queryEmbedding, c.embedding) }))
      .sort((a, b) => b.score - a.score)
      .slice(0, topK);
  }

  async search(queryText, topK = config.topK) {
    const queryEmbedding = await embed(queryText);
    return this.rank(queryEmbedding, topK);
  }

  size() {
    return this.chunks.length;
  }
}

module.exports = { VectorStore, chunkMarkdown, cosineSimilarity };
