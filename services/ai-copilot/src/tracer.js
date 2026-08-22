'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const config = require('./config');

/**
 * A local, dependency-free tracer shaped like Langfuse's trace/span/
 * generation model (trace -> ordered children, each a span or a generation
 * with input/output/metadata/timing) — deliberately NOT the real Langfuse
 * SDK.
 *
 * Why a shim instead of real self-hosted Langfuse: Langfuse's own compose
 * stack (Postgres + ClickHouse + Redis + MinIO + web + worker) needs more
 * headroom than this machine's Docker Desktop currently has allocated
 * (3.8GB total, checked before deciding this — see docs/next/next.md).
 * Rather than risk an unstable multi-container stack for a demo, this
 * shim gets the AI copilot's tracing *behavior* fully real and testable
 * today, with a narrow, swappable interface (startTrace/startSpan/
 * endSpan/startGeneration/endGeneration/endTrace) — swapping in the real
 * Langfuse SDK later means rewriting this file's internals, not any of
 * its callers (see rag-service.js, which only calls this interface).
 *
 * Persistence: every completed trace is appended as one JSON line to
 * data/traces.jsonl (gitignored — it's runtime data, not source) and kept
 * in memory for the HTTP trace-viewer endpoints.
 */

const traces = new Map();

function newId(prefix) {
  return `${prefix}_${crypto.randomUUID()}`;
}

function startTrace(name, { input, metadata } = {}) {
  const trace = {
    id: newId('trace'),
    name,
    input,
    metadata,
    startTime: Date.now(),
    endTime: null,
    output: null,
    status: 'running',
    children: [], // spans and generations, in order
  };
  traces.set(trace.id, trace);
  return trace;
}

function startSpan(trace, name, { input, metadata } = {}) {
  const span = {
    id: newId('span'),
    type: 'span',
    name,
    input,
    metadata,
    startTime: Date.now(),
    endTime: null,
    output: null,
  };
  trace.children.push(span);
  return span;
}

function endSpan(span, { output, metadata } = {}) {
  span.endTime = Date.now();
  span.durationMs = span.endTime - span.startTime;
  span.output = output;
  if (metadata) span.metadata = { ...span.metadata, ...metadata };
  return span;
}

function startGeneration(trace, name, { model, input, metadata } = {}) {
  const generation = {
    id: newId('gen'),
    type: 'generation',
    name,
    model,
    input,
    metadata,
    startTime: Date.now(),
    endTime: null,
    output: null,
    usage: null,
  };
  trace.children.push(generation);
  return generation;
}

function endGeneration(generation, { output, usage, metadata } = {}) {
  generation.endTime = Date.now();
  generation.durationMs = generation.endTime - generation.startTime;
  generation.output = output;
  generation.usage = usage || null;
  if (metadata) generation.metadata = { ...generation.metadata, ...metadata };
  return generation;
}

function endTrace(trace, { output, status = 'ok', metadata } = {}) {
  trace.endTime = Date.now();
  trace.durationMs = trace.endTime - trace.startTime;
  trace.output = output;
  trace.status = status;
  if (metadata) trace.metadata = { ...trace.metadata, ...metadata };

  fs.mkdirSync(path.dirname(config.tracesFile), { recursive: true });
  fs.appendFileSync(config.tracesFile, JSON.stringify(trace) + '\n');

  return trace;
}

function getTrace(id) {
  return traces.get(id) || null;
}

function listTraces(limit = 20) {
  return [...traces.values()]
    .sort((a, b) => b.startTime - a.startTime)
    .slice(0, limit)
    .map(({ id, name, status, startTime, durationMs, input }) => ({ id, name, status, startTime, durationMs, input }));
}

module.exports = { startTrace, startSpan, endSpan, startGeneration, endGeneration, endTrace, getTrace, listTraces };
