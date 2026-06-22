const express = require('express');
const router = express.Router();
const commCtrl = require('../controllers/communicationController');

router.post('/send', commCtrl.sendSchoolMessage);
router.get('/all', commCtrl.getAllMessages); // Kudar kani

module.exports = router;