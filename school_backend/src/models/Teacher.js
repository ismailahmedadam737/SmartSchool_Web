const pool = require('../config/db'); 

const Teacher = {
    // 1. Soo qaado dhamaan macalimiinta
    findAll: async () => {
        await pool.query(`
            CREATE TABLE IF NOT EXISTS teachers (
                id SERIAL PRIMARY KEY,
                name VARCHAR(255),
                district VARCHAR(255),
                phone VARCHAR(255),
                level VARCHAR(255),
                experience VARCHAR(255),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        `).catch(() => {});
        const result = await pool.query('SELECT * FROM teachers ORDER BY id DESC');
        return result.rows;
    },

    // 2. Abuur macalin cusub
    create: async (data) => {
        await pool.query(`
            CREATE TABLE IF NOT EXISTS teachers (
                id SERIAL PRIMARY KEY,
                name VARCHAR(255),
                district VARCHAR(255),
                phone VARCHAR(255),
                level VARCHAR(255),
                experience VARCHAR(255),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        `).catch(() => {});
        
        const { name, district, phone, level, exp } = data; 
        let result;
        try {
            result = await pool.query(
                'INSERT INTO teachers (name, district, phone, level, experience) VALUES ($1, $2, $3, $4, $5) RETURNING *',
                [name, district, phone, level, exp]
            );
        } catch (err) {
            if (err.code === '23502' || err.code === '23505' || (err.message && (err.message.includes('null value in column "id"') || err.message.includes('violates unique constraint')))) {
                const maxRes = await pool.query('SELECT COALESCE(MAX(id), 0) + 1 AS next_id FROM teachers');
                const nextId = maxRes.rows[0].next_id;
                result = await pool.query(
                    'INSERT INTO teachers (id, name, district, phone, level, experience) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
                    [nextId, name, district, phone, level, exp]
                );
            } else {
                throw err;
            }
        }
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