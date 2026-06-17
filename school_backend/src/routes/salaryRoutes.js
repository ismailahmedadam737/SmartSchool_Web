const express = require('express');
const router = express.Router();
const salaryCtrl = require('../controllers/salaryController');

// Routes-ka u adeegaya Flutter-kaaga
router.get('/list', salaryCtrl.getSalaryList);
router.post('/pay/:id', salaryCtrl.payTeacherSalary);

module.exports = router;