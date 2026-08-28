const ReportModel = require('../models/report_model');

exports.generateLiveReport = async (req, res) => {
    try {
        const { class_name } = req.query;

        // Hubi in fasalka la soo doortay ka hor intaan query-ga la huriyeen
        if (!class_name) {
            return res.status(400).json({ 
                success: false, 
                message: "Fadlan soo bixi magaca fasalka (class_name)" 
            });
        }

        // Toos ugu dhex akhri database-ka maraya miiska 'students'
        const studentsList = await ReportModel.getStudentsForReport(class_name);

        // U celi Flutter-ka qaab habaysan oo nadiif ah
        return res.status(200).json({
            success: true,
            class_name: class_name,
            generated_at: new Date(),
            total_students: studentsList.length,
            data: studentsList 
        });

    } catch (error) {
        console.error("❌ Report Generation Error:", error);
        return res.status(500).json({ 
            success: false, 
            message: "Cillad farsamo ayaa ka dhacday server-ka", 
            error: error.message 
        });
    }
};