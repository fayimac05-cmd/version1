const supabase = require('../config/supabase');

const CanalModel = {
  async findAll(filters = {}) {
    let query = supabase.from('canaux').select('*').order('created_at', { ascending: true });

    if (filters.etablissement_id) {
      query = query.eq('etablissement_id', filters.etablissement_id);
    }
    if (filters.type) {
      query = query.eq('type', filters.type);
    }
    if (filters.filiere) {
      query = query.or(`filiere.is.null,filiere.eq.${filters.filiere}`);
    }

    const { data, error } = await query;
    if (error) throw error;
    return data;
  },

  async findById(id) {
    const { data, error } = await supabase.from('canaux').select('*').eq('id', id).single();
    if (error) throw error;
    return data;
  },

  async create(canalData) {
    const { data, error } = await supabase.from('canaux').insert([canalData]).select().single();
    if (error) throw error;
    return data;
  },
};

module.exports = CanalModel;
