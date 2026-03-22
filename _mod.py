import pathlib 
p=pathlib.Path('backend/src/websocket/gemini-bridge.ts') 
t=p.read_text(encoding='utf-8') 
old=\"export function buildSystemPrompt(lang) { \n  return [\"  
new=\"export function buildSystemPrompt(lang) { \n  if (process.env.GEMINI_SYSTEM_PROMPT) { \n    return process.env.GEMINI_SYSTEM_PROMPT + '\\nGuest primary language is: ' + lang; \n  } \n  return [\"  
t=t.replace(old,new) 
p.write_text(t,encoding='utf-8') 
