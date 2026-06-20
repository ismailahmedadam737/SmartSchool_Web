const express = require('express');
const router = express.Router();
const controller = require('../controllers/paymentController');

// 1. Endpoint-ka lagu darayo lacag bixinta cusub
router.post('/add', controller.createPayment);

// 2. Endpoint-ka lagu soo helayo taariikhda lacag bixinta ee arday gaar ah
router.get('/history/:studentId', controller.getHistory);

// 3. Endpoint-ka lagu helayo wadarta dakhliga (Dashboard)
router.get('/total-income', controller.getTotalIncome);

module.exports = router;