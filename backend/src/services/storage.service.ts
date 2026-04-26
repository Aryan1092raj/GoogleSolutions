import { Storage } from '@google-cloud/storage'; 
import { logger } from '../utils/logger'; 
 
const storage = new Storage(); 
const chunkBuffers = new Map(); 
 
export async function appendMediaChunk(incidentId, chunkIndex, videoBase64, audioBase64) { 
  if (!chunkBuffers.has(incidentId)) { 
    chunkBuffers.set(incidentId, []); 
  } 
  const entries = chunkBuffers.get(incidentId); 
  entries.push({ chunkIndex: chunkIndex, video: videoBase64, audio: audioBase64 }); 
} 
 
export async function finalizeRecording(incidentId) { 
  const bucketName = process.env.GCS_BUCKET; 
  if (!bucketName) { 
    logger.warn('GCS bucket is not configured'); 
    return null; 
  } 
 
  let entries = []; 
  if (chunkBuffers.has(incidentId)) { 
    entries = chunkBuffers.get(incidentId); 
  } 
  const objectPath = incidentId + '/raw-chunks.json'; 
  const payload = JSON.stringify({ incidentId: incidentId, chunks: entries }); 
 
  const bucket = storage.bucket(bucketName); 
  const file = bucket.file(objectPath); 
  await file.save(payload, { contentType: 'application/json' }); 
  chunkBuffers.delete(incidentId); 
 
  return 'gs://' + bucketName + '/' + objectPath; 
} 
 
export function discardRecordingBuffer(incidentId) { 
  chunkBuffers.delete(incidentId); 
}
