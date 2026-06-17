const express = require('express');
const router = express.Router();
const { OpenAI } = require('openai');
const pool = require('../config/db'); 
require('dotenv').config();

const client = new OpenAI({
  apiKey: process.env.GROQ_API_KEY, 
  baseURL: 'https://api.groq.com/openai/v1',
});

router.post('/query', async (req, res) => {
  const prompt = req.body.prompt || req.body.question;

  if (!prompt) {
    return res.status(400).json({ success: false, message: "Fadlan soo dir su'aal!" });
  }

  try {
    // 1. Soo ururi xogta dhamaan qaybaha dugsiga (Aggregation)
    const [students, teachers, buses, exams] = await Promise.all([
      pool.query('SELECT COUNT(*) FROM students'),
      pool.query('SELECT COUNT(*) FROM teachers'),
      pool.query('SELECT COUNT(*) FROM buses'),
      pool.query('SELECT COUNT(*) FROM examination')
    ]);
    
    // 2. Diyaari "Context" dhamaystiran
    const statsContext = `
      Macluumaadka hadda ee Dugsiga Iftiinshe:
      - Tirada ardayda diiwaangashan: ${students.rows[0].count}
      - Tirada macalimiinta: ${teachers.rows[0].count}
      - Tirada basaska: ${buses.rows[0].count}
      - Tirada diiwaanka imtixaanada: ${exams.rows[0].count}
    `;

    // 3. U dir xogtaan AI-ga
    const completion = await client.chat.completions.create({
      messages: [
        { 
          role: 'system', 
          content: `Waxaad tahay kaaliyaha dugsiga Iftiinshe. Halkan waa xogta dhabta ah ee database-ka: ${statsContext}. 
          U jawaab mar walba af-Soomaali. Haddii su'aasha isticmaalaha ay la xiriirto tirakoobka dugsiga, isticmaal xogtan. Haddii kale, uga jawaab si caadi ah.` 
        },
        { role: 'user', content: prompt }
      ],
      model: 'llama-3.3-70b-versatile',
    });

    res.json({
      success: true,
      data: completion.choices[0].message.content 
    });

  } catch (error) {
    console.error("❌ Groq API Error:", error);
    res.status(500).json({ 
      success: false, 
      message: "AI-ga wuu shaqayn waayay", 
      error: error.message 
    });
  }
});

module.exports = router;