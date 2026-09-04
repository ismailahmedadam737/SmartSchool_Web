const pool = require('../config/db');

const StudentModel = {
  // In la keydiyo arday cusub (tenant-scoped)
  registerStudent: async (studentData, tenantId) => {
    await pool.query(`
        CREATE TABLE IF NOT EXISTS students (
            id SERIAL PRIMARY KEY,
            name VARCHAR(255),
            phone VARCHAR(255),
            district VARCHAR(255),
            neighbor VARCHAR(255),
            class_name VARCHAR(255),
            tenant_id INT REFERENCES tenants(id) ON DELETE CASCADE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    `).catch(() => {});
    // Add tenant_id column if old table exists without it
    await pool.query(`ALTER TABLE students ADD COLUMN IF NOT EXISTS tenant_id INT REFERENCES tenants(id) ON DELETE CASCADE`).catch(() => {});
    await pool.query(`CREATE INDEX IF NOT EXISTS idx_students_tenant_id ON students(tenant_id)`).catch(() => {});

    const { name, phone, district, neighbor, class_name } = studentData;
    const values = [name, phone, district, neighbor, class_name || studentData.class, tenantId || null];
    let rows;
    try {
        const res = await pool.query(
            `INSERT INTO students (name, phone, district, neighbor, class_name, tenant_id)
             VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
            values
        );
        rows = res.rows;
    } catch (err) {
        if (err.code === '23502' || err.code === '23505' || (err.message && (err.message.includes('null value in column "id"') || err.message.includes('violates unique constraint')))) {
            const maxRes = await pool.query('SELECT COALESCE(MAX(id), 0) + 1 AS next_id FROM students');
            const nextId = maxRes.rows[0].next_id;
            const res = await pool.query(
                `INSERT INTO students (id, name, phone, district, neighbor, class_name, tenant_id)
                 VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
                [nextId, name, phone, district, neighbor, class_name || studentData.class, tenantId || null]
            );
            rows = res.rows;
        } else {
            throw err;
        }
    }
    return rows[0];
  },

  // In la soo saaro ardayda iskuulka gaar ah kaliya (tenant-scoped)
  getAllStudents: async (tenantId) => {
    await pool.query(`ALTER TABLE students ADD COLUMN IF NOT EXISTS tenant_id INT REFERENCES tenants(id) ON DELETE CASCADE`).catch(() => {});
    
    if (tenantId) {
      // Return only THIS school's students
      const { rows } = await pool.query(
        'SELECT * FROM students WHERE tenant_id = $1 ORDER BY id DESC',
        [tenantId]
      );
      return rows;
    }
    // Fallback: return all (for legacy/demo mode only)
    const { rows } = await pool.query('SELECT * FROM students ORDER BY id DESC');
    return rows;
  },

  // Tirtirista Ardayga (tenant-safe)
  deleteStudentById: async (id, tenantId) => {
    let result;
    if (tenantId) {
      result = await pool.query(
        'DELETE FROM students WHERE id = $1 AND tenant_id = $2',
        [id, tenantId]
      );
    } else {
      result = await pool.query('DELETE FROM students WHERE id = $1', [id]);
    }
    return result.rowCount > 0;
  },

  // Cusboonaysiinta xogta ardayga (tenant-safe)
  updateStudent: async (id, studentData, tenantId) => {
    const { name, phone, district, neighbor, class_name } = studentData;
    const studentId = parseInt(id, 10) || id;
    let query, values;
    if (tenantId) {
      query = `UPDATE students SET name=$1, phone=$2, district=$3, neighbor=$4, class_name=$5
               WHERE id=$6 AND tenant_id=$7 RETURNING *`;
      values = [name, phone, district, neighbor, class_name || studentData.class, studentId, tenantId];
    } else {
      query = `UPDATE students SET name=$1, phone=$2, district=$3, neighbor=$4, class_name=$5
               WHERE id=$6 RETURNING *`;
      values = [name, phone, district, neighbor, class_name || studentData.class, studentId];
    }
    const { rows } = await pool.query(query, values);
    return rows[0];
  }
};

module.exports = StudentModel;