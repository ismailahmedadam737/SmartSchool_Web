const express = require('express');
const router = express.Router();
const studentController = require('../controllers/studentController');

// Diiwaangelinta
router.post('/register', studentController.createStudent);

// Dhamaan Ardayda
router.get('/all', studentController.getStudents);

// Fasallada (Muhiim u ah Attendance Page)
router.get('/classes/all', studentController.getClasses);

// Cusboonaysiinta (PUT & POST)
router.put('/update/:id', studentController.updateStudent);
router.put('/:id', studentController.updateStudent);
router.post('/update/:id', studentController.updateStudent);
router.post('/:id', studentController.updateStudent);
router.post('/update', studentController.updateStudent);

// Tirtirista
router.delete('/delete/:id', studentController.deleteStudent); 
router.delete('/:id', studentController.deleteStudent); 

module.exports = router;