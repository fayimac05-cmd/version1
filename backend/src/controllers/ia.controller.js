// backend/src/controllers/ia.controller.js

const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY
);

// POST /api/ia/chat - Envoyer un message à Claude
const chat = async (req, res) => {
  try {
    const { message } = req.body;
    const userId = req.user.id;

    // Récupérer les N derniers échanges pour le contexte
    const { data: historique } = await supabase
      .from('ia_conversations')
      .select('role, contenu')
      .eq('user_id', userId)
      .order('created_at', { ascending: true })
      .limit(10);

    // Construire l'historique des messages
    const messages = historique
      ? historique.map((h) => ({ role: h.role, content: h.contenu }))
      : [];

    // Ajouter le nouveau message
    messages.push({ role: 'user', content: message });

    // Appel API Claude
    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': process.env.ANTHROPIC_API_KEY,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: 'claude-sonnet-4-20250514',
        max_tokens: 1024,
        system: `Tu es un assistant IA intégré dans ScholARHub, 
                 une plateforme scolaire. Tu aides les étudiants, 
                 professeurs et parents avec leurs questions.`,
        messages: messages,
      }),
    });

    const data = await response.json();
    const reponseIA = data.content[0].text;

    // Sauvegarder l'échange en base
    await supabase.from('ia_conversations').insert([
      { user_id: userId, role: 'user', contenu: message },
      { user_id: userId, role: 'assistant', contenu: reponseIA },
    ]);

    res.json({ success: true, reponse: reponseIA });
  } catch (error) {
    console.error('Erreur chat IA:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/ia/historique - Récupérer l'historique
const getHistorique = async (req, res) => {
  try {
    const userId = req.user.id;
    const limit = parseInt(req.query.limit) || 20;

    const { data, error } = await supabase
      .from('ia_conversations')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .limit(limit);

    if (error) throw error;

    res.json({ success: true, historique: data.reverse() });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = { chat, getHistorique };