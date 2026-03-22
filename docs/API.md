# ResQLink Backend API 
 
## Public 
GET /health 
POST /api/auth/guest-token 
POST /api/auth/staff-login 
 
## Auth Required 
POST /api/incidents 
GET /api/incidents/:incidentId 
PATCH /api/incidents/:incidentId/status 
POST /api/incidents/:incidentId/log 
GET /api/incidents?hotelId=...&status=... 
 
## WebSocket 
WS /ws?token=...&incidentId=...
