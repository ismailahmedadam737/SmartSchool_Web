const Teacher = require('../models/Teacher'); 

const getTenantId = (req) => {
    const tid = req.tenantId || req.headers['x-tenant-id'] || req.query.tenant_id || req.body.tenant_id;
    return tid ? parseInt(tid, 10) : null;
};

// 1. Soo aqri dhamaan macalimiinta (GET)
exports.getTeachers = async (req, res) => {
    try {
        const tenantId = getTenantId(req);
        const teachers = await Teacher.findAll(tenantId);
        res.status(200).json(teachers);
    } catch (error) {
        res.status(500).json({ error: "Khalad ayaa ka dhacay soo aqrinta: " + error.message });
    }
};

// 2. Kaydi Macalin cusub (POST)
exports.addTeacher = async (req, res) => {
    try {
        const tenantId = getTenantId(req);
        const newTeacher = await Teacher.create(req.body, tenantId);
        res.status(201).json(newTeacher);
    } catch (error) {
        res.status(500).json({ error: "Kaydintu ma guulaysan: " + error.message });
    }
};

// 3. Cusboonaysii Macalin (PUT)
exports.updateTeacher = async (req, res) => {
    try {
        const { id } = req.params;
        const tenantId = getTenantId(req);
        const updatedTeacher = await Teacher.update(id, req.body, tenantId);

        if (!updatedTeacher) {
            return res.status(404).json({ message: "Macalinka lama helin" });
        }

        res.status(200).json({ 
            message: "Si guul leh ayaa loo cusboonaysiiyey",
            data: updatedTeacher 
        });
    } catch (error) {
        res.status(500).json({ error: "Wax ka bedelku ma guulaysan: " + error.message });
    }
};

// 4. Tirtir Macalin (DELETE)
exports.deleteTeacher = async (req, res) => {
    try {
        const { id } = req.params;
        const tenantId = getTenantId(req);
        const result = await Teacher.delete(id, tenantId);
        res.status(200).json(result);
    } catch (error) {
        res.status(500).json({ error: "Tirtiristu ma guulaysan: " + error.message });
    }
};