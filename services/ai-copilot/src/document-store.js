'use strict';

const fs = require('fs');
const path = require('path');
const config = require('./config');

/**
 * Simulates SAP Document Management Service — a BTP-native document
 * store (folders, versioning, metadata, content search) that would be
 * the real production home for the supplier policy/contract documents
 * `ai-copilot` retrieves against, instead of flat local files.
 *
 * Same seam pattern as srv/lib/destination.js in procurement-core: this
 * module's two functions (`listDocuments`, `readDocument`) are the
 * interface a real Document Management Service client would also expose
 * — vector-store.js calls only these two functions, never `fs` directly,
 * so swapping the local-filesystem implementation for a real Document
 * Management Service client later means rewriting this one file, not its
 * caller.
 */

function listDocuments(corpusDir = config.corpusDir) {
  return fs.readdirSync(corpusDir).filter((f) => f.endsWith('.md'));
}

function readDocument(name, corpusDir = config.corpusDir) {
  return fs.readFileSync(path.join(corpusDir, name), 'utf8');
}

module.exports = { listDocuments, readDocument };
