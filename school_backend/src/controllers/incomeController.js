const Income = require('../models/incomeModel');
const pool = require('../config/db');

const getTenantId = (req) => {
    const tid = req.tenantId || req.headers['x-tenant-id'] || req.query.tenant_id || req.body.tenant_id;
    return tid ? parseInt(tid, 10) : null;
};

// 1. Kaydi Rasiid Cusub
exports.createIncome = async (req, res) => {
    const { receipt_no, student_name, amount_paid, remaining_debt, payment_method, description, month } = req.body;
    const tenantId = getTenantId(req);

    try {
        let duplicateCheck;
        if (tenantId) {
            duplicateCheck = await pool.query(
                'SELECT * FROM incomes WHERE student_name = $1 AND month = $2 AND tenant_id = $3',
                [student_name, month, tenantId]
            );
        } else {
            duplicateCheck = await pool.query(
                'SELECT * FROM incomes WHERE student_name = $1 AND month = $2',
                [student_name, month]
            );
        }

        if (duplicateCheck.rows.length > 0) {
            return res.status(400).json({ 
                error: `Ardaygan hore ayuu u bixiyey lacagta bisha ${month}.` 
            });
        }

        const newIncome = await Income.create(req.body, tenantId);
        console.log("✅ Xogta waa la kaydiyey bisha:", month);
        res.status(201).json(newIncome);
    } catch (err) {
        console.error("❌ Database Error:", err.message);
        res.status(500).json({ error: "Rasiidka lama kaydin karo: " + err.message });
    }
};

// 2. Soo saar Dhammaan Rasiidhada
exports.getIncomes = async (req, res) => {
    try {
        const tenantId = getTenantId(req);
        const incomes = await Income.getAll(tenantId);
        res.status(200).json(incomes);
    } catch (err) {
        console.error("❌ Get Error:", err.message);
        res.status(500).json({ error: err.message });
    }
};