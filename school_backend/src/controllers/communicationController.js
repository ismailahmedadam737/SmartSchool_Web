const Communication = require('../models/communicationModel');

// 1. Dirista fariin cusub
exports.sendSchoolMessage = async (req, res) => {
  try {
    const { name, phone, subject, message } = req.body;
    if (!name || !phone || !subject || !message) {
      return res.status(400).json({ error: "Fadlan buuxi dhammaan meelaha banaan" });
    }

    // Fariinta waxaa lagu keydinayaa is_read: false (default ahaan)
    const newMessage = await Communication.addMessage({ name, phone, subject, message });

    res.status(200).json({ 
      message: "Fariintaada si guul leh ayaa loo kaydiyay", 
      data: newMessage 
    });
  } catch (err) {
    console.error("ERROR SENDING MESSAGE:", err);
    res.status(500).json({ error: err.message });
  }
};

// 2. Soo aqrinta dhammaan fariimaha (Admin-ka)
exports.getAllMessages = async (req, res) => {
  try {
    const messages = await Communication.findAllMessages();
    res.status(200).json(messages);
  } catch (err) {
    console.error("ERROR FETCHING MESSAGES:", err);
    res.status(500).json({ error: err.message });
  }
};

// 3. Calaamadee fariin in la aqriyay
exports.markAsRead = async (req, res) => {
  try {
    const { id } = req.params;
    await Communication.updateReadStatus(id, true);
    res.status(200).json({ message: "Fariintan waa la aqriyay" });
  } catch (err) {
    console.error("ERROR MARKING AS READ:", err);
    res.status(500).json({ error: err.message });
  }
};

// 4. Calaamadee dhammaan fariimaha in la aqriyay (marka Admin-ku furo bogga)
exports.markAllAsRead = async (req, res) => {
  try {
    await Communication.updateAllReadStatus(true);
    res.status(200).json({ message: "Dhammaan fariimaha waa la aqriyay" });
  } catch (err) {
    console.error("ERROR MARKING ALL AS READ:", err);
    res.status(500).json({ error: err.message });
  }
};