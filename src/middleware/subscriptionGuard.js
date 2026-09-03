// src/middleware/subscriptionGuard.js

/**
 * Subscription guard middleware for tenant‑scoped routes.
 *
 * The middleware expects that `req.tenantId` has been populated by the
 * `tenantResolver` middleware. It then checks the tenant's subscription
 * status in the master database. If the subscription is not active, the
 * request is rejected with a 403 response.
 */
module.exports = async function subscriptionGuard(req, res, next) {
  // Allow super‑admin routes (they are not tenant‑scoped)
  if (req.path.startsWith('/admin')) return next();

  const tenantId = req.tenantId;
  if (!tenantId) {
    return res.status(400).json({ error: 'Tenant ID not resolved' });
  }

  const db = require('../../backend/db');
  try {
    // Query the tenants table for subscription status and expiry
  const result = await db.query(
    `SELECT subscription_status AS status, subscription_expires_at AS expires_at FROM tenants WHERE id = $1`,
    [tenantId]
  );
    const sub = result.rows[0];
    if (!sub || sub.status !== 'active' || new Date(sub.expires_at) < new Date()) {
      return res.status(403).json({ error: 'Subscription inactive or expired' });
    }
    // Subscription valid – proceed
    next();
  } catch (err) {
    console.error('Subscription guard error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
};
