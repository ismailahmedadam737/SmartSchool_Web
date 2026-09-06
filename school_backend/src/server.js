const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const { Pool } = require('pg');
require('dotenv').config();

// Routes Import-yada
const attendanceRoutes = require('./routes/attendanceRoutes');
const studentRoutes = require('./routes/studentRoutes');
const teacherRoutes = require('./routes/teacherRoutes');
const busRoutes = require('./routes/busRoutes');
const examRoutes = require('./routes/examRoutes');
const userRoutes = require('./routes/userRoutes');
const expenseRoutes = require('./routes/expenseRoutes');
const incomeRoutes = require('./routes/incomeRoutes');
const reportRoutes = require('./routes/report_routes');
const paymentRoutes = require('./routes/paymentRoutes');
const salaryRoutes = require('./routes/salaryRoutes');
const communicationRoutes = require('./routes/communicationRoutes');

const app = express();

// Database Connection
const pool = new Pool({ 
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false } 
});

// --- Middleware ---
app.use((req, res, next) => {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS");
  res.header("Access-Control-Allow-Headers", "*");
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }
  next();
});
app.use(cors());
app.use(morgan('dev')); 
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// --- Cache Control ---
app.use((req, res, next) => {
  res.set('Cache-Control', 'no-store, no-cache, must-revalidate, private');
  next();
});

// --- API Routes ---
app.get('/', (req, res) => {
  res.send('🚀 Iftiinshe School Management System API is Running...');
});

// Routes usage
app.use('/api/attendance', attendanceRoutes);
app.use('/api/students', studentRoutes);
app.use('/api/teachers', teacherRoutes);
app.use('/api/buses', busRoutes);
app.use('/api/exam', examRoutes);
app.use('/api/users', userRoutes);

