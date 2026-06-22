const express = require('express');
const router = express.Router();
const commCtrl = require('../controllers/communicationController');

// Route-ka dirista fariinta
router.post('/send', commCtrl.sendSchoolMessage);

// Route-ka soo akhrinta fariimaha
router.get('/all', commCtrl.getAllMessages);

module.exports = router;