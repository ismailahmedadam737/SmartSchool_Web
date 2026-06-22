const Communication = require('../models/communicationModel');

// Fariin cusub dirista
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

// Soo akhrinta dhammaan fariimaha
exports.getAllMessages = async (req, res) => {
  try {
    const messages = await Communication.fetchAll();
    res.status(200).json(messages);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
};

// Tirtirida fariin gaar ah (Kani waa qaybtii aan kusoo kordhiyay)
exports.deleteMessage = async (req, res) => {
  try {
    const { id } = req.params;
    
    // Waxaan u malaynayaa in Model-kaagu leeyahay function la yiraahdo deleteById
    // Haddii uusan lahayn, fadlan hubi in Model-kaagu uu awood u leeyahay inuu fariin tirtiro
    const result = await Communication.deleteById(id);
    
    if (!result) {
      return res.status(404).json({ error: "Fariintan lama helin ama horey ayaa loo tirtiray" });
    }
    
    res.status(200).json({ message: "Fariintii si joogto ah ayaa loo tirtiray." });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
};