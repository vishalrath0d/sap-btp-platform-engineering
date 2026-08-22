'use strict';

const path = require('path');
const documentStore = require('../src/document-store');

const corpusDir = path.join(__dirname, '..', 'corpus');

describe('document-store (Document Management Service simulation)', () => {
  test('listDocuments returns the real corpus markdown files', () => {
    const files = documentStore.listDocuments(corpusDir);
    expect(files.length).toBeGreaterThan(0);
    expect(files.every((f) => f.endsWith('.md'))).toBe(true);
  });

  test('readDocument returns real content for a listed document', () => {
    const [first] = documentStore.listDocuments(corpusDir);
    const content = documentStore.readDocument(first, corpusDir);
    expect(content.length).toBeGreaterThan(0);
  });
});
