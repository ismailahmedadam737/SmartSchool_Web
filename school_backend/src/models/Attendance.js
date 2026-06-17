const pool = require('../config/db');

class AttendanceModel {
  // 1. Kaydinta ama Cusboonaysiinta (Save or Update)
  // Habkani wuxuu hubiyaa inaan ardayga laba jeer maalin qudh ah la xaadirin
  static async saveAttendance(data) {
    const { student_name, class_name, status, remarks, month, date } = data;
    
    const query = `
      INSERT INTO attendance (student_name, class_name, status, remarks, month_name, attendance_date)
      VALUES ($1, $2, $3, $4, $5, $6)
      ON CONFLICT (student_name, class_name, attendance_date) 
      DO UPDATE SET 
        status = EXCLUDED.status, 
        remarks = EXCLUDED.remarks;
    `;
    
    const values = [student_name, class_name, status, remarks, month, date];
    await pool.query(query, values);
  }

  // 2. Soo saarista xogta maalin gaar ah (History/Check)
  static async getAttendanceByDate(className, date) {
    const query = `
      SELECT student_name, status, remarks 
      FROM attendance 
      WHERE class_name = $1 AND attendance_date = $2;
    `;
    const { rows } = await pool.query(query, [className, date]);
    return rows;
  }

  // 3. Xisaabinta guud ee bisha (30-ka maalmood)
  static async getMonthlySummary(className, month) {
    const query = `
      SELECT 
        student_name,
        COUNT(*) FILTER (WHERE status = 'Present') as present_days,
        COUNT(*) FILTER (WHERE status = 'Absent') as absent_days,
        ARRAY_AGG(attendance_date || ': ' || remarks) FILTER (WHERE remarks IS NOT NULL AND remarks <> '') as history_remarks
      FROM attendance
      WHERE class_name = $1 AND month_name = $2
      GROUP BY student_name;
    `;
    const { rows } = await pool.query(query, [className, month]);
    return rows;
  }
}

module.exports = AttendanceModel;