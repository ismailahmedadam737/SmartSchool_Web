const express = require('express');
const router = express.Router();
const commCtrl = require('../controllers/communicationController');

// 1. Route-ka lagu soo diro fariimaha cusub (PostgreSQL Insert)
// Endpoint-ka rasmiga ah: POST /api/communications/send
router.post('/send', commCtrl.sendSchoolMessage);

// 2. (Optional) Route-ka mustaqbalka haddii aad rabto inaad fariimaha oo dhan kasoo aqriso database-ka
// Endpoint-ka rasmiga ah: GET /api/communications/all
// router.get('/all', commCtrl.getAllMessages); 

module.exports = router;