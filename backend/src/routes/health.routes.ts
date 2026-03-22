import { Router } from 'express'; 
import { isGeminiConfigured } from '../services/gemini.service'; 
 
export const healthRouter = Router(); 
 
healthRouter.get('/', function (_req, res) { 
  res.status(200).json({ 
    status: 'ok', 
    version: '1.0.0', 
    geminiReady: isGeminiConfigured(), 
  }); 
});
