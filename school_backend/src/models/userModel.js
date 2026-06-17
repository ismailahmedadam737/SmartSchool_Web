const pool = require('../config/db');

const UserModel = {

  // GET ALL USERS
  getAll: async () => {
    return await pool.query('SELECT * FROM users ORDER BY id DESC');
  },

  // GET BY ID
  getById: async (id) => {
    return await pool.query(
      'SELECT * FROM users WHERE id = $1',
      [id]
    );
  },

  // CREATE USER
  create: async (username, password, role) => {
    return await pool.query(
      'INSERT INTO users (username, password, role) VALUES ($1, $2, $3) RETURNING *',
      [username, password, role]
    );
  },

  // UPDATE USER
  update: async (id, username, password, role) => {
    return await pool.query(
      'UPDATE users SET username=$1, password=$2, role=$3 WHERE id=$4 RETURNING *',
      [username, password, role, id]
    );
  },

  // DELETE USER
  delete: async (id) => {
    return await pool.query(
      'DELETE FROM users WHERE id=$1',
      [id]
    );
  },

  // LOGIN
  login: async (username, password) => {
    return await pool.query(
      'SELECT * FROM users WHERE username=$1 AND password=$2',
      [username, password]
    );
  }
};

module.exports = UserModel;