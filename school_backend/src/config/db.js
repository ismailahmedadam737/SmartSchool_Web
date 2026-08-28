const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL, // Halkan ayaad ku beddeshay
  ssl: {
    rejectUnauthorized: false // Neon DB waxay u baahan tahay tan
  }
});

pool.on('connect', () => {
  console.log('✅ PostgreSQL connected successfully!');
});

module.exports = pool;