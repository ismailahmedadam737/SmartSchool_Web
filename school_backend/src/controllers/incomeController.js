const pool = require('../config/db');

// 1. Kaydi Rasiid Cusub
exports.createIncome = async (req, res) => {
    // Waxaan ku darnay 'month' oo laga soo dirayo Flutter
    const { receipt_no, student_name, amount_paid, remaining_debt, payment_method, description, month } = req.body;
    
    try {
        // 🛑 HUBIN: Ma jiraa ardaygan oo bishan lacag ka bixiyey miiska incomes?
        const duplicateCheck = await pool.query(
            'SELECT * FROM incomes WHERE student_name = $1 AND month = $2',
            [student_name, month]
        );

        if (duplicateCheck.rows.length > 0) {
            return res.status(400).json({ 
                error: `Ardaygan hore ayuu u bixiyey lacagta bisha ${month}.` 
            });
        }

        // ✅ Haddii uusan hore u bixin, kaydi hadda
        const result = await pool.query(
            `INSERT INTO incomes (receipt_no, student_name, amount_paid, remaining_debt, payment_method, description, month) 
             VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
            [
                receipt_no, 
                student_name, 
                amount_paid, 
                remaining_debt, 
                payment_method, 
                description || "School Fee Payment",
                month // Bisha halkan ayay galaysaa
            ]
        );
        
        console.log("✅ Xogta waa la kaydiyey bisha:", month);
        res.status(201).json(result.rows[0]);
    } catch (err) {
        console.error("❌ Database Error:", err.message);
        res.status(500).json({ error: "Rasiidka lama kaydin karo: " + err.message });
    }
};

// 2. Soo saar Dhammaan Rasiidhada
exports.getIncomes = async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM incomes ORDER BY created_at DESC');
        res.status(200).json(result.rows);
    } catch (err) {
        console.error("❌ Get Error:", err.message);
        res.status(500).json({ error: err.message });
    }
};