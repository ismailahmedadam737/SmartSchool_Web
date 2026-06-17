const pool = require('../config/db');

const Communication = {
  addMessage: async (data) => {
    const { name, phone, subject, message } = data;
    
    // Magaca table-ka waxaa laga dhigay 'communications'
    const query = `
      INSERT INTO communications (name, phone, subject, message)
      VALUES ($1, $2, $3, $4)
      RETURNING *`;
      
    const result = await pool.query(query, [name, phone, subject, message]);
    return result.rows[0];
  }
};

module.exports = Communication;