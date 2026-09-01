const pool = require('../config/db');

// In-memory fallback if DB table is not yet created or error occurs
let memoryMenu = [
  {
    id: 'menu-1',
    nom: 'Riz gras au poulet',
    description: 'Riz parfumé garni de morceaux de poulet braisé et légumes frais',
    prix: 500,
    categorie: 'Plat principal',
    disponible: true,
    emoji: '🍽️',
    date_menu: new Date().toISOString().split('T')[0],
  },
  {
    id: 'menu-2',
    nom: 'Poisson braisé avec alloco',
    description: 'Capitaine frais grillé au feu de bois accompagné d’alloco croustillant',
    prix: 800,
    categorie: 'Plat principal',
    disponible: true,
    emoji: '🐟',
    date_menu: new Date().toISOString().split('T')[0],
  },
  {
    id: 'menu-3',
    nom: 'Yassa Poulet',
    description: 'Poulet mariné aux oignons caramélisés et jus de citron',
    prix: 700,
    categorie: 'Plat principal',
    disponible: true,
    emoji: '🍗',
    date_menu: new Date().toISOString().split('T')[0],
  },
  {
    id: 'menu-4',
    nom: 'Croissant au beurre',
    description: 'Viennoiserie artisanale croustillante pur beurre',
    prix: 200,
    categorie: 'Petit déjeuner',
    disponible: true,
    emoji: '🥐',
    date_menu: new Date().toISOString().split('T')[0],
  },
  {
    id: 'menu-5',
    nom: 'Pain au chocolat',
    description: 'Feuilleté au chocolat noir fondant',
    prix: 250,
    categorie: 'Petit déjeuner',
    disponible: true,
    emoji: '🍫',
    date_menu: new Date().toISOString().split('T')[0],
  },
  {
    id: 'menu-6',
    nom: 'Café au lait',
    description: 'Café robusta chaud au lait concentré',
    prix: 150,
    categorie: 'Boisson',
    disponible: true,
    emoji: '☕',
    date_menu: new Date().toISOString().split('T')[0],
  },
  {
    id: 'menu-7',
    nom: 'Jus de Bissap (50cl)',
    description: 'Boisson artisanale rafraîchissante aux fleurs d’hibiscus',
    prix: 250,
    categorie: 'Boisson',
    disponible: true,
    emoji: '🍹',
    date_menu: new Date().toISOString().split('T')[0],
  },
  {
    id: 'menu-8',
    nom: 'Salade composée',
    description: 'Salade verte, tomates, concombres, maïs et œufs durs',
    prix: 300,
    categorie: 'Entrée',
    disponible: true,
    emoji: '🥗',
    date_menu: new Date().toISOString().split('T')[0],
  },
  {
    id: 'menu-9',
    nom: 'Délices Yaourt Mangue',
    description: 'Yaourt crémeux fait maison à la pulpe de mangue',
    prix: 300,
    categorie: 'Dessert',
    disponible: true,
    emoji: '🍦',
    date_menu: new Date().toISOString().split('T')[0],
  },
];

let memoryCommandes = [
  {
    id: 'cmd-101',
    etudiant_id: 'etud-1',
    etudiant_nom: 'KABORÉ Yacouba',
    etudiant_matricule: '24IST-0145',
    montant_total: 1050,
    statut: 'prete',
    code_retrait: 'CAN-4821',
    created_at: new Date(Date.now() - 25 * 60000).toISOString(),
    items: [
      { id: 'item-1', nom_plat: 'Riz gras au poulet', prix_unitaire: 500, quantite: 1 },
      { id: 'item-2', nom_plat: 'Jus de Bissap (50cl)', prix_unitaire: 250, quantite: 1 },
      { id: 'item-3', nom_plat: 'Délices Yaourt Mangue', prix_unitaire: 300, quantite: 1 },
    ],
  },
  {
    id: 'cmd-102',
    etudiant_id: 'etud-2',
    etudiant_nom: 'ZONGO Aminata',
    etudiant_matricule: '24IST-0892',
    montant_total: 800,
    statut: 'en_preparation',
    code_retrait: 'CAN-8912',
    created_at: new Date(Date.now() - 10 * 60000).toISOString(),
    items: [
      { id: 'item-4', nom_plat: 'Poisson braisé avec alloco', prix_unitaire: 800, quantite: 1 },
    ],
  },
];

// Helper to generate withdrawal code
function generateCodeRetrait() {
  const num = Math.floor(1000 + Math.random() * 9000);
  return `CAN-${num}`;
}

