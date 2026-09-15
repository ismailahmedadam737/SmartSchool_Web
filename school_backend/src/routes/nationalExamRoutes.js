const express = require('express');
const router = express.Router();
const nationalExamController = require('../controllers/nationalExamController');

// GET /api/national-exams -> Fetch all exams (optionally filter by ?subject= & ?year=)
router.get('/', nationalExamController.getExams);

// POST /api/national-exams/upload -> Upload or update past paper
router.post('/upload', nationalExamController.uploadExam);

// DELETE /api/national-exams/:id -> Delete paper by ID
router.delete('/:id', nationalExamController.deleteExam);
router.post('/delete/:id', nationalExamController.deleteExam); // Fallback post route

module.exports = router;
