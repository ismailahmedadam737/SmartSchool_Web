const User = require('../models/userModel');

const loginUser = async (req, res) => {
  try {
    const { username, password } = req.body;
    const result = await User.login(username, password);

    if (result.rows.length === 0) {
      return res.status(401).json({ message: "Invalid login" });
    }

    // Waxaan u soo celinaynaa user-ka iyo role-kiisa
    res.json({
      message: "Login success",
      user: result.rows[0] 
    });
  } catch (err) {
    res.status(500).json({ message: "Server error" });
  }
};

// Inta kale ee controller-ka (getAllUsers, createUser, iwm.)
module.exports = { loginUser, getAllUsers: async (req, res) => { /*...*/ }, createUser: async (req, res) => { /*...*/ }, updateUser: async (req, res) => { /*...*/ }, deleteUser: async (req, res) => { /*...*/ } };