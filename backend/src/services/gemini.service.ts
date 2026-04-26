import { VertexAI } from '@google-cloud/vertexai';

let vertexClient = null;

export function getVertexClient() {
  if (vertexClient) {
    return vertexClient;
  }

  vertexClient = new VertexAI({
    project: process.env.GOOGLE_CLOUD_PROJECT,
    location: process.env.GOOGLE_CLOUD_LOCATION || process.env.VERTEX_AI_LOCATION,
  });

  return vertexClient;
}
 
export function isGeminiConfigured() { 
  const model = (process.env.GEMINI_MODEL || '').trim();
  const apiKey = (process.env.GEMINI_API_KEY || '').trim();
  const project = (process.env.GOOGLE_CLOUD_PROJECT || '').trim();
  const location =
    (process.env.GOOGLE_CLOUD_LOCATION || process.env.VERTEX_AI_LOCATION || '').trim();

  const apiModeReady = apiKey.length > 0 && model.length > 0;
  const vertexModeReady = project.length > 0 && location.length > 0 && model.length > 0;

  return apiModeReady || vertexModeReady;
}