// ✅ DIRECT DELETE ROUTES - BEFORE expenseRoutes (priority routes)
app.delete('/api/expenses/:id', async (req, res) => {
  try {
    const { id } = req.params;
    console.log(`🗑️ Direct DELETE /api/expenses/${id}`);
    const result = await pool.query('DELETE FROM expenses WHERE id = $1 RETURNING *', [id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Kharashka lama helin' });
    res.status(200).json({ message: 'Si guul leh ayaa loo tirtiray', data: result.rows[0] });
  } catch (err) {
    console.error('Delete error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/expenses/delete/:id', async (req, res) => {
  try {
    const { id } = req.params;
    console.log(`🗑️ Direct POST /api/expenses/delete/${id}`);
    const result = await pool.query('DELETE FROM expenses WHERE id = $1 RETURNING *', [id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Kharashka lama helin' });
    res.status(200).json({ message: 'Si guul leh ayaa loo tirtiray', data: result.rows[0] });
  } catch (err) {
    console.error('Delete error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

app.use('/api/expenses', expenseRoutes);
app.use('/api/incomes', incomeRoutes);
app.use('/api/reports', reportRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/salary', salaryRoutes);
app.use('/api/communications', communicationRoutes);

// ============================================================
// 🔑 SUPER ADMIN ROUTES – /admin/tenants
// ============================================================

// Ensure tenants table & multi-tenant isolation columns exist
async function ensureTenantsTable() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS tenants (
        id                      SERIAL PRIMARY KEY,
        name                    TEXT NOT NULL,
        schema_name             TEXT UNIQUE NOT NULL,
        admin_email             TEXT,
        admin_username          TEXT,
        admin_password          TEXT,
        subscription_status     TEXT NOT NULL DEFAULT 'active',
        subscription_plan       TEXT NOT NULL DEFAULT 'basic',
        monthly_fee             NUMERIC(10,2) DEFAULT 50.00,
        subscription_expires_at TIMESTAMPTZ,
        created_at              TIMESTAMPTZ DEFAULT NOW()
      )
    `);
    // Add columns if upgrading from old schema
    await pool.query(`ALTER TABLE tenants ADD COLUMN IF NOT EXISTS admin_username TEXT`).catch(() => {});
    await pool.query(`ALTER TABLE tenants ADD COLUMN IF NOT EXISTS admin_password TEXT`).catch(() => {});
    await pool.query(`ALTER TABLE tenants ADD COLUMN IF NOT EXISTS monthly_fee NUMERIC(10,2) DEFAULT 50.00`).catch(() => {});

    // Ensure tenant_id exists across core tables for Shared DB Shared Schema Isolation
    const tables = ['users', 'students', 'teachers', 'buses', 'expenses', 'incomes', 'payments'];
    for (const tbl of tables) {
      await pool.query(`ALTER TABLE ${tbl} ADD COLUMN IF NOT EXISTS tenant_id INT REFERENCES tenants(id) ON DELETE CASCADE`).catch(() => {});
      await pool.query(`CREATE INDEX IF NOT EXISTS idx_${tbl}_tenant_id ON ${tbl}(tenant_id)`).catch(() => {});
    }

    // Auto-link orphaned users in users table to tenants table if username matches admin_username
    await pool.query(`
      UPDATE users u
      SET tenant_id = t.id
      FROM tenants t
      WHERE LOWER(u.username) = LOWER(t.admin_username) AND u.tenant_id IS NULL;
    `).catch(() => {});

    // Ensure school_settings table exists for storing permanent school banners & timetables
    await pool.query(`
      CREATE TABLE IF NOT EXISTS school_settings (
        id            SERIAL PRIMARY KEY,
        tenant_id     INT REFERENCES tenants(id) ON DELETE CASCADE,
        setting_key   TEXT NOT NULL,
        setting_value TEXT NOT NULL,
        updated_at    TIMESTAMPTZ DEFAULT NOW(),
        CONSTRAINT unique_tenant_setting UNIQUE(tenant_id, setting_key)
      )
    `).catch(() => {});

    console.log('✅ Multi-Tenant Database Isolation Schema Ready');
  } catch (err) {
    console.error('❌ Failed to prepare multi-tenant schema:', err.message);
  }
}
ensureTenantsTable();

// ============================================================
// 📌 PERMANENT TENANT SETTINGS ROUTES (Banners, Timetables, etc.)
// ============================================================
app.get('/api/settings/:key', async (req, res) => {
  try {
    const tenantId = req.headers['x-tenant-id'];
    const { key } = req.params;
    if (!tenantId) {
      return res.status(200).json({ value: null });
    }
    const result = await pool.query(
      'SELECT setting_value FROM school_settings WHERE tenant_id = $1 AND setting_key = $2',
      [tenantId, key]
    );
    if (result.rows.length === 0) return res.status(200).json({ value: null });
    res.json({ value: result.rows[0].setting_value });
  } catch (err) {
    console.error('Get setting error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/settings/:key', async (req, res) => {
  try {
    const tenantId = req.headers['x-tenant-id'];
    const { key } = req.params;
    const { value } = req.body;
    if (!tenantId) {
      return res.status(400).json({ error: 'Tenant ID is required' });
    }
    const strVal = typeof value === 'string' ? value : JSON.stringify(value);
    await pool.query(
      `INSERT INTO school_settings (tenant_id, setting_key, setting_value, updated_at)
       VALUES ($1, $2, $3, NOW())
       ON CONFLICT (tenant_id, setting_key)
       DO UPDATE SET setting_value = EXCLUDED.setting_value, updated_at = NOW()`,
      [tenantId, key, strVal]
    );
    res.json({ success: true, message: 'Setting saved permanently!' });
  } catch (err) {
    console.error('Save setting error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

// Automated Daily Cron Job (Runs at 00:00 every midnight) to suspend expired subscriptions
const cron = require('node-cron');
cron.schedule('0 0 * * *', async () => {
  try {
    const result = await pool.query(
      `UPDATE tenants 
       SET subscription_status = 'suspended' 
       WHERE subscription_expires_at < NOW() AND subscription_status = 'active' 
       RETURNING id, name`
    );
    if (result.rows.length > 0) {
      console.log(`⏰ Cron Job: Auto-suspended ${result.rows.length} expired tenants:`, result.rows.map(r => r.name));
    }
  } catch (err) {
    console.error('Cron job error:', err.message);
  }
});

// GET /admin/stats – Platform-wide Overview Metrics
app.get('/admin/stats', async (req, res) => {
  try {
    const tenantsRes = await pool.query(`
      SELECT 
        COUNT(*) as total_schools,
        COUNT(CASE WHEN subscription_status = 'active' THEN 1 END) as active_schools,
        COUNT(CASE WHEN subscription_status = 'suspended' THEN 1 END) as suspended_schools,
        COUNT(CASE WHEN subscription_expires_at < NOW() THEN 1 END) as expired_schools,
        COALESCE(SUM(monthly_fee), 0) as estimated_mrr
      FROM tenants
    `);
    const stats = tenantsRes.rows[0];
    res.json({
      totalSchools: parseInt(stats.total_schools, 10),
      activeSchools: parseInt(stats.active_schools, 10),
      suspendedSchools: parseInt(stats.suspended_schools, 10),
      expiredSchools: parseInt(stats.expired_schools, 10),
      estimatedMrr: parseFloat(stats.estimated_mrr || 0),
    });
  } catch (err) {
    console.error('Get admin stats error:', err.message);
    res.status(500).json({ error: 'Failed to fetch platform stats' });
  }
});

// GET /admin/tenants – list all schools
app.get('/admin/tenants', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, name, schema_name, admin_email, admin_username, admin_password,
              subscription_status, subscription_plan, monthly_fee, subscription_expires_at, created_at
       FROM tenants ORDER BY id`
    );
    res.json(result.rows);
  } catch (err) {
    console.error('List tenants error:', err.message);
    res.status(500).json({ error: 'Failed to list tenants' });
  }
});

// GET /admin/tenants/:id – single tenant detail
app.get('/admin/tenants/:id', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, name, schema_name, admin_email, admin_username, admin_password,
              subscription_status, subscription_plan, monthly_fee, subscription_expires_at, created_at
       FROM tenants WHERE id = $1`, [req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Not found' });
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch tenant' });
  }
});

// POST /admin/tenants – register a new school
app.post('/admin/tenants', async (req, res) => {
  const {
    name,
    admin_email = '',
    admin_username,
    admin_password,
    subscription_plan = 'basic',
    billing_cycle_days = 30,
    monthly_fee = 50.00
  } = req.body;
  if (!name)           return res.status(400).json({ error: 'name is required' });
  if (!admin_username) return res.status(400).json({ error: 'admin_username is required' });
  if (!admin_password) return res.status(400).json({ error: 'admin_password is required' });

  const schemaName = 'tenant_' + name.toLowerCase().replace(/[^a-z0-9]/g, '_') + '_' + Date.now();
  const expiresAt  = new Date(Date.now() + billing_cycle_days * 86400000);
  try {
    const result = await pool.query(
      `INSERT INTO tenants
         (name, schema_name, admin_email, admin_username, admin_password, subscription_plan, monthly_fee, subscription_expires_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *`,
      [name, schemaName, admin_email, admin_username, admin_password, subscription_plan, monthly_fee, expiresAt]
    );
    const newTenant = result.rows[0];

    // Also register the admin in the users table scoped with tenant_id
    try {
      const existingUser = await pool.query('SELECT id FROM users WHERE LOWER(username) = LOWER($1)', [admin_username]);
      if (existingUser.rows.length > 0) {
        await pool.query('UPDATE users SET password = $1, role = \'Admin\', tenant_id = $2 WHERE id = $3', [admin_password, newTenant.id, existingUser.rows[0].id]);
      } else {
        await pool.query('INSERT INTO users (username, password, role, tenant_id) VALUES ($1, $2, \'Admin\', $3)', [admin_username, admin_password, newTenant.id]);
      }
    } catch (uErr) {
      console.log('Note: users table insert log:', uErr.message);
    }
    res.status(201).json(newTenant);
  } catch (err) {
    console.error('Create tenant error:', err.message);
    res.status(500).json({ error: 'Failed to create tenant' });
  }
});

// POST /admin/tenants/:id/renew – 1-Click Subscription Renewal
app.post('/admin/tenants/:id/renew', async (req, res) => {
  const { id } = req.params;
  const { days = 30 } = req.body;
  try {
    const tenantRes = await pool.query('SELECT subscription_expires_at FROM tenants WHERE id = $1', [id]);
    if (tenantRes.rows.length === 0) return res.status(404).json({ error: 'Tenant not found' });

    let currentExpiry = new Date(tenantRes.rows[0].subscription_expires_at || Date.now());
    if (currentExpiry < new Date()) {
      currentExpiry = new Date(); // Reset from today if expired
    }
    const newExpiry = new Date(currentExpiry.getTime() + days * 86400000);

    const result = await pool.query(
      `UPDATE tenants 
       SET subscription_status = 'active', subscription_expires_at = $1 
       WHERE id = $2 RETURNING *`,
      [newExpiry, id]
    );
    res.json({ message: `Successfully renewed subscription for ${days} days!`, tenant: result.rows[0] });
  } catch (err) {
    console.error('Renew tenant error:', err.message);
    res.status(500).json({ error: 'Failed to renew subscription' });
  }
});

// POST /admin/tenants/:id/impersonate – Login As School
app.post('/admin/tenants/:id/impersonate', async (req, res) => {
  const { id } = req.params;
  try {
    const result = await pool.query('SELECT * FROM tenants WHERE id = $1', [id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'School not found' });

    const tenant = result.rows[0];
    res.json({
      message: `Successfully logged in as ${tenant.name}`,
      impersonation: {
        isImpersonating: true,
        originalRole: 'SuperAdmin',
        tenantId: tenant.id,
        tenantName: tenant.name,
        adminUsername: tenant.admin_username || 'Admin',
        assignedRole: 'Admin'
      }
    });
  } catch (err) {
    console.error('Impersonate error:', err.message);
    res.status(500).json({ error: 'Failed to impersonate school' });
  }
});

// PATCH /admin/tenants/:id/status – activate / suspend / cancel
app.patch('/admin/tenants/:id/status', async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;
  if (!['active', 'suspended', 'cancelled'].includes(status)) {
    return res.status(400).json({ error: 'Invalid status. Use: active | suspended | cancelled' });
  }
  try {
    const result = await pool.query(
      'UPDATE tenants SET subscription_status = $1 WHERE id = $2 RETURNING *',
      [status, id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Tenant not found' });
    res.json(result.rows[0]);
  } catch (err) {
    console.error('Update tenant status error:', err.message);
    res.status(500).json({ error: 'Failed to update status' });
  }
});

// DELETE /admin/tenants/:id – remove a school record
app.delete('/admin/tenants/:id', async (req, res) => {
  const { id } = req.params;
  try {
    const result = await pool.query('DELETE FROM tenants WHERE id = $1 RETURNING *', [id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Tenant not found' });
    res.json({ message: 'Tenant deleted', data: result.rows[0] });
  } catch (err) {
    console.error('Delete tenant error:', err.message);
    res.status(500).json({ error: 'Failed to delete tenant' });
  }
});



// --- Error Handling ---
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: 'Something went wrong on the server!' });
});

// --- Server Startup ---
const PORT = process.env.PORT || 10000;
app.listen(PORT, () => {
  console.log(`🚀 Server is running on port ${PORT}`);
  console.log(`✅ Expense DELETE route registered: DELETE /api/expenses/:id`);
  console.log(`✅ Expense DELETE fallback: POST /api/expenses/delete/:id`);
});