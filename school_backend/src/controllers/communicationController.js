const Communication = require('../models/communicationModel');

exports.sendSchoolMessage = async (req, res) => {
  try {
    const { name, phone, subject, message } = req.body;

    // 1. Hubi in dhammaan meelaha muhiimka ah la soo buuxiyey
    if (!name || !phone || !subject || !message) {
      return res.status(400).json({ error: "Fadlan buuxi dhammaan meelaha banaan" });
    }

    // 2. U gudbi xogta nidaamka Model-ka si loogu kaydiyo Database-ka
    const newMessage = await Communication.addMessage({ name, phone, subject, message });

    // 3. Soo celi jawaab guul ah haddii ay si sax ah u kaydsanto
    res.status(200).json({ 
      message: "Fariintaada si guul leh ayaa loo kaydiyay", 
      data: newMessage 
    });
    
  } catch (err) {
    console.error("COMMUNICATION CONTROLLER ERROR:", err);
    res.status(500).json({ error: err.message });
  }
};