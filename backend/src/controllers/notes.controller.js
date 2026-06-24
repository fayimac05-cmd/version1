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
            JOIN etudiants e ON n.etudiant_id = e.id
            WHERE e.user_id = $1
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

const createGradeSession = async (req, res) => {
    try {
        const { filiere_id, filiere_nom, niveau, module_id, notes } = req.body;
        const professeur_id = req.user.id;

        if (!filiere_id || !module_id) {
            return res.status(400).json({ success: false, message: 'filiere_id et module_id sont requis.' });
        }
        
        const sessionResult = await pool.query(`
            INSERT INTO sessions_notes (filiere_id, filiere_nom, niveau, module_id, professeur_id) 
            VALUES ($1, $2, $3, $4, $5) RETURNING id
        `, [filiere_id, filiere_nom || '', niveau || 'Tous', module_id, professeur_id]);
        
        const session_id = sessionResult.rows[0].id;
        const skippedStudents = [];
        
        if (notes && notes.length > 0) {
            for (const note of notes) {
                if (!note.matricule || note.valeur === undefined || note.valeur === null) {
                    skippedStudents.push({ matricule: note.matricule || 'inconnu', reason: 'matricule ou valeur manquant' });
                    continue;
                }
                const etudiantResult = await pool.query(`SELECT id FROM etudiants WHERE matricule = $1`, [note.matricule]);
                if (etudiantResult.rows.length > 0) {
                    const e_id = etudiantResult.rows[0].id;
                    await pool.query(`
                        INSERT INTO notes (etudiant_id, module_id, valeur) 
                        VALUES ($1, $2, $3)
                    `, [e_id, module_id, note.valeur]);
                } else {
                    skippedStudents.push({ matricule: note.matricule, reason: 'étudiant introuvable' });
                }
            }
        }
        
        const response = { success: true, message: 'Session de notes créée avec succès', session_id };
        if (skippedStudents.length > 0) {
            response.warnings = skippedStudents;
            response.message = `Session créée avec ${skippedStudents.length} note(s) non enregistrée(s).`;
        }
        res.status(201).json(response);
    } catch (error) {
        console.error('[createGradeSession]', error);
        res.status(500).json({ success: false, message: 'Erreur lors de la création de la session de notes.' });
    }
};

const getGradeSessions = async (req, res) => {
    try {
        const professeur_id = req.user.id;
        const result = await pool.query(`
            SELECT sn.*, m.nom as module_nom 
            FROM sessions_notes sn
            JOIN modules m ON sn.module_id = m.id
            WHERE sn.professeur_id = $1
            ORDER BY sn.date_session DESC
        `, [professeur_id]);
        
        res.json({ success: true, data: result.rows });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

const markSessionSent = async (req, res) => {
    try {
        const { session_id } = req.params;
        const professeur_id = req.user.id;
        
        await pool.query(`
            UPDATE sessions_notes SET is_sent = true 
            WHERE id = $1 AND professeur_id = $2
        `, [session_id, professeur_id]);
        
        res.json({ success: true, message: 'Session marquée comme envoyée' });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

module.exports = {
    generateBulletinPdf,
    createGradeSession,
    getGradeSessions,
    markSessionSent
};
