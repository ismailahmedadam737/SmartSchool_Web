const pool = require('../config/db'); // Hubi in dariiqani sax yahay

const Bus = {
    // 1. Soo kici dhammaan basaska
    getAll: async () => {
        const res = await pool.query('SELECT * FROM buses ORDER BY id DESC');
        return res.rows;
    },

    // 2. Diwaangeli bas cusub
    create: async (bus) => {
        const { name, phone, plate, route } = bus;
        const res = await pool.query(
            'INSERT INTO buses (name, phone, plate, route) VALUES ($1, $2, $3, $4) RETURNING *',
            [name, phone, plate, route]
        );
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