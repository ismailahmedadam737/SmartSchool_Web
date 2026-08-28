const Bus = require('../models/Bus');

// Soo kici dhammaan
exports.getAllBuses = async (req, res) => {
    try {
        const buses = await Bus.getAll();
        res.status(200).json(buses);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// Diwaangeli baska
exports.registerBus = async (req, res) => {
    try {
        const newBus = await Bus.create(req.body);
        res.status(201).json(newBus);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// Wax ka beddel baska
exports.updateBus = async (req, res) => {
    try {
        const updatedBus = await Bus.update(req.params.id, req.body);
        if (!updatedBus) return res.status(404).json({ message: "Bus not found" });
        res.status(200).json(updatedBus);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// Tirtir baska
exports.deleteBus = async (req, res) => {
    try {
        await Bus.delete(req.params.id);
        res.status(200).json({ message: "Baska si guul leh ayaa loo tirtiray" });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};