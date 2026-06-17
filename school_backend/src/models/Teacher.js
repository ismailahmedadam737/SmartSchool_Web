const pool = require('../config/db'); 

const Teacher = {
    // 1. Soo qaado dhamaan macalimiinta
    findAll: async () => {
        const result = await pool.query('SELECT * FROM teachers ORDER BY id DESC');
        return result.rows;
    },

    // 2. Abuur macalin cusub
    create: async (data) => {
        // Flutter: 'exp' -> Database: 'experience'
        const { name, district, phone, level, exp } = data; 
        
        const result = await pool.query(
            'INSERT INTO teachers (name, district, phone, level, experience) VALUES ($1, $2, $3, $4, $5) RETURNING *',
            [name, district, phone, level, exp]
        );
        return result.rows[0];
    },

    // 3. Wax ka bedel (Update)
    update: async (id, data) => {
        const { name, district, phone, level, exp } = data;
        const result = await pool.query(
            'UPDATE teachers SET name=$1, district=$2, phone=$3, level=$4, experience=$5 WHERE id=$6 RETURNING *',
            [name, district, phone, level, exp, id]
        );
        return result.rows[0];
    },

    // 4. Tirtir (Delete)
    delete: async (id) => {
        await pool.query('DELETE FROM teachers WHERE id = $1', [id]);
        return { message: "Macalinka waa la tirtiray" };
    }
};

module.exports = Teacher;