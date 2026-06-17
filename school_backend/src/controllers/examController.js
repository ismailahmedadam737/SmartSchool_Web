const Examination = require('../models/examinationModel');

// 1. Save results
exports.saveExamination = async (req, res) => {
  const { student_id, student_name, grades } = req.body;
  try {
    for (let item of grades) {
      await Examination.saveGrades(
        student_id,
        student_name,
        item.subject,
        item.score,
        item.exam_type
      );
    }
    res.status(200).json({ message: "Natiijada waa la kaydiyey!" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// 2. Get student results
exports.getResults = async (req, res) => {
  try {
    const results = await Examination.getByStudentId(req.params.studentId);
    res.status(200).json(results);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ✅ 3. Reset all records
exports.resetAllRecords = async (req, res) => {
  try {
    console.log("Codsiga tirtirista (Reset) ayaa soo gaadhay server-ka...");
    
    await Examination.deleteAllRecords();
    
    res.status(200).json({ 
      success: true, 
      message: "Dhammaan xogta imtixaanada si guul leh ayaa looga saaray database-ka." 
    });
  } catch (err) {
    console.error("❌ Cilad Controller:", err.message);
    res.status(500).json({ 
      success: false, 
      error: "Ma suurtagalin in xogta la tirtiro." 
    });
  }
};