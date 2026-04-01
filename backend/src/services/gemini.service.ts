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
  if (!process.env.GOOGLE_CLOUD_PROJECT) { 
    return false; 
  } 
  if (!process.env.VERTEX_AI_LOCATION) { 
    return false; 
  } 
  if (!process.env.GEMINI_MODEL) { 
    return false; 
  } 
  return true; 
}
