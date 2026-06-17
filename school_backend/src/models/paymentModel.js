const pool = require('../config/db');

const addPayment = async (data) => {
  const query = `INSERT INTO payments (student_id, amount, debt, month, transport_status, payment_date) 
                 VALUES ($1, $2, $3, $4, $5, NOW()) RETURNING *`;
  const values = [data.studentId, data.amount, data.debt, data.month, data.transport];
  const { rows } = await pool.query(query, values);
  return rows[0];
};

const getPaymentsByStudent = async (studentId) => {
  const query = `SELECT * FROM payments WHERE student_id = $1 ORDER BY payment_date DESC`;
  const { rows } = await pool.query(query, [studentId]);
  return rows;
};

// --- Halkan ku dar labadan function ee cusub ---

const getTotalIncome = async () => {
  // Waxaan u qaadanaynaa in 'amount' uu yahay dakhligaaga
  const query = `SELECT SUM(amount) as total FROM payments`;
  const { rows } = await pool.query(query);
  return rows[0].total || 0;
};

const getTotalExpenses = async () => {
  // Haddii aad leedahay table kale oo 'expenses' ah, waxaad ugu yeedhi kartaa halkan
  // Tusaale: SELECT SUM(amount) FROM expenses
  // Hadaad rabto inaan kuu sameeyo query-ga saxda ah ee expenses table-kaaga, ii sheeg magaca table-kaas.
  return 0; // Bedel haddii aad leedahay miiska kharashka
};

module.exports = { addPayment, getPaymentsByStudent, getTotalIncome, getTotalExpenses };