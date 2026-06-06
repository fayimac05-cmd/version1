const PDFDocument = require('pdfkit');
const pool = require('../config/db');

const generateBulletinPdf = async (req, res) => {
    try {
        const etudiantId = req.params.etudiantId;

        // Fetch student details
        const studentQuery = `SELECT nom, prenoms, matricule FROM users WHERE id = $1 AND role = 'etudiant'`;
        const studentResult = await pool.query(studentQuery, [etudiantId]);
        
        if (studentResult.rows.length === 0) {
            return res.status(404).json({ error: "Étudiant non trouvé." });
        }
        
        const etudiant = studentResult.rows[0];

        // Fetch notes
        const notesQuery = `
            SELECT m.nom AS matiere, m.coefficient, n.valeur AS note
            FROM notes n
            JOIN modules m ON n.module_id = m.id
            WHERE n.etudiant_id = $1
        `;
        
        const notesResult = await pool.query(notesQuery, [etudiantId]);
        const notes = notesResult.rows;

        // Create PDF
        const doc = new PDFDocument({ margin: 50 });

        res.setHeader('Content-Type', 'application/pdf');
        res.setHeader('Content-Disposition', `attachment; filename=bulletin_${etudiant.matricule}.pdf`);

        doc.pipe(res);

        // Header
        doc.fontSize(20).text('ScolarHub - Bulletin de Notes', { align: 'center' });
        doc.moveDown();
        
        doc.fontSize(14).text(`Étudiant: ${etudiant.prenoms} ${etudiant.nom}`);
        doc.text(`Matricule: ${etudiant.matricule}`);
        doc.moveDown(2);

        // Table headers
        doc.fontSize(12).font('Helvetica-Bold');
        doc.text('Matière', 50, doc.y);
        doc.text('Coef', 300, doc.y - doc.currentLineHeight());
        doc.text('Note', 400, doc.y - doc.currentLineHeight());
        
        let currentY = doc.y + 5;
        doc.moveTo(50, currentY).lineTo(450, currentY).stroke();
        currentY += 15;

        doc.font('Helvetica');
        let sumNotes = 0;
        let sumCoefs = 0;

        for (const row of notes) {
            let noteVal = parseFloat(row.note);
            let coefVal = parseFloat(row.coefficient);
            if (isNaN(noteVal)) noteVal = 0;
            if (isNaN(coefVal)) coefVal = 1;

            sumNotes += noteVal * coefVal;
            sumCoefs += coefVal;

            doc.text(row.matiere, 50, currentY, { width: 240 });
            doc.text(coefVal.toString(), 300, currentY);
            doc.text(noteVal.toFixed(2) + ' / 20', 400, currentY);
            
            currentY += 25;
        }

        currentY += 10;
        doc.moveTo(50, currentY).lineTo(450, currentY).stroke();
        currentY += 20;

        let moyenneGenerale = sumCoefs > 0 ? (sumNotes / sumCoefs) : 0;
        
        let mention = "Passable";
        if (moyenneGenerale >= 16) mention = "Très Bien";
        else if (moyenneGenerale >= 14) mention = "Bien";
        else if (moyenneGenerale >= 12) mention = "Assez Bien";
        else if (moyenneGenerale < 10) mention = "Insuffisant";

        doc.font('Helvetica-Bold').fontSize(14);
        doc.text(`Moyenne Générale : ${moyenneGenerale.toFixed(2)} / 20`, 50, currentY);
        currentY += 20;
        doc.text(`Mention : ${mention}`, 50, currentY);

        doc.end();

    } catch (error) {
        console.error('Erreur génération PDF:', error);
        if (!res.headersSent) {
            res.status(500).json({ error: 'Erreur interne du serveur lors de la génération du bulletin.' });
        }
    }
};

module.exports = {
    generateBulletinPdf
};
