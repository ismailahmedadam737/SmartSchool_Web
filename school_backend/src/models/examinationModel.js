const pool = require('../config/db');

class Examination {
  // 1. Kaydi ama Update-garee natiijada
  static async saveGrades(studentId, studentName, subject, score, examType) {
    const query = `
      INSERT INTO examination (student_id, student_name, subject, score, exam_type)
      VALUES ($1, $2, $3, $4, $5)
      ON CONFLICT (student_id, subject, exam_type) 
      DO UPDATE SET score = EXCLUDED.score;
    `;
    const values = [studentId, studentName, subject, score, examType];
    return await pool.query(query, values);
  }

  // 2. Soo saar natiijooyinka arday gaar ah
  static async getByStudentId(studentId) {
    const query = `SELECT * FROM examination WHERE student_id = $1 ORDER BY id ASC;`;
    const result = await pool.query(query, [studentId]);
    return result.rows;
  }

  // ✅ 3. Tirtir dhamaan xogta (Yearly Reset)
  static async deleteAllRecords() {
    try {
      // Amarkan wuxuu tirtirayaa dhamaan safafda table-ka 'examination'
      const query = `DELETE FROM examination;`; 
      const result = await pool.query(query);
      console.log(`✅ Xogta waa la tirtiray. Safafda la tirtiray: ${result.rowCount}`);
      return true;
    } catch (error) {
      console.error("❌ Cilad SQL Model:", error.message);
      throw error;
    }
  }
}

module.exports = Examination;