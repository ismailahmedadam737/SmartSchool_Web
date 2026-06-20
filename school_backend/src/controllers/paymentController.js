const Payment = require('../models/paymentModel');

// 1. Shaqada lagu darayo lacagta (Create)
const createPayment = async (req, res) => {
    // Debugging: Waxaan u rogaynaa JSON si aan si cad u aragno waxa soo socda
    console.log("DEBUG: Xogta soo gaartay server-ka (req.body):", JSON.stringify(req.body, null, 2));
    
    try {
        // Hubinta in student_id uu ku jiro xogta
        // Waxaan hubinaynaa student_id maxaa yeelay database-kaagu wuu u baahan yahay
        if (!req.body.student_id) {
            console.error("DEBUG: Cilad! student_id waa null ama maqan yahay xogta soo gaartay.");
            return res.status(400).json({ 
                error: "student_id waa lagama maarmaan, fadlan hubi Flutter-kaaga inuu dirayo 'student_id' (underscore leh)." 
            });
        }

        // U dirida xogta Model-ka
        const newPayment = await Payment.addPayment(req.body);
        
        res.status(201).json({ 
            message: "Lacagta waa la kaydiyay", 
            data: newPayment 
        });
        
    } catch (err) {
        console.error("DEBUG: Cilad ka dhacday Payment model:", err.message);
        res.status(500).json({ error: "Server Error: " + err.message });
    }
};

// 2. Shaqada lagu helayo taariikhda lacag bixinta ee ardayga (History)
const getHistory = async (req, res) => {
    try {
        const { studentId } = req.params;
        console.log("DEBUG: Raadinta History-ga ardayga ID-giisu yahay:", studentId);
        
        if (!studentId) {
            return res.status(400).json({ error: "studentId waa loo baahan yahay" });
        }

        const history = await Payment.getPaymentsByStudent(studentId);
        res.json(history);
    } catch (err) {
        console.error("DEBUG: Cilad ka dhacday History:", err.message);
        res.status(500).json({ error: err.message });
    }
};

// 3. Shaqada lagu helayo wadarta dakhliga (Total Income)
const getTotalIncome = async (req, res) => {
    try {
        const total = await Payment.getTotalIncome();
        res.json({ total_income: total });
    } catch (err) {
        console.error("DEBUG: Cilad ka dhacday Total Income:", err.message);
        res.status(500).json({ error: err.message });
    }
};

module.exports = { 
    createPayment, 
    getHistory, 
    getTotalIncome 
};