// ── GET /api/cantine/menu
exports.getMenu = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT * FROM cantine_menu ORDER BY categorie ASC, nom ASC`
    );
    return res.json({ success: true, data: result.rows });
  } catch (err) {
    console.log('[Cantine DB Fallback] Using memory menu:', err.message);
    return res.json({ success: true, data: memoryMenu });
  }
};

// ── POST /api/cantine/menu (Cantinière / Admin)
exports.addPlat = async (req, res) => {
  const { nom, description, prix, categorie, emoji, disponible } = req.body;
  if (!nom || !prix) {
    return res.status(400).json({ success: false, message: 'Nom et prix sont requis.' });
  }

  try {
    const result = await pool.query(
      `INSERT INTO cantine_menu (nom, description, prix, categorie, emoji, disponible)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [
        nom,
        description || '',
        parseFloat(prix),
        categorie || 'Plat principal',
        emoji || '🍽️',
        disponible !== undefined ? disponible : true,
      ]
    );
    return res.status(201).json({ success: true, data: result.rows[0], message: 'Plat ajouté avec succès au menu.' });
  } catch (err) {
    console.log('[Cantine DB Fallback] Adding plat to memory menu:', err.message);
    const newPlat = {
      id: 'menu-' + Date.now(),
      nom,
      description: description || '',
      prix: parseFloat(prix),
      categorie: categorie || 'Plat principal',
      emoji: emoji || '🍽️',
      disponible: disponible !== undefined ? disponible : true,
      date_menu: new Date().toISOString().split('T')[0],
    };
    memoryMenu.unshift(newPlat);
    return res.status(201).json({ success: true, data: newPlat, message: 'Plat ajouté au menu.' });
  }
};

