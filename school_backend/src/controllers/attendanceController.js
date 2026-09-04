const AttendanceModel = require('../models/Attendance');

const getTenantId = (req) => {
    const tid = req.tenantId || req.headers['x-tenant-id'] || req.query.tenant_id || req.body.tenant_id;
    return tid ? parseInt(tid, 10) : null;
};

// Xareynta Liiska Attendance-ka
exports.submitAttendance = async (req, res) => {
  try {
    const { students, class_name, month, date } = req.body;
    const tenantId = getTenantId(req);

    // Waxaan isticmaalaynaa Map si aan u fulino dhamaan INSERT/UPDATE isku mar
    const promises = students.map(student => {
      return AttendanceModel.saveAttendance({
        student_name: student.name,
        class_name: class_name,
        status: student.isPresent ? 'Present' : 'Absent',
        remarks: student.remarks || '',
        month: month,
        date: date
      }, tenantId);
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
    const tenantId = getTenantId(req);
    const report = await AttendanceModel.getAttendanceByDate(class_name, date, tenantId);
    res.status(200).json(report);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Soo qaadista Warbixinta Bisha (30 Days)
exports.getSummary = async (req, res) => {
  try {
    const { class_name, month } = req.query;
    const tenantId = getTenantId(req);
    const summary = await AttendanceModel.getMonthlySummary(class_name, month, tenantId);
    res.status(200).json(summary);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};