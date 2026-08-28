const pool = require('../config/db');

const Salary = {
  // UPSERT: Kaydinta ama update-garaynta mushaharka macallinka iyadoo aan duplicate abuurin
  addPayment: async (id, data) => {
    const { amount, bonus, deduction, payment_method, payment_date } = data;
    
    const query = `
      INSERT INTO salary_payments (teacher_id, amount_paid, bonus, deduction, payment_method, payment_date)
      VALUES ($1, $2, $3, $4, $5, $6)
      ON CONFLICT (teacher_id) 
      DO UPDATE SET 
        amount_paid = EXCLUDED.amount_paid,
        bonus = EXCLUDED.bonus,
        deduction = EXCLUDED.deduction,
        payment_method = EXCLUDED.payment_method,
        payment_date = EXCLUDED.payment_date;
    `;
      
    await pool.query(query, [id, amount, bonus, deduction, payment_method, payment_date]);
  },

  getAll: async () => {
    const query = `
      SELECT DISTINCT ON (t.id)
        t.id, 
        t.name, 
        sp.amount_paid AS "amount", 
        CASE 
          WHEN sp.amount_paid IS NOT NULL AND sp.amount_paid::numeric > 0 THEN 'Paid'
          ELSE 'Pending'
        END AS "status"
      FROM teachers t
      LEFT JOIN salary_payments sp ON t.id = sp.teacher_id
      ORDER BY t.id, sp.payment_date DESC
    `;
    const result = await pool.query(query);
    return result.rows;
  },

  // Tirtiridda lacagta macallin keliya (Reset hal macallin)
  resetPayment: async (teacherId) => {
    const query = `DELETE FROM salary_payments WHERE teacher_id = $1`;
    await pool.query(query, [teacherId]);
  },

  // Tirtiridda dhammaan xogta mushaharka (Reset All)
  resetAllPayments: async () => {
    const query = `DELETE FROM salary_payments`;
    await pool.query(query);
  }
};

module.exports = Salary;