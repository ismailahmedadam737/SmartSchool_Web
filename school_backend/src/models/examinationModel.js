const pool = require('../config/db');
const { ensureTenantColumn } = require('../utils/tenantIsolation');

class Examination {
  // 1. Kaydi ama Update-garee natiijada (tenant-scoped)
  static async saveGrades(studentId, studentName, subject, score, examType, tenantId) {
    await ensureTenantColumn('examination').catch(() => {});
    let query, values;
    if (tenantId) {
      query = `
        INSERT INTO examination (student_id, student_name, subject, score, exam_type, tenant_id)
        VALUES ($1, $2, $3, $4, $5, $6)
        ON CONFLICT (student_id, subject, exam_type) 
        DO UPDATE SET score = EXCLUDED.score, tenant_id = EXCLUDED.tenant_id;
      `;
      values = [studentId, studentName, subject, score, examType, tenantId];
    } else {
      query = `
        INSERT INTO examination (student_id, student_name, subject, score, exam_type)
        VALUES ($1, $2, $3, $4, $5)
        ON CONFLICT (student_id, subject, exam_type) 
        DO UPDATE SET score = EXCLUDED.score;
      `;
      values = [studentId, studentName, subject, score, examType];
    }
    return await pool.query(query, values);
  }

  // 2. Soo saar natiijooyinka arday gaar ah (tenant-scoped)
  static async getByStudentId(studentId, tenantId) {
    await ensureTenantColumn('examination').catch(() => {});
    let query, values;
    if (tenantId) {
      query = `SELECT * FROM examination WHERE student_id = $1 AND tenant_id = $2 ORDER BY id ASC;`;
      values = [studentId, tenantId];
    } else {
      query = `SELECT * FROM examination WHERE student_id = $1 ORDER BY id ASC;`;
      values = [studentId];
    }
    const result = await pool.query(query, values);
    return result.rows;
  }

  // ✅ 3. Tirtir dhamaan xogta (Yearly Reset - tenant-scoped)
  static async deleteAllRecords(tenantId) {
    try {
      let query, values;
      if (tenantId) {
        query = `DELETE FROM examination WHERE tenant_id = $1;`;
        values = [tenantId];
      } else {
        query = `DELETE FROM examination;`;
        values = [];
      }
      const result = await pool.query(query, values);
      console.log(`✅ Xogta waa la tirtiray. Safafda la tirtiray: ${result.rowCount}`);
      return true;
    } catch (error) {
      console.error("❌ Cilad SQL Model:", error.message);
      throw error;
    }
  }
}

module.exports = Examination;