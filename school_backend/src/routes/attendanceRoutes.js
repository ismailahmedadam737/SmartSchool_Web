const express = require('express');
const router = express.Router();
const attendanceController = require('../controllers/attendanceController');

// 1. Submit/Update Attendance
router.post('/submit', attendanceController.submitAttendance);

// 2. Get Daily History
router.get('/report/daily', attendanceController.getDailyReport);

// 3. Get Monthly Summary
router.get('/report/monthly', attendanceController.getSummary);

module.exports = router;