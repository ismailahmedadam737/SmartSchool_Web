const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Transaction = sequelize.define('Transaction', {
  amount: { type: DataTypes.DECIMAL(12, 2), allowNull: false },
  type: { type: DataTypes.ENUM('income', 'expense'), allowNull: false },
  description: { type: DataTypes.STRING, allowNull: true }
});

module.exports = Transaction;