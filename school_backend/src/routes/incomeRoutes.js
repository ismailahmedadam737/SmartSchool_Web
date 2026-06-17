const express = require('express');
const router = express.Router();
const Income = require('../models/incomeModel');

// POST: Kaydinta Rasiidhka
router.post('/', async (req, res) => {
    const { student_name, month } = req.body;

    try {
        // 1. Hubi haddii ardaygu bishan hore u bixiyey
        const isAlreadyPaid = await Income.checkExisting(student_name, month);

        if (isAlreadyPaid) {
            return res.status(400).json({
                success: false,
                message: `Cilad: Ardayga ${student_name} hore ayuu u bixiyey lacagta bisha ${month}!`
            });
        }

        // 2. Haddii uusan hore u bixin, kaydi rasiidhka cusub
        const newRecord = await Income.create(req.body);
        
        console.log(`✅ Rasiidh la kaydiyey: ${newRecord.receipt_no} (Bil: ${newRecord.month})`);
        
        res.status(201).json({
            success: true,
            data: newRecord
        });

    } catch (err) {
        console.error("❌ Error saving income:", err.message);
        res.status(500).json({ 
            success: false, 
            message: "Cillad ayaa ka dhacday database-ka",
            error: err.message 
        });
    }
});

// GET: Soo qaadashada dhammaan dakhliga (Optional - haddaad u baahato)
router.get('/', async (req, res) => {
    try {
        const records = await Income.getAll();
        res.status(200).json({
            success: true,
            data: records
        });
    } catch (err) {
        res.status(500).json({ success: false, error: err.message });
    }
});

module.exports = router;