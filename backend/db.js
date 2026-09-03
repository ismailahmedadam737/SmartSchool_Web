// backend/db.js
// Central PostgreSQL connection pool used by all services.
// Adjust connection parameters to match your environment (host, port, user, password, database).

const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.PGHOST || 'localhost',
  port: process.env.PGPORT ? parseInt(process.env.PGPORT) : 5432,
  user: process.env.PGUSER || 'postgres',
  password: process.env.PGPASSWORD || 'your_password',
  database: process.env.PGDATABASE || 'iftiinshe_master', // master DB that holds tenant metadata
  max: 20, // max connections in pool
  idleTimeoutMillis: 30000,
});

module.exports = {
  query: (text, params) => pool.query(text, params),
  getClient: () => pool.connect(), // for transactions
};
