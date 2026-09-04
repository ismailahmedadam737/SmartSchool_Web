const pool = require('../config/db');
const { scopedGetAll, scopedInsert, scopedDelete, ensureTenantColumn } = require('../utils/tenantIsolation');

const Bus = {
    // 1. Soo kici dhammaan basaska (tenant-scoped)
    getAll: async (tenantId) => {
        await ensureTenantColumn('buses').catch(() => {});
        return scopedGetAll('buses', tenantId, 'id DESC');
    },

    // 2. Diwaangeli bas cusub (tenant-scoped)
    create: async (bus, tenantId) => {
        await ensureTenantColumn('buses').catch(() => {});
        const { name, phone, plate, route } = bus;
        return scopedInsert('buses',
            ['name', 'phone', 'plate', 'route'],
            [name, phone, plate, route],
            tenantId
        );
    },

    // 3. Wax ka beddel baska jira (tenant-scoped)
    update: async (id, bus, tenantId) => {
        const { name, phone, plate, route } = bus;
        let res;
        if (tenantId) {
            res = await pool.query(
                'UPDATE buses SET name = $1, phone = $2, plate = $3, route = $4 WHERE id = $5 AND tenant_id = $6 RETURNING *',
                [name, phone, plate, route, id, tenantId]
            );
        } else {
            res = await pool.query(
                'UPDATE buses SET name = $1, phone = $2, plate = $3, route = $4 WHERE id = $5 RETURNING *',
                [name, phone, plate, route, id]
            );
        }
        return res.rows[0];
    },

    // 4. Tirtir baska (tenant-scoped)
    delete: async (id, tenantId) => {
        await scopedDelete('buses', id, tenantId);
        return { message: "Baska waa la tirtiray" };
    }
};

module.exports = Bus;