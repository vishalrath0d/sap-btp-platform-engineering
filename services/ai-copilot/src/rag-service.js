'use strict';

const config = require('./config');
const ollama = require('./ollama-client');
const tracer = require('./tracer');

function buildPrompt(question, contextChunks) {
  const context = contextChunks.map((c) => `Source: ${c.source}\n${c.text}`).join('\n\n---\n\n');
  return [
    'You are the ProcureIQ procurement copilot. Answer the question using ONLY the context below.',
    'If the context does not contain the answer, say exactly: "I don\'t have information about that in the available documents."',
    'Cite which source file(s) you used at the end of your answer, in the form (source: filename.md).',
    '',
    `Context:\n${context}`,
    '',
    `Question: ${question}`,
    '',
    'Answer:',
  ].join('\n');
}

/**
 * The one function this whole service exists to provide. Every step is
 * traced (see tracer.js) so a real answer's provenance — which chunks were
 * retrieved, with what similarity scores, and exactly what prompt produced
 * the final answer — is always inspectable, not just the final text.
 */
async function ask(vectorStore, question) {
  if (!question || !question.trim()) {
    const err = new Error('question is required');
    err.status = 400;
    throw err;
  }

  const trace = tracer.startTrace('rag-ask', { input: question });

  try {
    const retrievalSpan = tracer.startSpan(trace, 'retrieval', { input: question });
    const results = await vectorStore.search(question, config.topK);
    tracer.endSpan(retrievalSpan, {
      output: results.map((r) => ({ source: r.source, id: r.id, score: Number(r.score.toFixed(4)) })),
    });

    const prompt = buildPrompt(question, results);
    const genSpan = tracer.startGeneration(trace, 'answer-generation', { model: config.chatModel, input: prompt });
    const { text, promptTokens, completionTokens, totalDurationMs } = await ollama.generate(prompt);
    tracer.endGeneration(genSpan, {
      output: text,
      usage: { promptTokens, completionTokens },
      metadata: { totalDurationMs },
    });

    const sources = results.map((r) => ({ source: r.source, score: Number(r.score.toFixed(4)) }));
    tracer.endTrace(trace, { output: text, status: 'ok' });

    return { answer: text.trim(), sources, traceId: trace.id };
  } catch (err) {
    tracer.endTrace(trace, { output: null, status: 'error', metadata: { error: err.message } });
    throw err;
  }
}

module.exports = { ask, buildPrompt };
