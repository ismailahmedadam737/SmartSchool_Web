const express = require('express');
const router = express.Router();
const teacherController = require('../controllers/teacherController');

// 1. Soo aqri dhamaan macalimiinta (URL: /api/teachers/all)
router.get('/all', teacherController.getTeachers);

// 2. Kaydi macalin cusub (URL: /api/teachers/register)
// Waxaan u beddelnay 'register' si uu ula mid noqdo Flutter-kaaga
router.post('/register', teacherController.addTeacher);

// 3. Cusboonaysii xogta macalinka (URL: /api/teachers/update/:id)
router.put('/update/:id', teacherController.updateTeacher);

// 4. Tirtir macalinka (URL: /api/teachers/delete/:id)
router.delete('/delete/:id', teacherController.deleteTeacher);

module.exports = router;