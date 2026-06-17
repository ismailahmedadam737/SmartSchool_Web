const express = require('express');
const router = express.Router();
const controller = require('../controllers/expenseController');

// Endpoint-yada
router.get('/', controller.getExpenses);
router.post('/', controller.createExpense);
// Kan ayaa xallinaya ciladii 404-ta
router.get('/total-expenses', controller.getTotalExpenses);

module.exports = router;