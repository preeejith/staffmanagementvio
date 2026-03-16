const { supabaseAdmin } = require('../config/supabase');

async function logAudit(adminId, action, targetTable, targetId, details = {}) {
  try {
    await supabaseAdmin.from('audit_logs').insert({ admin_id: adminId, action, target_table: targetTable, target_id: targetId, details });
  } catch (e) { console.error('[audit_log]', e.message); }
}

// GET /api/workplaces
exports.getAll = async (req, res) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('workplaces')
      .select('*')
      .order('created_at', { ascending: false });
    if (error) return res.status(400).json({ success: false, error: error.message });
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Failed to fetch workplaces' });
  }
};

// GET /api/workplaces/:id
exports.getById = async (req, res) => {
  try {
    const { data: workplace, error } = await supabaseAdmin
      .from('workplaces')
      .select('*')
      .eq('id', req.params.id)
      .single();
    if (error || !workplace) return res.status(404).json({ success: false, error: 'Workplace not found' });

    // Fetch assigned employees
    const { data: employees } = await supabaseAdmin
      .from('profiles')
      .select('id, name, email, phone, profile_photo_url, is_active')
      .eq('assigned_workplace_id', req.params.id);

    res.json({ success: true, data: { ...workplace, employees: employees || [] } });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Failed to fetch workplace' });
  }
};

// POST /api/workplaces
exports.create = async (req, res) => {
  try {
    const { name, description, location, instructions, contact_name, contact_phone, contact_email, is_featured, banner_image_url } = req.body;
    if (!name) return res.status(400).json({ success: false, error: 'Workplace name is required' });

    const { data, error } = await supabaseAdmin
      .from('workplaces')
      .insert({ name, description, location, instructions, contact_name, contact_phone, contact_email, is_featured: is_featured || false, banner_image_url })
      .select()
      .single();
    if (error) return res.status(400).json({ success: false, error: error.message });

    await logAudit(req.user.id, 'create_workplace', 'workplaces', data.id, { name });
    res.status(201).json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Failed to create workplace' });
  }
};

// PUT /api/workplaces/:id
exports.update = async (req, res) => {
  try {
    const allowed = ['name', 'description', 'location', 'instructions', 'contact_name', 'contact_phone', 'contact_email', 'is_featured', 'banner_image_url', 'is_active'];
    const updates = {};
    allowed.forEach(key => { if (req.body[key] !== undefined) updates[key] = req.body[key]; });

    const { data, error } = await supabaseAdmin
      .from('workplaces')
      .update(updates)
      .eq('id', req.params.id)
      .select()
      .single();
    if (error) return res.status(400).json({ success: false, error: error.message });

    await logAudit(req.user.id, 'update_workplace', 'workplaces', req.params.id, updates);
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Failed to update workplace' });
  }
};

// PATCH /api/workplaces/:id/assign
exports.assignEmployees = async (req, res) => {
  try {
    const { employee_ids = [] } = req.body;
    const workplaceId = req.params.id;

    // Update workplace
    const { data, error } = await supabaseAdmin
      .from('workplaces')
      .update({ assigned_employees: employee_ids })
      .eq('id', workplaceId)
      .select()
      .single();
    if (error) return res.status(400).json({ success: false, error: error.message });

    // Update each employee's assigned_workplace_id
    if (employee_ids.length > 0) {
      await supabaseAdmin.from('profiles').update({ assigned_workplace_id: workplaceId }).in('id', employee_ids);
    }

    await logAudit(req.user.id, 'assign_employees', 'workplaces', workplaceId, { employee_ids });
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Failed to assign employees' });
  }
};

// PATCH /api/workplaces/:id/toggle-status
exports.toggleStatus = async (req, res) => {
  try {
    const { data: current } = await supabaseAdmin.from('workplaces').select('is_active').eq('id', req.params.id).single();
    const { data, error } = await supabaseAdmin
      .from('workplaces')
      .update({ is_active: !current.is_active })
      .eq('id', req.params.id)
      .select()
      .single();
    if (error) return res.status(400).json({ success: false, error: error.message });
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Failed to toggle status' });
  }
};
