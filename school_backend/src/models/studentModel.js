const pool = require('../config/db');

const StudentModel = {
  // In la keydiyo arday cusub
  registerStudent: async (studentData) => {
    const { name, phone, district, neighbor, class_name } = studentData;
    const query = `
      INSERT INTO students (name, phone, district, neighbor, class_name)
      VALUES ($1, $2, $3, $4, $5) RETURNING *`;
    const values = [name, phone, district, neighbor, class_name];
    const { rows } = await pool.query(query, values);
    return rows[0];
  },

  // In la soo saaro dhammaan ardayda
  getAllStudents: async () => {
    const { rows } = await pool.query('SELECT * FROM students ORDER BY created_at DESC');
    return rows;
  },

  // KAN KU DAR SI TIRTIRISTU U SHAQEEYSO (PostgreSQL)
  deleteStudentById: async (id) => {
    const query = 'DELETE FROM students WHERE id = $1';
    const result = await pool.query(query, [id]);
    // rowCount wuxuu sheegayaa inta xariiq (rows) oo la tirtiray
    return result.rowCount > 0;
  }
};

module.exports = StudentModel;