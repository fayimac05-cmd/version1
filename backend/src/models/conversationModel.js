const supabase = require('../config/supabase');

const ConversationModel = {
  async findByUser(etudiantId) {
    const { data, error } = await supabase
      .from('conversations')
      .select('*')
      .eq('etudiant_id', etudiantId)
      .order('updated_at', { ascending: false });

    if (error) throw error;
    return data;
  },

  async findAllForAdmin() {
    const { data, error } = await supabase
      .from('conversations')
      .select('*')
      .order('updated_at', { ascending: false });

    if (error) throw error;
    return data;
  },

  async findById(id) {
    const { data, error } = await supabase.from('conversations').select('*').eq('id', id).single();
    if (error) throw error;
    return data;
  },

  async findOrCreatePriveAdmin(etudiantId, sujet) {
    const { data: existing } = await supabase
      .from('conversations')
      .select('*')
      .eq('etudiant_id', etudiantId)
      .eq('type', 'prive_admin')
      .eq('statut', 'ouvert')
      .maybeSingle();

    if (existing) return existing;

    const { data, error } = await supabase
      .from('conversations')
      .insert([{
        type: 'prive_admin',
        etudiant_id: etudiantId,
        sujet: sujet || 'Contact administration',
        statut: 'ouvert',
      }])
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async touch(id) {
    const { data, error } = await supabase
      .from('conversations')
      .update({ updated_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data;
  },
};

module.exports = ConversationModel;
