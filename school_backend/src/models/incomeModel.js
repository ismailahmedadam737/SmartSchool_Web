const pool = require('../config/db');
const { scopedGetAll, scopedInsert, scopedDelete, scopedSum, ensureTenantColumn } = require('../utils/tenantIsolation');

const Income = {
    create: async (data, tenantId) => {
        await ensureTenantColumn('incomes').catch(() => {});
        const { receipt_no, student_id, student_name, amount_paid, remaining_debt, payment_method, description, month } = data;
        return scopedInsert('incomes',
            ['receipt_no', 'student_id', 'student_name', 'amount_paid', 'remaining_debt', 'payment_method', 'description', 'month'],
            [receipt_no, student_id, student_name, amount_paid, remaining_debt, payment_method, description || 'School Fee Payment', month],
            tenantId
        );
    },

    getPaidIdsByMonth: async (month, tenantId) => {
        await ensureTenantColumn('incomes').catch(() => {});
        let result;
        if (tenantId) {
            result = await pool.query(
                'SELECT student_id FROM incomes WHERE month = $1 AND tenant_id = $2',
                [month, tenantId]
            );
        } else {
            result = await pool.query('SELECT student_id FROM incomes WHERE month = $1', [month]);
        }
        return result.rows.map(row => row.student_id);
    },

    getAll: async (tenantId) => scopedGetAll('incomes', tenantId, 'created_at DESC'),

    getTotal: async (tenantId) => scopedSum('incomes', 'amount_paid', tenantId),
};

module.exports = Income;