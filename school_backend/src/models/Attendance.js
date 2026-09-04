const pool = require('../config/db');
const { ensureTenantColumn } = require('../utils/tenantIsolation');

class AttendanceModel {
  // 1. Kaydinta ama Cusboonaysiinta (Save or Update) (tenant-scoped)
  static async saveAttendance(data, tenantId) {
    await ensureTenantColumn('attendance').catch(() => {});
    const { student_name, class_name, status, remarks, month, date } = data;
    
    let query, values;
    if (tenantId) {
      query = `
        INSERT INTO attendance (student_name, class_name, status, remarks, month_name, attendance_date, tenant_id)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        ON CONFLICT (student_name, class_name, attendance_date) 
        DO UPDATE SET 
          status = EXCLUDED.status, 
          remarks = EXCLUDED.remarks,
          tenant_id = EXCLUDED.tenant_id;
      `;
      values = [student_name, class_name, status, remarks, month, date, tenantId];
    } else {
      query = `
        INSERT INTO attendance (student_name, class_name, status, remarks, month_name, attendance_date)
        VALUES ($1, $2, $3, $4, $5, $6)
        ON CONFLICT (student_name, class_name, attendance_date) 
        DO UPDATE SET 
          status = EXCLUDED.status, 
          remarks = EXCLUDED.remarks;
      `;
      values = [student_name, class_name, status, remarks, month, date];
    }
    
    await pool.query(query, values);
  }

  // 2. Soo saarista xogta maalin gaar ah (History/Check) (tenant-scoped)
  static async getAttendanceByDate(className, date, tenantId) {
    await ensureTenantColumn('attendance').catch(() => {});
    let query, values;
    if (tenantId) {
      query = `
        SELECT student_name, status, remarks 
        FROM attendance 
        WHERE class_name = $1 AND attendance_date = $2 AND tenant_id = $3;
      `;
      values = [className, date, tenantId];
    } else {
      query = `
        SELECT student_name, status, remarks 
        FROM attendance 
        WHERE class_name = $1 AND attendance_date = $2;
      `;
      values = [className, date];
    }
    const { rows } = await pool.query(query, values);
    return rows;
  }

  // 3. Xisaabinta guud ee bisha (30-ka maalmood) (tenant-scoped)
  static async getMonthlySummary(className, month, tenantId) {
    await ensureTenantColumn('attendance').catch(() => {});
    let query, values;
    if (tenantId) {
      query = `
        SELECT 
          student_name,
          COUNT(*) FILTER (WHERE status = 'Present') as present_days,
          COUNT(*) FILTER (WHERE status = 'Absent') as absent_days,
          ARRAY_AGG(attendance_date || ': ' || remarks) FILTER (WHERE remarks IS NOT NULL AND remarks <> '') as history_remarks
        FROM attendance
        WHERE class_name = $1 AND month_name = $2 AND tenant_id = $3
        GROUP BY student_name;
      `;
      values = [className, month, tenantId];
    } else {
      query = `
        SELECT 
          student_name,
          COUNT(*) FILTER (WHERE status = 'Present') as present_days,
          COUNT(*) FILTER (WHERE status = 'Absent') as absent_days,
          ARRAY_AGG(attendance_date || ': ' || remarks) FILTER (WHERE remarks IS NOT NULL AND remarks <> '') as history_remarks
        FROM attendance
        WHERE class_name = $1 AND month_name = $2
        GROUP BY student_name;
      `;
      values = [className, month];
    }
    const { rows } = await pool.query(query, values);
    return rows;
  }
}

module.exports = AttendanceModel;