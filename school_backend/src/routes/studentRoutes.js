const express = require('express');
const router = express.Router();
const studentController = require('../controllers/studentController');

// Diiwaangelinta
router.post('/register', studentController.createStudent);

// Dhamaan Ardayda
router.get('/all', studentController.getStudents);

// Fasallada (Muhiim u ah Attendance Page)
router.get('/classes/all', studentController.getClasses);

// Tirtirista
router.delete('/delete/:id', studentController.deleteStudent); 

module.exports = router;