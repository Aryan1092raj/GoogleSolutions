import test from 'node:test';
import assert from 'node:assert/strict';

import geminiBridge from '../dist/websocket/gemini-bridge.js';

const { resolveGeminiSessionMode } = geminiBridge;

test('prefers API mode when GEMINI_API_KEY is configured', () => {
  const mode = resolveGeminiSessionMode({
    GEMINI_API_KEY: 'demo-key',
    GEMINI_MODEL: 'gemini-2.0-flash',
    GOOGLE_CLOUD_PROJECT: 'demo-project',
    VERTEX_AI_LOCATION: 'us-central1',
  });

  assert.equal(mode, 'GEMINI_API');
});

test('falls back to Vertex mode when API key is absent', () => {
  const mode = resolveGeminiSessionMode({
    GEMINI_MODEL: 'gemini-2.0-flash',
    GOOGLE_CLOUD_PROJECT: 'demo-project',
    VERTEX_AI_LOCATION: 'us-central1',
  });

  assert.equal(mode, 'VERTEX_CHAT');
});

test('returns null when Gemini configuration is incomplete', () => {
  const mode = resolveGeminiSessionMode({
    GEMINI_MODEL: 'gemini-2.0-flash',
  });

  assert.equal(mode, null);
});
