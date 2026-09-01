const express = require('express');
const router = express.Router();
const controller = require('../controllers/expenseController');

// Endpoint-yada
router.get('/', controller.getExpenses);
router.post('/', controller.createExpense);
router.get('/total-expenses', controller.getTotalExpenses);
// DELETE route - standard REST
router.delete('/:id', controller.deleteExpense);
// POST fallback - Flutter Web browser (CORS preflight xaaladda)
router.post('/delete/:id', controller.deleteExpense);

module.exports = router;