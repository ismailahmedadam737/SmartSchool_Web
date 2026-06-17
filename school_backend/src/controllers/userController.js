const User = require('../models/userModel');

// 📌 GET ALL USERS
const getAllUsers = async (req, res) => {
  try {
    const result = await User.getAll();
    res.json(result.rows);
  } catch (err) {
    console.log(err);
    res.status(500).json({ message: "Server error" });
  }
};

// 📌 GET USER BY ID
const getUserById = async (req, res) => {
  try {
    const result = await User.getById(req.params.id);
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ message: "Server error" });
  }
};

// 📌 CREATE USER
const createUser = async (req, res) => {
  try {
    const { username, password, role } = req.body;

    const result = await User.create(username, password, role);

    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.log(err);
    res.status(500).json({ message: "Server error" });
  }
};

// 📌 UPDATE USER
const updateUser = async (req, res) => {
  try {
    const { username, password, role } = req.body;

    const result = await User.update(
      req.params.id,
      username,
      password,
      role
    );

    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ message: "Server error" });
  }
};

// 📌 DELETE USER
const deleteUser = async (req, res) => {
  try {
    await User.delete(req.params.id);
    res.json({ message: "User deleted successfully" });
  } catch (err) {
    res.status(500).json({ message: "Server error" });
  }
};

// 📌 LOGIN USER
const loginUser = async (req, res) => {
  try {
    const { username, password } = req.body;

    const result = await User.login(username, password);

    if (result.rows.length === 0) {
      return res.status(401).json({ message: "Invalid login" });
    }

    res.json({
      message: "Login success",
      user: result.rows[0]
    });

  } catch (err) {
    console.log(err);
    res.status(500).json({ message: "Server error" });
  }
};

module.exports = {
  getAllUsers,
  getUserById,
  createUser,
  updateUser,
  deleteUser,
  loginUser
};