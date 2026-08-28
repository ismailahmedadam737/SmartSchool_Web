const express = require('express');
const router = express.Router();
const controller = require('../controllers/transaction.controller');

// URL-ka Flutter uu wacayo wuxuu noqonayaa: /api/transactions/summary
router.get('/summary', controller.getSummary);

module.exports = router;