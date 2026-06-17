const pool = require('../config/db');

const Salary = {
  addPayment: async (id, data) => {
    const { amount, bonus, deduction, payment_method, payment_date } = data;
    
    const query = `
      INSERT INTO salary_payments (teacher_id, amount_paid, bonus, deduction, payment_method, payment_date)
      VALUES ($1, $2, $3, $4, $5, $6)`;
      
    await pool.query(query, [id, amount, bonus, deduction, payment_method, payment_date]);
  },

  getAll: async () => {
    // CILLAD-SAXID: Waxaan ka saarnay t.role madaama uusan ku jirin shaxdaada teachers
    const query = `
      SELECT 
        t.id, 
        t.name, 
        sp.amount_paid AS "amount", 
        CASE 
          WHEN sp.amount_paid IS NOT NULL THEN 'Paid'
          ELSE 'Pending'
        END AS "status"
      FROM teachers t
      LEFT JOIN salary_payments sp ON t.id = sp.teacher_id
      ORDER BY t.name ASC
    `;
    const result = await pool.query(query);
    return result.rows;
  }
};

module.exports = Salary;