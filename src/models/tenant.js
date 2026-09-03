// src/models/tenant.js
/**
 * Tenant model – encapsulates operations on the master `tenants` table
 * and handles schema creation for a new tenant.
 */
const db = require('../../backend/db');
const bcrypt = require('bcrypt');

/** Create a new tenant (school) */
async function createTenant({ name, adminEmail, adminPassword, plan = 'basic', billingCycleDays = 30 }) {
  const client = await db.getClient();
  try {
    await client.query('BEGIN');
    // Generate a unique schema name – you can replace this with a slugified name if desired
    const schemaName = `school_${Date.now()}`;
    await client.query(`CREATE SCHEMA IF NOT EXISTS "${schemaName}"`);

    // Insert tenant metadata
    const tenantRes = await client.query(
      `INSERT INTO tenants (name, schema_name, subscription_status, subscription_expires_at)
       VALUES ($1, $2, 'active', now() + interval '${billingCycleDays} days')
       RETURNING id, schema_name`,
      [name, schemaName]
    );
    const tenantId = tenantRes.rows[0].id;

    // Create admin user for the tenant (stored in master users table)
    const hash = await bcrypt.hash(adminPassword, 10);
    await client.query(
      `INSERT INTO users (email, password_hash, role, tenant_id)
       VALUES ($1, $2, 'admin', $3)`,
      [adminEmail, hash, tenantId]
    );

    // Run per‑tenant migrations (example tables – extend as needed)
    await client.query(`SET search_path TO "${schemaName}"`);
    await client.query(`CREATE TABLE teachers (id SERIAL PRIMARY KEY, name TEXT NOT NULL);`);
    await client.query(`CREATE TABLE students (id SERIAL PRIMARY KEY, name TEXT NOT NULL, teacher_id INTEGER REFERENCES teachers(id));`);

    await client.query('COMMIT');
    return { tenantId, schemaName };
  } catch (e) {
    await client.query('ROLLBACK');
    console.error('createTenant error', e);
    throw e;
  } finally {
    client.release();
  }
}

/** List all tenants */
async function listTenants() {
  const result = await db.query(`SELECT id, name, schema_name, subscription_status, subscription_expires_at, created_at FROM tenants ORDER BY id`);
  return result.rows;
}

/** Update subscription status for a tenant */
async function setTenantStatus(tenantId, status) {
  const allowed = ['active', 'suspended', 'cancelled'];
  if (!allowed.includes(status)) throw new Error('Invalid status');
  const result = await db.query(
    `UPDATE tenants SET subscription_status = $1 WHERE id = $2 RETURNING *`,
    [status, tenantId]
  );
  return result.rows[0];
}

module.exports = {
  createTenant,
  listTenants,
  setTenantStatus,
};
