const express = require('express');
const router = express.Router();
const controller = require('../controllers/paymentController');

router.post('/add', controller.createPayment);
router.get('/history/:studentId', controller.getHistory);

// KU DAR KHADKAN SI UU 404-KA U BAXO:
router.get('/total-income', controller.getTotalIncome);

module.exports = router;