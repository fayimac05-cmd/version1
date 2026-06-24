const supabase = require('../config/supabase');

const MessageModel = {
  async findByCanal(canalId, { limit = 50, offset = 0 } = {}) {
    const { data, error } = await supabase
      .from('messages')
      .select('*')
      .eq('canal_id', canalId)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) throw error;
    return (data || []).reverse();
  },

  async findByConversation(conversationId, { limit = 50, offset = 0 } = {}) {
    const { data, error } = await supabase
      .from('messages')
      .select('*')
      .eq('conversation_id', conversationId)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) throw error;
    return (data || []).reverse();
  },

  async create(messageData) {
    const { data, error } = await supabase.from('messages').insert([messageData]).select().single();
    if (error) throw error;
    return data;
  },

  async countUnreadByCanal(canalId, since) {
    let query = supabase
      .from('messages')
      .select('id', { count: 'exact', head: true })
      .eq('canal_id', canalId);

    if (since) query = query.gt('created_at', since);
    const { count, error } = await query;
    if (error) throw error;
    return count || 0;
  },
};

module.exports = MessageModel;
