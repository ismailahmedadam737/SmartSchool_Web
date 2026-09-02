const pool = require('../config/db'); // Hubi in dariiqani sax yahay

const Bus = {
    // 1. Soo kici dhammaan basaska
    getAll: async () => {
        await pool.query(`
            CREATE TABLE IF NOT EXISTS buses (
                id SERIAL PRIMARY KEY,
                name VARCHAR(255),
                phone VARCHAR(255),
                plate VARCHAR(255),
                route VARCHAR(255),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        `).catch(() => {});
        const res = await pool.query('SELECT * FROM buses ORDER BY id DESC');
        return res.rows;
    },

    // 2. Diwaangeli bas cusub
    create: async (bus) => {
        await pool.query(`
            CREATE TABLE IF NOT EXISTS buses (
                id SERIAL PRIMARY KEY,
                name VARCHAR(255),
                phone VARCHAR(255),
                plate VARCHAR(255),
                route VARCHAR(255),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        `).catch(() => {});
        const { name, phone, plate, route } = bus;
        let res;
        try {
            res = await pool.query(
                'INSERT INTO buses (name, phone, plate, route) VALUES ($1, $2, $3, $4) RETURNING *',
                [name, phone, plate, route]
            );
        } catch (err) {
            if (err.code === '23502' || err.code === '23505' || (err.message && (err.message.includes('null value in column "id"') || err.message.includes('violates unique constraint')))) {
                const maxRes = await pool.query('SELECT COALESCE(MAX(id), 0) + 1 AS next_id FROM buses');
                const nextId = maxRes.rows[0].next_id;
                res = await pool.query(
                    'INSERT INTO buses (id, name, phone, plate, route) VALUES ($1, $2, $3, $4, $5) RETURNING *',
                    [nextId, name, phone, plate, route]
                );
            } else {
                throw err;
            }
        }
        return res.rows[0];
    },

    // 3. Wax ka beddel baska jira (Update)
    update: async (id, bus) => {
        const { name, phone, plate, route } = bus;
        const res = await pool.query(
            'UPDATE buses SET name = $1, phone = $2, plate = $3, route = $4 WHERE id = $5 RETURNING *',
            [name, phone, plate, route, id]
        );
        return res.rows[0];
    },

    // 4. Tirtir baska (Delete)
    delete: async (id) => {
        await pool.query('DELETE FROM buses WHERE id = $1', [id]);
        return { message: "Bus deleted successfully" };
    }
};

module.exports = Bus;