const Salary = require('../models/salaryModel');

exports.getSalaryList = async (req, res) => {
  try {
    const data = await Salary.getAll();
    res.status(200).json(data); // Waxay u diraysaa Flutter liis ammaan ah
  } catch (err) {
    console.error("Error fetching salary list:", err);
    res.status(500).json({ error: err.message });
  }
};

exports.payTeacherSalary = async (req, res) => {
  try {
    const { id } = req.params;
    
    // Hubi in xogtu soo gashay req.body
    if (!req.body.payment_date) {
      req.body.payment_date = new Date().toISOString().split('T')[0]; // Maanta haddii la waayo
    }

    await Salary.addPayment(id, req.body);
    res.status(200).json({ message: "Mushaharka si guul leh ayaa loo kaydiyay" });
  } catch (err) {
    console.error("DATABASE ERROR:", err);
    res.status(500).json({ error: err.message });
  }
};