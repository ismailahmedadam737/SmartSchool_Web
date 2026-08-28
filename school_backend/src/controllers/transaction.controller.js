const Transaction = require('../models/transaction.model');

exports.getSummary = async (req, res) => {
  try {
    const income = await Transaction.sum('amount', { where: { type: 'income' } }) || 0;
    const expenses = await Transaction.sum('amount', { where: { type: 'expense' } }) || 0;
    
    res.status(200).json({
      total_income: parseFloat(income),
      total_expenses: parseFloat(expenses)
    });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
};