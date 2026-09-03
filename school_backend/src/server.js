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
app.use(helmet({
  crossOriginResourcePolicy: { policy: "cross-origin" },
}));
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Cache-Control', 'cache-control', 'Pragma', 'pragma'],
  optionsSuccessStatus: 200,
}));
app.options('*', cors()); // Preflight
app.use(morgan('dev')); 
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

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

// Ensure tenants table exists (run once on startup)
async function ensureTenantsTable() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS tenants (
        id                      SERIAL PRIMARY KEY,
        name                    TEXT NOT NULL,
        schema_name             TEXT UNIQUE NOT NULL,
        admin_email             TEXT,
        subscription_status     TEXT NOT NULL DEFAULT 'active',
        subscription_plan       TEXT NOT NULL DEFAULT 'basic',
        subscription_expires_at TIMESTAMPTZ,
        created_at              TIMESTAMPTZ DEFAULT NOW()
      )
    `);
    console.log('✅ Tenants table ready');
  } catch (err) {
    console.error('❌ Failed to create tenants table:', err.message);
  }
}
ensureTenantsTable();

// GET /admin/tenants – list all schools
app.get('/admin/tenants', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, name, schema_name, admin_email, subscription_status, subscription_plan, subscription_expires_at, created_at FROM tenants ORDER BY id'
    );
    res.json(result.rows);
  } catch (err) {
    console.error('List tenants error:', err.message);
    res.status(500).json({ error: 'Failed to list tenants' });
  }
});

// POST /admin/tenants – register a new school
app.post('/admin/tenants', async (req, res) => {
  const { name, admin_email, subscription_plan = 'basic', billing_cycle_days = 30 } = req.body;
  if (!name) return res.status(400).json({ error: 'name is required' });
  const schemaName = 'tenant_' + name.toLowerCase().replace(/[^a-z0-9]/g, '_') + '_' + Date.now();
  const expiresAt = new Date(Date.now() + billing_cycle_days * 86400000);
  try {
    const result = await pool.query(
      `INSERT INTO tenants (name, schema_name, admin_email, subscription_plan, subscription_expires_at)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [name, schemaName, admin_email, subscription_plan, expiresAt]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('Create tenant error:', err.message);
    res.status(500).json({ error: 'Failed to create tenant' });
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