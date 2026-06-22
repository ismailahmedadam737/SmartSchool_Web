const pool = require('../config/db');

const Communication = {
  // 1. Kaydinta fariin cusub
  addMessage: async (data) => {
    const { name, phone, subject, message } = data;
    
    // Waxaan ku darnay 'created_at' si aan u ogaano goorta la diray
    const query = `
      INSERT INTO communications (name, phone, subject, message, created_at)
      VALUES ($1, $2, $3, $4, NOW())
      RETURNING *`;
      
    const result = await pool.query(query, [name, phone, subject, message]);
    return result.rows[0];
  },

  // 2. Soo akhrinta dhammaan fariimaha (Sida ugu habboon)
  fetchAll: async () => {
    // Waxaan u kala saraynay fariimaha si kan cusub uu ugu horreeyo
    const query = 'SELECT * FROM communications ORDER BY created_at DESC';
    const result = await pool.query(query);
    return result.rows;
  },

  // 3. Tirtiridda hal fariin (Haddii loo baahdo mustaqbalka)
  deleteMessage: async (id) => {
    const query = 'DELETE FROM communications WHERE id = $1';
    await pool.query(query, [id]);
    return true;
  }
};

module.exports = Communication;