const pool = require('../config/db'); // Hubi in kani yahay db connection-gaaga

const ReportModel = {
    // Wuxuu toos xogta uga soo akhrisanayaa jadwalka 'students' ee PostgreSQL
    getStudentsForReport: async (className) => {
        const query = `
            SELECT 
                id, 
                name, 
                phone, 
                district, 
                neighbor, 
                class_name, 
                created_at 
            FROM students 
            WHERE class_name = $1 
            ORDER BY name ASC;
        `;
        const { rows } = await pool.query(query, [className]);
        return rows;
    }
};

// Hubi in loo dhoofiyey qaab Object ah si la mid ah StudentModel-kaaga kale
module.exports = ReportModel;