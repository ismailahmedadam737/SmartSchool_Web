const pool = require('../config/db');

const Communication = {
  addMessage: async (data) => {
    const { name, phone, subject, message } = data;
    const query = `INSERT INTO communications (name, phone, subject, message) VALUES ($1, $2, $3, $4) RETURNING *`;
    const result = await pool.query(query, [name, phone, subject, message]);
    return result.rows[0];
  },

  // HUBI IN KANI U QORAN YAHAY SIDAN:
  fetchAll: async () => {
    const query = 'SELECT * FROM communications ORDER BY id DESC';
    const result = await pool.query(query);
    return result.rows;
  }
};

module.exports = Communication;