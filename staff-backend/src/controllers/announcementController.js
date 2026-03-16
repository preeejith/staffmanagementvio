const { supabaseAdmin } = require('../config/supabase');

// GET /api/announcements
exports.getAll = async (req, res) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('announcements')
      .select('*')
      .eq('is_active', true)
      .order('created_at', { ascending: false });
    if (error) return res.status(400).json({ success: false, error: error.message });
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Failed to fetch announcements' });
  }
};

// POST /api/announcements
exports.create = async (req, res) => {
  try {
    const { title, body, target_audience = 'all', is_active = true } = req.body;
    if (!title || !body) return res.status(400).json({ success: false, error: 'title and body are required' });

    const { data, error } = await supabaseAdmin
      .from('announcements')
      .insert({ title, body, target_audience, is_active })
      .select()
      .single();
    if (error) return res.status(400).json({ success: false, error: error.message });
    res.status(201).json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Failed to create announcement' });
  }
};

// PUT /api/announcements/:id
exports.update = async (req, res) => {
  try {
    const allowed = ['title', 'body', 'target_audience', 'is_active'];
    const updates = {};
    allowed.forEach(key => { if (req.body[key] !== undefined) updates[key] = req.body[key]; });

    const { data, error } = await supabaseAdmin
      .from('announcements').update(updates).eq('id', req.params.id).select().single();
    if (error) return res.status(400).json({ success: false, error: error.message });
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Failed to update announcement' });
  }
};

// PATCH /api/announcements/:id/toggle
exports.toggle = async (req, res) => {
  try {
    const { data: current } = await supabaseAdmin.from('announcements').select('is_active').eq('id', req.params.id).single();
    const { data, error } = await supabaseAdmin
      .from('announcements').update({ is_active: !current.is_active }).eq('id', req.params.id).select().single();
    if (error) return res.status(400).json({ success: false, error: error.message });
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Failed to toggle announcement' });
  }
};
