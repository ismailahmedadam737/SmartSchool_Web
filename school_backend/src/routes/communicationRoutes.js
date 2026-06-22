const express = require('express');
const router = express.Router();
const commCtrl = require('../controllers/communicationController');

// Route-ka dirista fariinta
router.post('/send', commCtrl.sendSchoolMessage);

// Route-ka soo akhrinta fariimaha
router.get('/all', commCtrl.getAllMessages);

// Route-ka tirtirida fariinta (Kani waa midka cusub)
// Fadlan hubi in function-ka 'deleteMessage' uu ku jiro 'communicationController.js'
router.delete('/:id', commCtrl.deleteMessage);

module.exports = router;