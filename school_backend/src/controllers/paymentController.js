const Payment = require('../models/paymentModel');

// 1. Shaqada lagu darayo lacagta (Create)
const createPayment = async (req, res) => {
  // --- DEBUGGING: Tani waxay ku tusaysaa waxa dhabta ah ee ka yimid Flutter ---
  console.log("DEBUG: Xogta soo gaartay server-ka (req.body):", JSON.stringify(req.body, null, 2));
  
  try {
    // Hubinta in xogta ay jirto ka hor inta aan la dirin model-ka
    if (!req.body.student_id) {
      console.error("DEBUG: Cilad! student_id waa null ama maqan yahay.");
      return res.status(400).json({ error: "student_id waa lagama maarmaan (required)." });
    }

    const newPayment = await Payment.addPayment(req.body);
    res.status(201).json({ message: "Lacagta waa la kaydiyay", data: newPayment });
  } catch (err) {
    console.error("DEBUG: Cilad ka dhacday Payment model:", err.message);
    res.status(500).json({ error: err.message });
  }
};

// 2. Shaqada lagu helayo taariikhda lacag bixinta ee ardayga (History)
const getHistory = async (req, res) => {
  try {
    const { studentId } = req.params;
    console.log("DEBUG: Raadinta History-ga ardayga:", studentId);
    
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