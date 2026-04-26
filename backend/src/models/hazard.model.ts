import { z } from 'zod'; 
 
const hazardTypes = [ 
  'FIRE', 
  'SMOKE', 
  'MEDICAL', 
  'SECURITY_THREAT', 
  'STRUCTURAL_DAMAGE', 
  'FLOOD', 
  'UNKNOWN', 
] as const; 
 
export type HazardType = (typeof hazardTypes)[number]; 
 
export interface Hazard { 
  type: HazardType; 
  confidence: number; 
  description: string; 
  detectedAt: unknown; 
} 
 
export const hazardTypeSchema = z.enum(hazardTypes); 
 
export const hazardSchema = z.object({ 
  type: hazardTypeSchema, 
  confidence: z.number().min(0).max(1), 
  description: z.string(), 
  detectedAt: z.unknown(), 
});
