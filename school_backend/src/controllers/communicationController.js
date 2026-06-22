const Communication = require('../models/communicationModel');

exports.sendSchoolMessage = async (req, res) => {
  try {
    const { name, phone, subject, message } = req.body;
    if (!name || !phone || !subject || !message) {
      return res.status(400).json({ error: "Fadlan buuxi dhammaan meelaha banaan" });
    }
    const newMessage = await Communication.addMessage({ name, phone, subject, message });
    res.status(200).json({ message: "Fariintaada si guul leh ayaa loo kaydiyay", data: newMessage });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
};

// HUBI IN KANI U QORAN YAHAY SIDAN:
exports.getAllMessages = async (req, res) => {
  try {
    const messages = await Communication.fetchAll();
    res.status(200).json(messages);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
};