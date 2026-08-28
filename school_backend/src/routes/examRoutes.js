const express = require('express');
const router = express.Router();
const examController = require('../controllers/examController');

/**
 * 1. Kaydinta Natiijooyinka (Teacher Side)
 * Shaqada: Waxay kaydisaa ama update-gareysaa natiijooyinka (Upsert)
 * Endpoint: POST /api/exam/save
 */
router.post('/save', examController.saveExamination);

/**
 * 2. Soo saarista Natiijooyinka Hal Arday (Student Side)
 * Shaqada: Waxay soo celisaa dhamaan natiijooyinka hal arday
 * Endpoint: GET /api/exam/student/:studentId
 */
router.get('/student/:studentId', examController.getResults);

/**
 * 3. Tirtirista Dhamaan Xogta (Yearly Reset)
 * Shaqada: Waxay database-ka ka saartaa dhamaan xogta imtixaanada
 * Endpoint: DELETE /api/exam/reset
 */
router.delete('/reset', examController.resetAllRecords); // ✅ Safkan ayaa u dambeeyey ee lagu daray

module.exports = router;