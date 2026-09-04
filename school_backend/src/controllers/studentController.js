const StudentModel = require('../models/studentModel');

// Helper to extract tenantId from request
const getTenantId = (req) => {
    const tid = req.tenantId || req.headers['x-tenant-id'] || req.query.tenant_id || req.body.tenant_id;
    return tid ? parseInt(tid, 10) : null;
};

// 1. Diiwaangelinta Ardayga
exports.createStudent = async (req, res) => {
    try {
        const tenantId = getTenantId(req);
        const newStudent = await StudentModel.registerStudent(req.body, tenantId);
        res.status(201).json({
            message: "Student registered successfully!",
            student: newStudent
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// 2. Soo saarista Dhamaan Ardayda
exports.getStudents = async (req, res) => {
    try {
        const tenantId = getTenantId(req);
        const students = await StudentModel.getAllStudents(tenantId);
        res.status(200).json(students);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// 3. Tirtirista Ardayga
exports.deleteStudent = async (req, res) => {
    try {
        const { id } = req.params;
        const tenantId = getTenantId(req);
        const result = await StudentModel.deleteStudentById(id, tenantId); 
        if (result) {
            res.status(200).json({ message: "Student deleted successfully!" });
        } else {
            res.status(404).json({ message: "Student not found!" });
        }
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// 4. Soo saarista Fasallada (UNIQUE CLASSES)
exports.getClasses = async (req, res) => {
    try {
        const tenantId = getTenantId(req);
        const students = await StudentModel.getAllStudents(tenantId);
        const classes = [...new Set(students.map(s => s.class_name || s.className).filter(Boolean))];
        const classList = classes.map(c => ({ class_name: c }));
        res.status(200).json(classList);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// 5. Cusboonaysiinta Ardayga
exports.updateStudent = async (req, res) => {
    try {
        const id = req.params.id || req.body.id || req.body._id;
        const tenantId = getTenantId(req);
        if (!id) {
            return res.status(400).json({ error: "Student ID waa loo baahan yahay" });
        }
        const updatedStudent = await StudentModel.updateStudent(id, req.body, tenantId);
        if (updatedStudent) {
            res.status(200).json({
                message: "Student updated successfully!",
                student: updatedStudent
            });
        } else {
            res.status(404).json({ message: "Student not found!" });
        }
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};