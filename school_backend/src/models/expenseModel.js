const pool = require('../config/db'); 

const Expense = {
    getAll: async () => {
        const query = 'SELECT * FROM expenses ORDER BY created_at DESC';
        const { rows } = await pool.query(query);
        return rows;
    },

    // Waxaan meesha ka saaray 'is_paid' oo aan ku beddelay columns-ka aad haysato
    create: async (category, amount, note, title) => {
        const query = `
            INSERT INTO expenses (category, amount, note, title) 
            VALUES ($1, $2, $3, $4) 
            RETURNING *`;
        const values = [category, amount, note || '', title || 'Expense']; 
        const { rows } = await pool.query(query, values);
        return rows[0];
    },

    getTotalExpenses: async () => {
        const query = 'SELECT SUM(amount) as total FROM expenses';
        const { rows } = await pool.query(query);
        return rows[0].total || 0;
    },

    deleteById: async (id) => {
        const query = 'DELETE FROM expenses WHERE id = $1 RETURNING *';
        const { rows } = await pool.query(query, [id]);
        return rows[0];
    }
};

module.exports = Expense;