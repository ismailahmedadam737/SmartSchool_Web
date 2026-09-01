const Expense = require('../models/expenseModel');

// 1. Soo hel dhammaan kharashyada
const getExpenses = async (req, res) => {
    try {
        const expenses = await Expense.getAll();
        res.status(200).json(expenses);
    } catch (err) {
        console.error("Error in getExpenses:", err.message);
        res.status(500).json({ error: "Xogta lama soo heli karo: " + err.message });
    }
};

// 2. Kaydi kharash cusub
const createExpense = async (req, res) => {
    // Xogta aan ka sugayno Flutter
    const { category, amount, note, title } = req.body;

    // Hubi in xogta lagama maarmaanka ah ay timid
    if (!category || !amount) {
        return res.status(400).json({ error: "Fadlan soo geli category iyo amount" });
    }

    try {
        // U gudbi xogta Model-ka (category, amount, note, title)
        const newExpense = await Expense.create(category, amount, note, title);
        res.status(201).json(newExpense);
    } catch (err) {
        console.error("Qaladka Database-ka (createExpense):", err);
        res.status(500).json({ error: "Lama kaydin karo: " + err.message });
    }
};

// 3. Wadarta guud ee kharashyada
const getTotalExpenses = async (req, res) => {
    try {
        const total = await Expense.getTotalExpenses();
        res.json({ total_expenses: parseFloat(total) });
    } catch (err) {
        console.error("Error in getTotalExpenses:", err.message);
        res.status(500).json({ error: err.message });
    }
};

// 4. Tirtir kharash gaar ah
const deleteExpense = async (req, res) => {
    const { id } = req.params;
    if (!id) {
        return res.status(400).json({ error: "ID-ga kharashka lama bixin" });
    }
    try {
        const deleted = await Expense.deleteById(id);
        if (!deleted) {
            return res.status(404).json({ error: "Kharashka lama helin" });
        }
        res.status(200).json({ message: "Kharashka si guul leh ayaa loo tirtiray", data: deleted });
    } catch (err) {
        console.error("Error in deleteExpense:", err.message);
        res.status(500).json({ error: "Tirtirku wuu fashilmay: " + err.message });
    }
};

module.exports = { getExpenses, createExpense, getTotalExpenses, deleteExpense };