// src/index.js
require('dotenv').config();
const express = require('express');
const app = express();
const db = require('../backend/db'); // master DB pool
const tenantResolver = require('./middleware/tenantResolver');
const subscriptionGuard = require('./middleware/subscriptionGuard');
const superAdminRoutes = require('./routes/superAdmin');

app.use(express.json());
// Resolve tenant from request (sub‑domain, header or JWT)
app.use(tenantResolver);
// Enforce subscription status for all tenant routes
app.use(subscriptionGuard);

// Super‑admin routes are prefixed with /admin and are NOT tenant‑scoped
app.use('/admin', superAdminRoutes);

// Example tenant route placeholder
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', tenant: req.tenantId });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server listening on port ${PORT}`));
