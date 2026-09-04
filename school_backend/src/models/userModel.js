const pool = require('../config/db');
const { scopedGetAll, scopedInsert, scopedDelete, ensureTenantColumn } = require('../utils/tenantIsolation');

const UserModel = {

  // GET ALL USERS (tenant-scoped)
  getAll: async (tenantId) => {
    await ensureTenantColumn('users').catch(() => {});
    if (tenantId) {
      return await pool.query('SELECT id, username, role, tenant_id FROM users WHERE tenant_id = $1 ORDER BY id DESC', [tenantId]);
    }
    return await pool.query('SELECT id, username, role, tenant_id FROM users ORDER BY id DESC');
  },

  // GET BY ID
  getById: async (id, tenantId) => {
    if (tenantId) {
      return await pool.query('SELECT id, username, role, tenant_id FROM users WHERE id = $1 AND tenant_id = $2', [id, tenantId]);
    }
    return await pool.query('SELECT id, username, role, tenant_id FROM users WHERE id = $1', [id]);
  },

  // CREATE USER (tenant-scoped)
  create: async (username, password, role, tenantId) => {
    await ensureTenantColumn('users').catch(() => {});
    if (tenantId) {
      return await pool.query(
        'INSERT INTO users (username, password, role, tenant_id) VALUES ($1, $2, $3, $4) RETURNING id, username, role, tenant_id',
        [username, password, role, tenantId]
      );
    }
    return await pool.query(
      'INSERT INTO users (username, password, role) VALUES ($1, $2, $3) RETURNING id, username, role',
      [username, password, role]
    );
  },

  // UPDATE USER
  update: async (id, username, password, role, tenantId) => {
    if (tenantId) {
      return await pool.query(
        'UPDATE users SET username=$1, password=$2, role=$3 WHERE id=$4 AND tenant_id=$5 RETURNING id, username, role, tenant_id',
        [username, password, role, id, tenantId]
      );
    }
    return await pool.query(
      'UPDATE users SET username=$1, password=$2, role=$3 WHERE id=$4 RETURNING id, username, role',
      [username, password, role, id]
    );
  },

  // DELETE USER
  delete: async (id, tenantId) => {
    if (tenantId) {
      return await pool.query('DELETE FROM users WHERE id=$1 AND tenant_id=$2', [id, tenantId]);
    }
    return await pool.query('DELETE FROM users WHERE id=$1', [id]);
  },

  // LOGIN
  login: async (username, password) => {
    return await pool.query(
      'SELECT * FROM users WHERE username=$1 AND password=$2',
      [username, password]
    );
  }
};

module.exports = UserModel;