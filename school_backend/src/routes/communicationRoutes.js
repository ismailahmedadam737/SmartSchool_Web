const express = require('express');
const router = express.Router();
const commCtrl = require('../controllers/communicationController');

// 1. Fariin cusub dirista (POST: /api/communications/send)
router.post('/send', commCtrl.sendSchoolMessage);

// 2. Soo akhrinta dhammaan fariimaha (GET: /api/communications/all)
router.get('/all', commCtrl.getAllMessages);

// 3. Tirtirida fariin gaar ah (DELETE: /api/communications/:id)
// Fadlan hubi in id-ga la soo dirayo uu yahay kan saxda ah ee database-ka
router.delete('/:id', commCtrl.deleteMessage);

module.exports = router;