// ── PUT /api/cantine/menu/:id (Cantinière / Admin)
exports.updatePlat = async (req, res) => {
  const { id } = req.params;
  const { nom, description, prix, categorie, emoji, disponible } = req.body;

  try {
    const result = await pool.query(
      `UPDATE cantine_menu
       SET nom = COALESCE($1, nom),
           description = COALESCE($2, description),
           prix = COALESCE($3, prix),
           categorie = COALESCE($4, categorie),
           emoji = COALESCE($5, emoji),
           disponible = COALESCE($6, disponible)
       WHERE id = $7
       RETURNING *`,
      [nom, description, prix ? parseFloat(prix) : null, categorie, emoji, disponible, id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Plat non trouvé.' });
    }
    return res.json({ success: true, data: result.rows[0], message: 'Plat mis à jour.' });
  } catch (err) {
    console.log('[Cantine DB Fallback] Updating plat in memory menu:', err.message);
    const idx = memoryMenu.findIndex((item) => item.id === id);
    if (idx === -1) {
      return res.status(404).json({ success: false, message: 'Plat non trouvé.' });
    }
    if (nom) memoryMenu[idx].nom = nom;
    if (description !== undefined) memoryMenu[idx].description = description;
    if (prix) memoryMenu[idx].prix = parseFloat(prix);
    if (categorie) memoryMenu[idx].categorie = categorie;
    if (emoji) memoryMenu[idx].emoji = emoji;
    if (disponible !== undefined) memoryMenu[idx].disponible = disponible;

    return res.json({ success: true, data: memoryMenu[idx], message: 'Plat mis à jour.' });
  }
};

// ── DELETE /api/cantine/menu/:id (Cantinière / Admin)
exports.deletePlat = async (req, res) => {
  const { id } = req.params;
  try {
    await pool.query(`DELETE FROM cantine_menu WHERE id = $1`, [id]);
    return res.json({ success: true, message: 'Plat supprimé du menu.' });
  } catch (err) {
    console.log('[Cantine DB Fallback] Deleting plat from memory:', err.message);
    memoryMenu = memoryMenu.filter((item) => item.id !== id);
    return res.json({ success: true, message: 'Plat supprimé du menu.' });
  }
};

// ── POST /api/cantine/commandes (Étudiant passe commande)
exports.creerCommande = async (req, res) => {
  const { etudiant_id, etudiant_nom, etudiant_matricule, items, montant_total } = req.body;

  if (!items || !Array.isArray(items) || items.length === 0) {
    return res.status(400).json({ success: false, message: 'Le panier ne peut pas être vide.' });
  }

  const codeRetrait = generateCodeRetrait();
  const total = montant_total || items.reduce((sum, item) => sum + (item.prix_unitaire * item.quantite), 0);

  const isUuid = (str) => typeof str === 'string' && /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/.test(str);
  const validUuid = isUuid(etudiant_id) ? etudiant_id : null;

  try {
    const resCmd = await pool.query(
      `INSERT INTO cantine_commandes (etudiant_id, etudiant_nom, etudiant_matricule, montant_total, statut, code_retrait)
       VALUES ($1, $2, $3, $4, 'en_attente', $5)
       RETURNING *`,
      [validUuid, etudiant_nom || 'Étudiant', etudiant_matricule || 'N/A', total, codeRetrait]
    );
    const commande = resCmd.rows[0];

    const insertedItems = [];
    for (const item of items) {
      const resItem = await pool.query(
        `INSERT INTO cantine_commande_items (commande_id, menu_id, nom_plat, prix_unitaire, quantite)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING *`,
        [commande.id, item.menu_id || null, item.nom_plat, item.prix_unitaire, item.quantite || 1]
      );
      insertedItems.push(resItem.rows[0]);
    }
    commande.items = insertedItems;

    // Ajouter à la mémoire pour synchroniser
    memoryCommandes.unshift(commande);

    return res.status(201).json({ success: true, data: commande, message: 'Commande enregistrée avec succès !' });
  } catch (err) {
    console.log('[Cantine DB Fallback] Creating commande in memory:', err.message);
    const newCmd = {
      id: 'cmd-' + Date.now(),
      etudiant_id: etudiant_id || 'etud-current',
      etudiant_nom: etudiant_nom || 'Étudiant Connecté',
      etudiant_matricule: etudiant_matricule || '24IST-DEMO',
      montant_total: total,
      statut: 'en_attente',
      code_retrait: codeRetrait,
      created_at: new Date().toISOString(),
      items: items.map((it, idx) => ({
        id: 'item-' + Date.now() + '-' + idx,
        nom_plat: it.nom_plat,
        prix_unitaire: it.prix_unitaire,
        quantite: it.quantite || 1,
      })),
    };
    memoryCommandes.unshift(newCmd);
    return res.status(201).json({ success: true, data: newCmd, message: 'Commande enregistrée avec succès !' });
  }
};

// ── GET /api/cantine/commandes/mes-commandes (Historique étudiant)
exports.getMesCommandes = async (req, res) => {
  const { etudiant_id, matricule } = req.query;
  const isUuid = (str) => typeof str === 'string' && /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/.test(str);
  const validUuid = isUuid(etudiant_id) ? etudiant_id : null;
  const mat = matricule || (etudiant_id && !validUuid ? etudiant_id : '');

  try {
    const result = await pool.query(
      `SELECT c.*,
              COALESCE(
                json_agg(
                  json_build_object(
                    'id', i.id,
                    'nom_plat', i.nom_plat,
                    'prix_unitaire', i.prix_unitaire,
                    'quantite', i.quantite
                  )
                ) FILTER (WHERE i.id IS NOT NULL), '[]'
              ) AS items
       FROM cantine_commandes c
       LEFT JOIN cantine_commande_items i ON i.commande_id = c.id
       WHERE ($1::uuid IS NOT NULL AND c.etudiant_id = $1::uuid)
          OR (c.etudiant_matricule = $2 AND $2 != '')
       GROUP BY c.id
       ORDER BY c.created_at DESC`,
      [validUuid, mat]
    );
    return res.json({ success: true, data: result.rows });
  } catch (err) {
    console.log('[Cantine DB Fallback] Getting mes commandes from memory:', err.message);
    const filtered = memoryCommandes.filter(
      (c) =>
        (validUuid && c.etudiant_id === validUuid) ||
        (mat && c.etudiant_matricule === mat) ||
        (etudiant_id && c.etudiant_id === etudiant_id) ||
        true
    );
    return res.json({ success: true, data: filtered });
  }
};

// ── GET /api/cantine/commandes (Cantinière / Admin)
exports.getAllCommandes = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT c.*,
              COALESCE(
                json_agg(
                  json_build_object(
                    'id', i.id,
                    'nom_plat', i.nom_plat,
                    'prix_unitaire', i.prix_unitaire,
                    'quantite', i.quantite
                  )
                ) FILTER (WHERE i.id IS NOT NULL), '[]'
              ) AS items
       FROM cantine_commandes c
       LEFT JOIN cantine_commande_items i ON i.commande_id = c.id
       GROUP BY c.id
       ORDER BY c.created_at DESC`
    );
    return res.json({ success: true, data: result.rows });
  } catch (err) {
    console.log('[Cantine DB Fallback] Getting all commandes from memory:', err.message);
    return res.json({ success: true, data: memoryCommandes });
  }
};

// ── PATCH /api/cantine/commandes/:id/statut (Cantinière / Admin)
exports.updateStatutCommande = async (req, res) => {
  const { id } = req.params;
  const { statut } = req.body;

  const validStatuts = ['en_attente', 'en_preparation', 'prete', 'servie', 'annulee'];
  if (!statut || !validStatuts.includes(statut)) {
    return res.status(400).json({ success: false, message: 'Statut invalide.' });
  }

  try {
    const result = await pool.query(
      `UPDATE cantine_commandes
       SET statut = $1
       WHERE id = $2
       RETURNING *`,
      [statut, id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Commande non trouvée.' });
    }
    return res.json({ success: true, data: result.rows[0], message: `Commande mise à jour (${statut}).` });
  } catch (err) {
    console.log('[Cantine DB Fallback] Updating commande statut in memory:', err.message);
    const idx = memoryCommandes.findIndex((c) => c.id === id);
    if (idx === -1) {
      return res.status(404).json({ success: false, message: 'Commande non trouvée.' });
    }
    memoryCommandes[idx].statut = statut;
    return res.json({ success: true, data: memoryCommandes[idx], message: `Commande mise à jour (${statut}).` });
  }
};
