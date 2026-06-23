const express = require('express');
const router = express.Router();
const { loginUser, getAllUsers, createUser, updateUser, deleteUser } = require('../controllers/userController');

router.post('/login', loginUser);
router.get('/', getAllUsers);
router.post('/', createUser);
router.put('/:id', updateUser);
router.delete('/:id', deleteUser);

module.exports = router;