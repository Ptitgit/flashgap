import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { buildApp } from '../src/app.js';

describe('GET /health', () => {
  it('returns status ok', async () => {
    const app = buildApp();
    try {
      const response = await app.inject({ method: 'GET', url: '/health' });
      assert.equal(response.statusCode, 200);
      assert.deepEqual(response.json(), { status: 'ok' });
    } finally {
      await app.close();
    }
  });
});
