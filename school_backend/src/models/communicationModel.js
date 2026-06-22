const pool = require('../config/db');

const Communication = {
  // Fariin cusub ku darida
  addMessage: async (data) => {
    const { name, phone, subject, message } = data;
    const query = `INSERT INTO communications (name, phone, subject, message) VALUES ($1, $2, $3, $4) RETURNING *`;
    const result = await pool.query(query, [name, phone, subject, message]);
    return result.rows[0];
  },

  // Soo akhrinta dhammaan fariimaha
  fetchAll: async () => {
    const query = 'SELECT * FROM communications ORDER BY id DESC';
    const result = await pool.query(query);
    return result.rows;
  },

  // TIRTIRIDDA FARIINTA (Kani waa qaybtii aad u baahnayd)
  deleteById: async (id) => {
    const query = 'DELETE FROM communications WHERE id = $1';
    const result = await pool.query(query, [id]);
    // Waxay soo celinaysaa true haddii fariin la tirtiray, false haddii aysan jirin
    return result.rowCount > 0;
  }
};

module.exports = Communication;