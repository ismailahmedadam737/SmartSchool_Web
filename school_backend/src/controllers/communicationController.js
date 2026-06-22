const Communication = require('../models/communicationModel');

// 1. Dirista fariin cusub
exports.sendSchoolMessage = async (req, res) => {
  try {
    const { name, phone, subject, message } = req.body;

    // Hubi in dhammaan xogta muhiimka ah ay jirto
    if (!name || !phone || !subject || !message) {
      return res.status(400).json({ error: "Fadlan buuxi dhammaan meelaha banaan" });
    }

    // U gudbi Model-ka si loogu kaydiyo Database-ka
    const newMessage = await Communication.addMessage({ name, phone, subject, message });

    res.status(200).json({ 
      message: "Fariintaada si guul leh ayaa loo kaydiyay", 
      data: newMessage 
    });
    
  } catch (err) {
    console.error("COMMUNICATION CONTROLLER ERROR (POST):", err);
    res.status(500).json({ error: "Khalad ayaa ka dhacay dirista fariinta" });
  }
};

// 2. Soo aqrinta dhammaan fariimaha
exports.getAllMessages = async (req, res) => {
  try {
    const messages = await Communication.fetchAll();
    res.status(200).json(messages);
  } catch (err) {
    console.error("COMMUNICATION CONTROLLER ERROR (GET):", err);
    res.status(500).json({ error: "Khalad ayaa ka dhacay soo helida fariimaha" });
  }
};

// 3. Tirtiridda fariin (Haddii admin-ku doono inuu masaxo fariin gaar ah)
exports.deleteMessage = async (req, res) => {
  try {
    const { id } = req.params;
    await Communication.deleteMessage(id);
    res.status(200).json({ message: "Fariintii waa la tirtiray" });
  } catch (err) {
    console.error("COMMUNICATION CONTROLLER ERROR (DELETE):", err);
    res.status(500).json({ error: "Fariinta lama tirtiri karin" });
  }
};