'use strict';

const { VectorStore, chunkMarkdown, cosineSimilarity } = require('../src/vector-store');

describe('cosineSimilarity', () => {
  test('identical vectors score 1', () => {
    expect(cosineSimilarity([1, 0, 0], [1, 0, 0])).toBeCloseTo(1);
  });

  test('orthogonal vectors score 0', () => {
    expect(cosineSimilarity([1, 0], [0, 1])).toBeCloseTo(0);
  });

  test('opposite vectors score -1', () => {
    expect(cosineSimilarity([1, 0], [-1, 0])).toBeCloseTo(-1);
  });
});

describe('chunkMarkdown', () => {
  test('splits on blank lines and drops short fragments', () => {
    const text = '# Title\n\nShort\n\nThis is a real paragraph with enough content to survive the length filter.';
    const chunks = chunkMarkdown('doc.md', text);
    // "# Title" and "Short" are both <= 40 chars, only the long paragraph survives
    expect(chunks).toHaveLength(1);
    expect(chunks[0].source).toBe('doc.md');
    expect(chunks[0].id).toBe('doc.md#0');
  });
});

describe('VectorStore.rank', () => {
  test('returns the closest chunks first, without needing Ollama', () => {
    const store = new VectorStore();
    store.chunks = [
      { id: 'a', source: 'a.md', text: 'about apples', embedding: [1, 0, 0] },
      { id: 'b', source: 'b.md', text: 'about bananas', embedding: [0, 1, 0] },
      { id: 'c', source: 'c.md', text: 'mostly about apples', embedding: [0.9, 0.1, 0] },
    ];

    const ranked = store.rank([1, 0, 0], 2);
    expect(ranked).toHaveLength(2);
    expect(ranked[0].id).toBe('a');
    expect(ranked[1].id).toBe('c');
    expect(ranked[0].score).toBeGreaterThan(ranked[1].score);
  });

  test('size() reflects ingested chunk count', () => {
    const store = new VectorStore();
    expect(store.size()).toBe(0);
    store.chunks = [{ id: 'x' }];
    expect(store.size()).toBe(1);
  });
});
