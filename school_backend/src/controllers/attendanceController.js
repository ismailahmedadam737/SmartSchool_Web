const AttendanceModel = require('../models/Attendance');

// Xareynta Liiska Attendance-ka
exports.submitAttendance = async (req, res) => {
  try {
    const { students, class_name, month, date } = req.body;

    // Waxaan isticmaalaynaa Map si aan u fulino dhamaan INSERT/UPDATE isku mar
    const promises = students.map(student => {
      return AttendanceModel.saveAttendance({
        student_name: student.name,
        class_name: class_name,
        status: student.isPresent ? 'Present' : 'Absent',
        remarks: student.remarks || '',
        month: month,
        date: date
      });
    });

    await Promise.all(promises);
    res.status(201).json({ message: "Attendance processed successfully!" });
  } catch (error) {
    console.error("Submission Error:", error);
    res.status(500).json({ error: error.message });
  }
};

// Soo qaadista History-ga Maalinta
exports.getDailyReport = async (req, res) => {
  try {
    const { class_name, date } = req.query;
    const report = await AttendanceModel.getAttendanceByDate(class_name, date);
    res.status(200).json(report);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Soo qaadista Warbixinta Bisha (30 Days)
exports.getSummary = async (req, res) => {
  try {
    const { class_name, month } = req.query;
    const summary = await AttendanceModel.getMonthlySummary(class_name, month);
    res.status(200).json(summary);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};