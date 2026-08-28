const Salary = require('../models/salaryModel');

exports.getSalaryList = async (req, res) => {
  try {
    const data = await Salary.getAll();
    res.status(200).json(data);
  } catch (err) {
    console.error("Error fetching salary list:", err);
    res.status(500).json({ error: err.message });
  }
};

exports.payTeacherSalary = async (req, res) => {
  try {
    const { id } = req.params;
    
    if (!req.body.payment_date) {
      req.body.payment_date = new Date().toISOString().split('T')[0];
    }

    await Salary.addPayment(id, req.body);
    
    res.status(200).json({ message: "Mushaharka si guul leh ayaa loo kaydiyay / update-gareeyey" });
  } catch (err) {
    console.error("DATABASE ERROR:", err);
    res.status(500).json({ error: err.message });
  }
};

// Reset hal macallin
exports.resetTeacherSalary = async (req, res) => {
  try {
    const { id } = req.params;
    await Salary.resetPayment(id);
    res.status(200).json({ message: "Mushaharkii macallinka waa la celiyay (Reset)" });
  } catch (err) {
    console.error("RESET ERROR:", err);
    res.status(500).json({ error: err.message });
  }
};

// Reset dhammaan macallimiinta hal mar (Reset All)
exports.resetAllSalaries = async (req, res) => {
  try {
    await Salary.resetAllPayments();
    res.status(200).json({ message: "Dhammaan mushaharkii waa la tirtiray (Reset All)" });
  } catch (err) {
    console.error("RESET ALL ERROR:", err);
    res.status(500).json({ error: err.message });
  }
};