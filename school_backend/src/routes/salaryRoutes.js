const express = require('express');
const router = express.Router();
const salaryCtrl = require('../controllers/salaryController');

// Routes-ka aasaasiga ah ee Flutter
router.get('/list', salaryCtrl.getSalaryList);
router.post('/pay/:id', salaryCtrl.payTeacherSalary);

// Reset hal macallin (DELETE ama POST adoo ka eegaya dhinaca Flutter)
router.delete('/reset/:id', salaryCtrl.resetTeacherSalary);
router.post('/reset/:id', salaryCtrl.resetTeacherSalary);

// Reset All (Haddii aad rabto in badhanka Reset All ee Flutter uu hal mar backend-ka soo waco halkii uu loop samayn lahaa)
router.delete('/reset-all', salaryCtrl.resetAllSalaries);
router.post('/reset-all', salaryCtrl.resetAllSalaries);

module.exports = router;