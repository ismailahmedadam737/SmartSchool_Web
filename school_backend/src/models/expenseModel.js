const pool = require('../config/db');
const { scopedGetAll, scopedInsert, scopedDelete, scopedSum, ensureTenantColumn } = require('../utils/tenantIsolation');

const Expense = {
    getAll: async (tenantId) => scopedGetAll('expenses', tenantId, 'created_at DESC'),

    create: async (category, amount, note, title, tenantId) => {
        await ensureTenantColumn('expenses').catch(() => {});
        return scopedInsert('expenses',
            ['category', 'amount', 'note', 'title'],
            [category, amount, note || '', title || 'Expense'],
            tenantId
        );
    },

    getTotalExpenses: async (tenantId) => scopedSum('expenses', 'amount', tenantId),

    deleteById: async (id, tenantId) => scopedDelete('expenses', id, tenantId),
};

module.exports = Expense;