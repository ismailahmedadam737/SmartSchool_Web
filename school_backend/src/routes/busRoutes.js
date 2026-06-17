const express = require('express');
const router = express.Router();
const busController = require('../controllers/busController');

// URL: /api/buses/all
router.get('/all', busController.getAllBuses);

// URL: /api/buses/register
router.post('/register', busController.registerBus);

// URL: /api/buses/update/:id
router.put('/update/:id', busController.updateBus);

// URL: /api/buses/delete/:id
router.delete('/delete/:id', busController.deleteBus);

module.exports = router;