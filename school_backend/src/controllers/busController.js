const Bus = require('../models/Bus');

const getTenantId = (req) => {
    const tid = req.tenantId || req.headers['x-tenant-id'] || req.query.tenant_id || req.body.tenant_id;
    return tid ? parseInt(tid, 10) : null;
};

// Soo kici dhammaan
exports.getAllBuses = async (req, res) => {
    try {
        const tenantId = getTenantId(req);
        const buses = await Bus.getAll(tenantId);
        res.status(200).json(buses);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// Diwaangeli baska
exports.registerBus = async (req, res) => {
    try {
        const tenantId = getTenantId(req);
        const newBus = await Bus.create(req.body, tenantId);
        res.status(201).json(newBus);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// Wax ka beddel baska
exports.updateBus = async (req, res) => {
    try {
        const tenantId = getTenantId(req);
        const updatedBus = await Bus.update(req.params.id, req.body, tenantId);
        if (!updatedBus) return res.status(404).json({ message: "Bus not found" });
        res.status(200).json(updatedBus);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// Tirtir baska
exports.deleteBus = async (req, res) => {
    try {
        const tenantId = getTenantId(req);
        await Bus.delete(req.params.id, tenantId);
        res.status(200).json({ message: "Baska si guul leh ayaa loo tirtiray" });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};