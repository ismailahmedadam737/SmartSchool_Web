const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
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
const aiRoutes = require('./routes/aiRoute');
const paymentRoutes = require('./routes/paymentRoutes');
const salaryRoutes = require('./routes/salaryRoutes'); // Ku daray salaryRoutes
const communicationRoutes = require('./routes/communicationRoutes'); // Ku daray communicationRoutes rasmiga ah

const app = express();

// --- Middleware ---
app.use(helmet()); 
app.use(cors()); 
app.use(morgan('dev')); 
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// --- Cache Control Middleware (Cillad-bixinta Code 304) ---
// Tani waxay hubinaysaa in Flutter uu mar walba helo xogta cusub ee database-ka
app.use((req, res, next) => {
  res.set('Cache-Control', 'no-store, no-cache, must-revalidate, private');
  next();
});

// --- Root Route ---
app.get('/', (req, res) => {
  res.send('🚀 Iftiinshe School Management System API is Running...');
});

// --- API Routes ---
app.use('/api/attendance', attendanceRoutes);
app.use('/api/students', studentRoutes);
app.use('/api/teachers', teacherRoutes);
app.use('/api/buses', busRoutes);
app.use('/api/exam', examRoutes);
app.use('/api/users', userRoutes);
app.use('/api/expenses', expenseRoutes);
app.use('/api/incomes', incomeRoutes);
app.use('/api/reports', reportRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/salary', salaryRoutes); // Ku daray salaryRoutes
app.use('/api/communications', communicationRoutes); // Ku daray communicationRoutes rasmiga ah

// --- Error Handling Middleware ---
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: 'Something went wrong on the server!' });
});

// --- Server Startup ---
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`🚀 Server is running on http://localhost:${PORT}`);
});