const pool = require('../config/db');
const { scopedGetAll, scopedInsert, scopedDelete, scopedSum, ensureTenantColumn } = require('../utils/tenantIsolation');

const Teacher = {
    findAll: async (tenantId) => {
        await ensureTenantColumn('teachers').catch(() => {});
        return scopedGetAll('teachers', tenantId, 'id DESC');
    },

    create: async (data, tenantId) => {
        await ensureTenantColumn('teachers').catch(() => {});
        const { name, district, phone, level, exp } = data;
        return scopedInsert('teachers',
            ['name', 'district', 'phone', 'level', 'experience'],
            [name, district, phone, level, exp],
            tenantId
        );
    },

    update: async (id, data, tenantId) => {
        const { name, district, phone, level, exp } = data;
        let result;
        if (tenantId) {
            result = await pool.query(
                'UPDATE teachers SET name=$1, district=$2, phone=$3, level=$4, experience=$5 WHERE id=$6 AND tenant_id=$7 RETURNING *',
                [name, district, phone, level, exp, id, tenantId]
            );
        } else {
            result = await pool.query(
                'UPDATE teachers SET name=$1, district=$2, phone=$3, level=$4, experience=$5 WHERE id=$6 RETURNING *',
                [name, district, phone, level, exp, id]
            );
        }
        return result.rows[0];
    },

    delete: async (id, tenantId) => {
        await scopedDelete('teachers', id, tenantId);
        return { message: "Macalinka waa la tirtiray" };
    }
};

module.exports = Teacher;