// src/routes/superAdmin.js
const express = require('express');
const router = express.Router();
// Master DB pool no longer needed directly here
const tenantModel = require('../models/tenant');

// Middleware to ensure only superadmin can access these routes.
// Assumes auth middleware earlier has set req.user with role.
function requireSuperAdmin(req, res, next) {
  if (req.user && req.user.role === 'superadmin') return next();
  return res.status(403).json({ error: 'Super admin access required' });
}

router.use(requireSuperAdmin);

// GET /admin/tenants – list all tenants
router.get('/tenants', async (req, res) => {
  try {
    const tenants = await tenantModel.listTenants();
    res.json(tenants);
  } catch (err) {
    console.error('List tenants error', err);
    res.status(500).json({ error: 'Failed to list tenants' });
  }
});

// POST /admin/tenants – create a new tenant (school)
router.post('/tenants', async (req, res) => {
  const { name, adminEmail, adminPassword, plan = 'basic', billingCycleDays = 30 } = req.body;
  try {
    const { tenantId, schemaName } = await tenantModel.createTenant({
      name,
      adminEmail,
      adminPassword,
      plan,
      billingCycleDays,
    });
    res.status(201).json({ tenantId, schemaName });
  } catch (e) {
    console.error('Create tenant error', e);
    res.status(500).json({ error: 'Failed to create tenant' });
  }
});

// PATCH /admin/tenants/:id/status – suspend/reactivate a tenant
router.patch('/tenants/:id/status', async (req, res) => {
  const { id } = req.params;
  const { status } = req.body; // expected: 'active' | 'suspended' | 'cancelled'
  if (!['active', 'suspended', 'cancelled'].includes(status)) {
    return res.status(400).json({ error: 'Invalid status value' });
  }
  try {
    const updated = await tenantModel.setTenantStatus(id, status);
    res.json(updated);
  } catch (err) {
    console.error('Update tenant status error', err);
    res.status(500).json({ error: 'Failed to update status' });
  }
});

module.exports = router;
