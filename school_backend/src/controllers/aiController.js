require('dotenv').config();
const { GoogleGenerativeAI } = require("@google/generative-ai");
const pool = require('../config/db');

exports.handleAiQuery = async (req, res) => {
  const { question } = req.body;

  try {
    // 1. Soo ururi xogta laga helayo dhammaan qaybaha dugsiga
    const [students, teachers, buses, exams] = await Promise.all([
      pool.query('SELECT COUNT(*) FROM students'),
      pool.query('SELECT COUNT(*) FROM teachers'),
      pool.query('SELECT COUNT(*) FROM buses'),
      pool.query('SELECT COUNT(*) FROM examinations')
    ]);

    // 2. Diyaari Context-ka (Xogta AI-ga u baahan yahay)
    const context = `
      Waxaad tahay kaaliyaha dugsiga Iftiinshe. U jawaab mar walba af-Soomaali.
      Halkan waa xogta dhabta ah ee dugsiga:
      - Tirada ardayda: ${students.rows[0].count}
      - Tirada macalimiinta: ${teachers.rows[0].count}
      - Tirada basaska: ${buses.rows[0].count}
      - Tirada imtixaanada la galay: ${exams.rows[0].count}
      
      Isticmaal xogtan si aad uga jawaabto su'aalaha isticmaalaha.
    `;

    // 3. U dir Gemini
    const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

    const fullPrompt = `${context}\n\nSu'aasha Isticmaalaha: ${question}`;
    
    const result = await model.generateContent(fullPrompt);
    const response = await result.response;
    
    res.json({ success: true, answer: response.text() });
    
  } catch (error) {
    console.error("❌ Cillad dhacday:", error.message);
    res.status(500).json({ 
        success: false, 
        message: "Cillad farsamo oo ku timid xog-ururinta AI-ga.",
        details: error.message 
    });
  }
};