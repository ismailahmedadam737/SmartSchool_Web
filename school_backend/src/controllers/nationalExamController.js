const pool = require('../config/db');

// Ensure database table exists
async function ensureNationalExamsTable() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS national_exams (
        id SERIAL PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        subject VARCHAR(100) NOT NULL,
        year INT NOT NULL,
        pdf_url TEXT NOT NULL,
        created_at TIMESTAMPTZ DEFAULT NOW()
      );
    `);

    // Add unique constraint safely if missing
    await pool.query(`
      DO $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM pg_constraint WHERE conname = 'unique_subject_year'
        ) THEN
          ALTER TABLE national_exams ADD CONSTRAINT unique_subject_year UNIQUE (subject, year);
        END IF;
      END $$;
    `).catch(() => {});

    console.log('✅ Table "national_exams" is ready.');
  } catch (err) {
    console.error('❌ Error creating national_exams table:', err.message);
  }
}

// Call on startup
ensureNationalExamsTable();

// 1. Get all exams or filter by subject
exports.getExams = async (req, res) => {
  try {
    const { subject, year } = req.query;
    let query = 'SELECT * FROM national_exams';
    let params = [];

    if (subject && year) {
      query += ' WHERE LOWER(TRIM(subject)) = LOWER(TRIM($1)) AND year = $2 ORDER BY year DESC';
      params = [subject, parseInt(year, 10)];
    } else if (subject) {
      query += ' WHERE LOWER(TRIM(subject)) = LOWER(TRIM($1)) ORDER BY year DESC';
      params = [subject];
    } else {
      query += ' ORDER BY year DESC, subject ASC';
    }

    const result = await pool.query(query, params);
    res.status(200).json(result.rows);
  } catch (err) {
    console.error('Error fetching national exams:', err.message);
    res.status(500).json({ error: 'Ma suurtagalin in la soo saaro imtixaanada: ' + err.message });
  }
};

// 2. Upload / Save exam (Safe Upsert)
exports.uploadExam = async (req, res) => {
  try {
    const { title, subject, year, pdf_url } = req.body;

    if (!subject || !year || !pdf_url) {
      return res.status(400).json({ error: 'Subject, year, iyo pdf_url waa khasab.' });
    }

    const examTitle = title || `Somaliland Grade 8 Exam ${year} - ${subject}`;
    const parsedYear = parseInt(year, 10);

    // 1. Try UPDATE first
    const updateRes = await pool.query(
      `UPDATE national_exams 
       SET title = $1, pdf_url = $2, created_at = NOW() 
       WHERE LOWER(TRIM(subject)) = LOWER(TRIM($3)) AND year = $4 
       RETURNING *`,
      [examTitle, pdf_url, subject, parsedYear]
    );

    if (updateRes.rows.length > 0) {
      return res.status(200).json({
        message: 'Imtixaanka si guul leh ayaa loo cusboonaysiiyay!',
        data: updateRes.rows[0],
      });
    }

    // 2. Otherwise INSERT
    const insertRes = await pool.query(
      `INSERT INTO national_exams (title, subject, year, pdf_url, created_at)
       VALUES ($1, $2, $3, $4, NOW())
       RETURNING *`,
      [examTitle, subject, parsedYear, pdf_url]
    );

    res.status(201).json({
      message: 'Imtixaanka si guul leh ayaa loo kaydiyay!',
      data: insertRes.rows[0],
    });
  } catch (err) {
    console.error('Error uploading national exam:', err.message);
    res.status(500).json({ error: 'Ma suurtagalin in la saaro imtixaanka: ' + err.message });
  }
};

// 3. Delete exam by ID
exports.deleteExam = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('DELETE FROM national_exams WHERE id = $1 RETURNING *', [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Imtixaanka la doortay ma jiro.' });
    }

    res.status(200).json({
      message: 'Imtixaanka si guul leh ayaa loo tirtiray.',
      data: result.rows[0],
    });
  } catch (err) {
    console.error('Error deleting national exam:', err.message);
    res.status(500).json({ error: 'Ma suurtagalin in la tirtiro imtixaanka: ' + err.message });
  }
};
