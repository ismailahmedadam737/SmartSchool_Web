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