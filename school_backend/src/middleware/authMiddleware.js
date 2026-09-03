// school_backend/src/middleware/authMiddleware.js
const { Pool } = require('pg');

// Create pool reference from environment or fallback
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.DATABASE_URL ? { rejectUnauthorized: false } : false
});

/**
 * Extract Tenant ID from header or body or query or authenticated user
 */
const tenantScope = (req, res, next) => {
  const tenantHeader = req.headers['x-tenant-id'];
  if (tenantHeader) {
    req.tenantId = parseInt(tenantHeader, 10);
  } else if (req.body && req.body.tenant_id) {
    req.tenantId = parseInt(req.body.tenant_id, 10);
  } else if (req.query && req.query.tenant_id) {
    req.tenantId = parseInt(req.query.tenant_id, 10);
  }
  next();
};

/**
 * Ensure School Subscription is Active
 */
const checkSubscription = async (req, res, next) => {
  const tenantId = req.tenantId || req.headers['x-tenant-id'];
  const userRole = req.headers['x-user-role'] || (req.user && req.user.role);

  // SuperAdmin bypasses subscription restriction
  if (userRole === 'SuperAdmin' || req.headers['x-superadmin-access'] === 'true') {
    return next();
  }

  if (!tenantId) {
    // If no tenantId provided, proceed (or handle legacy single-tenant)
    return next();
  }

  try {
    const result = await pool.query(
      `SELECT id, name, subscription_status, subscription_expires_at 
       FROM tenants WHERE id = $1`,
      [tenantId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Iskuulka la raadinayo lama helin.' });
    }

    const tenant = result.rows[0];

    // Check expiry date dynamically
    if (tenant.subscription_expires_at && new Date(tenant.subscription_expires_at) < new Date()) {
      // Auto-update status to suspended if expired
      if (tenant.subscription_status === 'active') {
        await pool.query(
          "UPDATE tenants SET subscription_status = 'suspended' WHERE id = $1",
          [tenantId]
        );
      }
      return res.status(402).json({
        error: 'Waqtigii adeegga iskuulkan waa dhacay (Subscription Expired). Fadlan la xiriir Super Admin si aad u cusboonaysiiso.',
        code: 'SUBSCRIPTION_EXPIRED',
        tenant: tenant.name
      });
    }

    if (tenant.subscription_status !== 'active') {
      return res.status(402).json({
        error: 'Nidaamka iskuulkan waa la hakiyay (Suspended). Fadlan la xiriir Super Admin.',
        code: 'TENANT_SUSPENDED',
        tenant: tenant.name
      });
    }

    next();
  } catch (err) {
    console.error('Subscription check error:', err.message);
    next();
  }
};

/**
 * Super Admin Authorization Middleware
 */
const requireSuperAdmin = (req, res, next) => {
  const role = req.headers['x-user-role'] || (req.user && req.user.role);
  if (role === 'SuperAdmin') {
    return next();
  }
  return res.status(403).json({ error: 'Awoodan waxaa leeh oo kaliya Super Admin.' });
};

module.exports = {
  tenantScope,
  checkSubscription,
  requireSuperAdmin
};
