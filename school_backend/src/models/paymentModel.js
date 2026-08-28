const pool = require('../config/db');

// Shaqadan waxaa loo habeeyay inay si sax ah ula jaanqaado Database-kaaga
const addPayment = async (data) => {
  const query = `INSERT INTO payments (student_id, amount, debt, month, transport, payment_date) 
                 VALUES ($1, $2, $3, $4, $5, NOW()) RETURNING *`;
  
  const values = [
    data.student_id, 
    data.amount, 
    data.debt, 
    data.month, 
    data.transport
  ];
  
  const { rows } = await pool.query(query, values);
  return rows[0];
};

const getPaymentsByStudent = async (studentId) => {
  const query = `SELECT * FROM payments WHERE student_id = $1 ORDER BY payment_date DESC`;
  const { rows } = await pool.query(query, [studentId]);
  return rows;
};

const getTotalIncome = async () => {
  const query = `SELECT SUM(amount) as total FROM payments`;
  const { rows } = await pool.query(query);
  return rows[0].total || 0;
};

const getTotalExpenses = async () => {
  const query = `SELECT SUM(amount) as total FROM expenses`;
  const { rows } = await pool.query(query);
  return rows[0].total || 0;
};

// Shaqada cusub ee tirtiraysa xogta lacagaha oo dhan database-ka
const resetAllPayments = async () => {
  const query = `DELETE FROM payments`;
  await pool.query(query);
};

module.exports = { 
  addPayment, 
  getPaymentsByStudent, 
  getTotalIncome, 
  getTotalExpenses,
  resetAllPayments 
};