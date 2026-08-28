const pool = require('../config/db');

const Income = {
    // 1. In la kaydiyo rasiid cusub
    create: async (data) => {
        const { 
            receipt_no, 
            student_id,    // 👈 Waxaa fiican in la isticmaalo ID-ga ardayga
            student_name, 
            amount_paid, 
            remaining_debt, 
            payment_method, 
            description,
            month 
        } = data;
        
        const query = `
            INSERT INTO incomes (receipt_no, student_id, student_name, amount_paid, remaining_debt, payment_method, description, month)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            RETURNING *;
        `;
        
        const values = [
            receipt_no, 
            student_id,    // 👈 Ku dar halkan
            student_name, 
            amount_paid, 
            remaining_debt, 
            payment_method, 
            description || "School Fee Payment",
            month 
        ];
        
        try {
            const result = await pool.query(query, values);
            return result.rows[0];
        } catch (err) {
            throw err;
        }
    },

    // 2. Tani waxay muhiim u tahay getPaidStudentIds-ka Flutter-ka
    getPaidIdsByMonth: async (month) => {
        const query = 'SELECT student_id FROM incomes WHERE month = $1';
        const result = await pool.query(query, [month]);
        // Waxay soo celinaysaa list ah ID-yo kaliya: [1, 5, 12]
        return result.rows.map(row => row.student_id);
    },

    // 3. In la soo wada aqriyo dakhliga
    getAll: async () => {
        const result = await pool.query('SELECT * FROM incomes ORDER BY created_at DESC');
        return result.rows;
    }
};

module.exports = Income;