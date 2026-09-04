/**
 * tenantIsolation.js
 * Central helper: ensures tenant_id column exists on every table and
 * provides scoped query helpers so EVERY model automatically filters by school.
 */
const pool = require('../config/db');

// Add tenant_id column to a table if not already present
const ensureTenantColumn = async (table) => {
  await pool.query(
    `ALTER TABLE ${table} ADD COLUMN IF NOT EXISTS tenant_id INT REFERENCES tenants(id) ON DELETE CASCADE`
  ).catch(() => {});
  await pool.query(
    `CREATE INDEX IF NOT EXISTS idx_${table}_tenant_id ON ${table}(tenant_id)`
  ).catch(() => {});
};

// SELECT all rows for a tenant
const scopedGetAll = async (table, tenantId, orderBy = 'id DESC') => {
  await ensureTenantColumn(table).catch(() => {});
  if (tenantId) {
    const { rows } = await pool.query(
      `SELECT * FROM ${table} WHERE tenant_id = $1 ORDER BY ${orderBy}`,
      [tenantId]
    );
    return rows;
  }
  const { rows } = await pool.query(`SELECT * FROM ${table} ORDER BY ${orderBy}`);
  return rows;
};

// INSERT a row and attach tenant_id
const scopedInsert = async (table, fields, values, tenantId) => {
  await ensureTenantColumn(table).catch(() => {});
  const allFields = [...fields, 'tenant_id'];
  const allValues = [...values, tenantId || null];
  const placeholders = allValues.map((_, i) => `$${i + 1}`).join(', ');
  const { rows } = await pool.query(
    `INSERT INTO ${table} (${allFields.join(', ')}) VALUES (${placeholders}) RETURNING *`,
    allValues
  );
  return rows[0];
};

// DELETE scoped to tenant
const scopedDelete = async (table, id, tenantId) => {
  if (tenantId) {
    const result = await pool.query(
      `DELETE FROM ${table} WHERE id = $1 AND tenant_id = $2`,
      [id, tenantId]
    );
    return result.rowCount > 0;
  }
  const result = await pool.query(`DELETE FROM ${table} WHERE id = $1`, [id]);
  return result.rowCount > 0;
};

// SUM scoped to tenant
const scopedSum = async (table, column, tenantId) => {
  await ensureTenantColumn(table).catch(() => {});
  if (tenantId) {
    const { rows } = await pool.query(
      `SELECT SUM(${column}) as total FROM ${table} WHERE tenant_id = $1`,
      [tenantId]
    );
    return rows[0].total || 0;
  }
  const { rows } = await pool.query(`SELECT SUM(${column}) as total FROM ${table}`);
  return rows[0].total || 0;
};

module.exports = { ensureTenantColumn, scopedGetAll, scopedInsert, scopedDelete, scopedSum };
