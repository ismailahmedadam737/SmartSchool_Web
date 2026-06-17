const express = require('express');
const router = express.Router();
const reportController = require('../controllers/report_controller');

// URL: http://127.0.0.1:5000/api/reports/generate?class_name=Grade1
router.get('/generate', reportController.generateLiveReport);

module.exports = router;