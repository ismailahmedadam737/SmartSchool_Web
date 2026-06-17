const StudentModel = require('../models/studentModel');

// 1. Diiwaangelinta Ardayga
exports.createStudent = async (req, res) => {
    try {
        const newStudent = await StudentModel.registerStudent(req.body);
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
        const students = await StudentModel.getAllStudents();
        res.status(200).json(students);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// 3. Tirtirista Ardayga
exports.deleteStudent = async (req, res) => {
    try {
        const { id } = req.params;
        const result = await StudentModel.deleteStudentById(id); 
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
        const students = await StudentModel.getAllStudents();
        // Waxay ka dhex saaraysaa fasallada unique-ka ah
        const classes = [...new Set(students.map(s => s.class_name || s.className))];
        const classList = classes.map(c => ({ class_name: c }));
        res.status(200).json(classList);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};