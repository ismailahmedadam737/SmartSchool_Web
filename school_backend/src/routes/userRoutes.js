const express = require('express');
const router = express.Router();

const {
  getAllUsers,
  getUserById,
  createUser,
  updateUser,
  deleteUser,
  loginUser
} = require('../controllers/userController');

// 📌 LOGIN USER
router.post('/login', loginUser);

// 📌 GET ALL USERS
router.get('/', getAllUsers);

// 📌 GET USER BY ID
router.get('/:id', getUserById);

// 📌 CREATE USER
router.post('/', createUser);

// 📌 UPDATE USER
router.put('/:id', updateUser);

// 📌 DELETE USER
router.delete('/:id', deleteUser);

module.exports = router;