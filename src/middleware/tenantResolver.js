// src/middleware/tenantResolver.js
/**
 * Middleware to resolve the tenant for each request.
 * It supports three methods (in order of precedence):
 *   1. Sub‑domain:   <tenant>.yourdomain.com (extracted from Host header)
 *   2. Custom header: X‑Tenant‑ID
 *   3. JWT claim: "tid" (tenant id) – decoded using JWT secret.
 *
 * After determining the tenant, it stores `req.tenantId` and ensures that
 * PostgreSQL queries run within that tenant's schema by setting the search_path
 * on a dedicated client for the request.
 */
const db = require('../../backend/db'); // master pool
const jwt = require('jsonwebtoken');

// You may configure which method to prioritize via env vars if needed.
const JWT_SECRET = process.env.JWT_SECRET || 'change_this_secret';

module.exports = async (req, res, next) => {
  try {
    // 1. Sub‑domain extraction
    let tenantId = null;
    const host = req.headers.host || '';
    if (host) {
      const parts = host.split('.');
      if (parts.length > 2) { // e.g., tenant.example.com
        tenantId = parts[0];
      }
    }

    // 2. Header fallback
    if (!tenantId && req.headers['x-tenant-id']) {
      tenantId = req.headers['x-tenant-id'];
    }

    // 3. JWT fallback
    if (!tenantId && req.headers.authorization) {
      const token = req.headers.authorization.split(' ')[1];
      try {
        const payload = jwt.verify(token, JWT_SECRET);
        tenantId = payload.tid; // custom claim
      } catch (e) {
        // ignore JWT errors – tenant will remain null
      }
    }

    if (!tenantId) {
      return res.status(400).json({ error: 'Tenant identifier missing' });
    }

    // If the request is for Super Admin routes, skip tenant resolution
    if (req.path.startsWith('/admin')) {
      return next();
    }

    // Attach tenantId to request for downstream handlers
    req.tenantId = tenantId;

    // Acquire a dedicated client so we can set search_path for this request only
    const client = await db.getClient();
    await client.query('SET search_path TO "' + tenantId + '"');
    // Put the client on the request – downstream code should use it for queries.
    req.dbClient = client;
    // Ensure the client is released after response finishes
    res.on('finish', () => {
      client.release();
    });
    next();
  } catch (err) {
    console.error('Tenant resolver error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
};
