const pool = require('../config/db');

const Communication = {
  // 1. Ku darista fariin cusub (Default-ka is_read waa false)
  addMessage: async (data) => {
    const { name, phone, subject, message } = data;
    const query = `
      INSERT INTO communications (name, phone, subject, message, is_read)
      VALUES ($1, $2, $3, $4, false)
      RETURNING *`;
      
    const result = await pool.query(query, [name, phone, subject, message]);
    return result.rows[0];
  },

  // 2. Soo saarista dhammaan fariimaha (Si loogu tuso Admin-ka)
  findAllMessages: async () => {
    const query = `SELECT * FROM communications ORDER BY created_at DESC`;
    const result = await pool.query(query);
    return result.rows;
  },

  // 3. Calaamadee hal fariin in la aqriyay
  updateReadStatus: async (id, status) => {
    const query = `UPDATE communications SET is_read = $1 WHERE id = $2 RETURNING *`;
    const result = await pool.query(query, [status, id]);
    return result.rows[0];
  },

  // 4. Calaamadee dhammaan fariimaha in la aqriyay (Marka Admin-ku furo bogga)
  updateAllReadStatus: async (status) => {
    const query = `UPDATE communications SET is_read = $1 WHERE is_read = false`;
    await pool.query(query, [status]);
  }
};

module.exports = Communication;