// src/controllers/teacherController.js

/**
 * FIIRO GAAR AH: Maadaama file-kaaga models-ka dhexdiisa ku jira magaciisu yahay 'Teacher.js',
 * waa inaan halkan ku qornaa 'Teacher' iyadoo 'T' ay weyn tahay.
 */
const Teacher = require('../models/Teacher'); 

// 1. Soo aqri dhamaan macalimiinta (GET)
exports.getTeachers = async (req, res) => {
    try {
        const teachers = await Teacher.findAll();
        res.status(200).json(teachers);
    } catch (error) {
        res.status(500).json({ error: "Khalad ayaa ka dhacay soo aqrinta: " + error.message });
    }
};

// 2. Kaydi Macalin cusub (POST)
exports.addTeacher = async (req, res) => {
    try {
        // req.body wuxuu ka imaanayaa Flutter: { name, district, phone, level, exp }
        const newTeacher = await Teacher.create(req.body);
        res.status(201).json(newTeacher);
    } catch (error) {
        res.status(500).json({ error: "Kaydintu ma guulaysan: " + error.message });
    }
};

// 3. Cusboonaysii Macalin (PUT)
exports.updateTeacher = async (req, res) => {
    try {
        const { id } = req.params;
        const updatedTeacher = await Teacher.update(id, req.body);

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
        const result = await Teacher.delete(id);
        res.status(200).json(result);
    } catch (error) {
        res.status(500).json({ error: "Tirtiristu ma guulaysan: " + error.message });
    }
};