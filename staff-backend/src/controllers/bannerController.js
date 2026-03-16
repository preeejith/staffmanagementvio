const { supabaseAdmin } = require('../config/supabase');

async function logAudit(adminId, action, targetTable, targetId, details = {}) {
  try {
    await supabaseAdmin.from('audit_logs').insert({ admin_id: adminId, action, target_table: targetTable, target_id: targetId, details });
  } catch (e) { console.error('[audit_log]', e.message); }
}

// GET /api/banners
exports.getAll = async (req, res) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('banners')
      .select('*, workplace:workplaces(id, name)')
      .eq('is_active', true)
      .order('display_order', { ascending: true });
    if (error) return res.status(400).json({ success: false, error: error.message });
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Failed to fetch banners' });
  }
};

// POST /api/banners
exports.create = async (req, res) => {
  try {
    const { title, subtitle, image_url, workplace_id, display_order } = req.body;
    if (!title) return res.status(400).json({ success: false, error: 'title is required' });

    const { data, error } = await supabaseAdmin
      .from('banners')
      .insert({ title, subtitle, image_url, workplace_id, display_order: display_order || 0 })
      .select()
      .single();
    if (error) return res.status(400).json({ success: false, error: error.message });

    await logAudit(req.user.id, 'create_banner', 'banners', data.id, { title });
    res.status(201).json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Failed to create banner' });
  }
};

// PUT /api/banners/:id
exports.update = async (req, res) => {
  try {
    const allowed = ['title', 'subtitle', 'image_url', 'workplace_id', 'display_order', 'is_active'];
    const updates = {};
    allowed.forEach(key => { if (req.body[key] !== undefined) updates[key] = req.body[key]; });

    const { data, error } = await supabaseAdmin
      .from('banners').update(updates).eq('id', req.params.id).select().single();
    if (error) return res.status(400).json({ success: false, error: error.message });
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Failed to update banner' });
  }
};

// PATCH /api/banners/:id/toggle
exports.toggle = async (req, res) => {
  try {
    const { data: current } = await supabaseAdmin.from('banners').select('is_active').eq('id', req.params.id).single();
    const { data, error } = await supabaseAdmin
      .from('banners').update({ is_active: !current.is_active }).eq('id', req.params.id).select().single();
    if (error) return res.status(400).json({ success: false, error: error.message });
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Failed to toggle banner' });
  }
};

// PATCH /api/banners/reorder
exports.reorder = async (req, res) => {
  try {
    const { ordered_ids = [] } = req.body;
    const updates = ordered_ids.map((id, index) =>
      supabaseAdmin.from('banners').update({ display_order: index }).eq('id', id)
    );
    await Promise.all(updates);
    res.json({ success: true, message: 'Banners reordered' });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Failed to reorder banners' });
  }
};

// DELETE /api/banners/:id
exports.remove = async (req, res) => {
  try {
    const { error } = await supabaseAdmin.from('banners').delete().eq('id', req.params.id);
    if (error) return res.status(400).json({ success: false, error: error.message });
    await logAudit(req.user.id, 'delete_banner', 'banners', req.params.id, {});
    res.json({ success: true, message: 'Banner deleted' });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Failed to delete banner' });
  }
};
