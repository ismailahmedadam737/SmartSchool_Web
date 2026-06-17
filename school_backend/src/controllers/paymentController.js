const Payment = require('../models/paymentModel');

// 1. Shaqada lagu darayo lacagta (Create)
const createPayment = async (req, res) => {
  try {
    const newPayment = await Payment.addPayment(req.body);
    res.status(201).json({ message: "Lacagta waa la kaydiyay", data: newPayment });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// 2. Shaqada lagu helayo taariikhda lacag bixinta ee ardayga (History)
const getHistory = async (req, res) => {
  try {
    const { studentId } = req.params;
    const history = await Payment.getPaymentsByStudent(studentId);
    res.json(history);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// 3. Shaqada lagu helayo wadarta dakhliga (Total Income)
const getTotalIncome = async (req, res) => {
  try {
    const total = await Payment.getTotalIncome();
    res.json({ total_income: total });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// MUHIIM: Hubi in dhammaan magacyadan ay ku jiraan module.exports
module.exports = { 
  createPayment, 
  getHistory, 
  getTotalIncome 
};