const pool = require('../config/db');

const StudentModel = {
  // In la keydiyo arday cusub
  registerStudent: async (studentData) => {
    await pool.query(`
        CREATE TABLE IF NOT EXISTS students (
            id SERIAL PRIMARY KEY,
            name VARCHAR(255),
            phone VARCHAR(255),
            district VARCHAR(255),
            neighbor VARCHAR(255),
            class_name VARCHAR(255),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    `).catch(() => {});
    const { name, phone, district, neighbor, class_name } = studentData;
    const values = [name, phone, district, neighbor, class_name || studentData.class];
    let rows;
    try {
        const res = await pool.query(
            `INSERT INTO students (name, phone, district, neighbor, class_name)
             VALUES ($1, $2, $3, $4, $5) RETURNING *`,
            values
        );
        rows = res.rows;
    } catch (err) {
        if (err.code === '23502' || err.code === '23505' || (err.message && (err.message.includes('null value in column "id"') || err.message.includes('violates unique constraint')))) {
            const maxRes = await pool.query('SELECT COALESCE(MAX(id), 0) + 1 AS next_id FROM students');
            const nextId = maxRes.rows[0].next_id;
            const res = await pool.query(
                `INSERT INTO students (id, name, phone, district, neighbor, class_name)
                 VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
                [nextId, name, phone, district, neighbor, class_name || studentData.class]
            );
            rows = res.rows;
        } else {
            throw err;
        }
    }
    return rows[0];
  },

  // In la soo saaro dhammaan ardayda
  getAllStudents: async () => {
    await pool.query(`
        CREATE TABLE IF NOT EXISTS students (
            id SERIAL PRIMARY KEY,
            name VARCHAR(255),
            phone VARCHAR(255),
            district VARCHAR(255),
            neighbor VARCHAR(255),
            class_name VARCHAR(255),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    `).catch(() => {});
    const { rows } = await pool.query('SELECT * FROM students ORDER BY id DESC');
    return rows;
  },

  // KAN KU DAR SI TIRTIRISTU U SHAQEEYSO (PostgreSQL)
  deleteStudentById: async (id) => {
    const query = 'DELETE FROM students WHERE id = $1';
    const result = await pool.query(query, [id]);
    // rowCount wuxuu sheegayaa inta xariiq (rows) oo la tirtiray
    return result.rowCount > 0;
  },

  // 4. Cusboonaysiinta xogta ardayga
  updateStudent: async (id, studentData) => {
    const { name, phone, district, neighbor, class_name } = studentData;
    const studentId = parseInt(id, 10) || id;
    const query = `
      UPDATE students 
      SET name = $1, phone = $2, district = $3, neighbor = $4, class_name = $5
      WHERE id = $6 RETURNING *`;
    const values = [name, phone, district, neighbor, class_name || studentData.class, studentId];
    const { rows } = await pool.query(query, values);
    return rows[0];
  }
};

module.exports = StudentModel;