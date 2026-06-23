const pool = require('../config/db');

const UserModel = {
  // LOGIN
  login: async (username, password) => {
    return await pool.query(
      'SELECT id, username, role FROM users WHERE username=$1 AND password=$2',
      [username, password]
    );
  },
  // Waxyaabaha kale ee model-ka...
  getAll: async () => await pool.query('SELECT * FROM users'),
  create: async (username, password, role) => await pool.query(
    'INSERT INTO users (username, password, role) VALUES ($1, $2, $3) RETURNING *',
    [username, password, role]
  ),
  update: async (id, username, password, role) => await pool.query(
    'UPDATE users SET username=$1, password=$2, role=$3 WHERE id=$4 RETURNING *',
    [username, password, role, id]
  ),
  delete: async (id) => await pool.query('DELETE FROM users WHERE id=$1', [id])
};

module.exports = UserModel;