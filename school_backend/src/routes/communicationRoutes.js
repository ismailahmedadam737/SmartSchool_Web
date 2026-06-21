const express = require('express');
const router = express.Router();
const commCtrl = require('../controllers/communicationController');

// 1. Dirista fariin cusub (Waalidka ayaa isticmaalaya)
// POST /api/communications/send
router.post('/send', commCtrl.sendSchoolMessage);

// 2. Soo aqrinta dhammaan fariimaha (Admin-ka ayaa isticmaalaya)
// GET /api/communications/all
router.get('/all', commCtrl.getAllMessages); 

// 3. Calaamadee fariin in la aqriyay (Si Badge-ka loo tirtiro)
// PUT /api/communications/mark-as-read/:id
router.put('/mark-as-read/:id', commCtrl.markAsRead);

// 4. (Optional) Calaamadee dhammaan fariimaha in la aqriyay hal mar
// PUT /api/communications/mark-all-as-read
router.put('/mark-all-as-read', commCtrl.markAllAsRead);

module.exports = router;