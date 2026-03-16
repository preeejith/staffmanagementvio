const { supabaseAdmin } = require('../config/supabase');

async function logAudit(adminId, action, targetTable, targetId, details = {}) {
  try {
    await supabaseAdmin.from('audit_logs').insert({ admin_id: adminId, action, target_table: targetTable, target_id: targetId, details });
  } catch (e) { console.error('[audit_log]', e.message); }
}

// GET /api/employees
exports.getAll = async (req, res) => {
  try {
    const { search, workplace_id, is_active } = req.query;

    let query = supabaseAdmin
      .from('profiles')
      .select('*, workplace:workplaces(id, name, location)')
      .neq('role', 'superadmin')
      .order('created_at', { ascending: false });

    if (search) {
      query = query.or(`name.ilike.%${search}%,email.ilike.%${search}%,phone.ilike.%${search}%`);
    }
    if (workplace_id) query = query.eq('assigned_workplace_id', workplace_id);
    if (is_active !== undefined) query = query.eq('is_active', is_active === 'true');

    const { data, error } = await query;
    if (error) return res.status(400).json({ success: false, error: error.message });

    res.json({ success: true, data });
  } catch (err) {
    console.error('[employees.getAll]', err);
    res.status(500).json({ success: false, error: 'Failed to fetch employees' });
  }
};

// GET /api/employees/:id
exports.getById = async (req, res) => {
  try {
    const { id } = req.params;
    const { data: profile, error } = await supabaseAdmin
      .from('profiles')
      .select('*, workplace:workplaces(*)')
      .eq('id', id)
      .single();

    if (error || !profile) return res.status(404).json({ success: false, error: 'Employee not found' });

    // Expense stats
    const { data: expenses } = await supabaseAdmin
      .from('expenses')
      .select('id, amount, status')
      .eq('employee_id', id);

    const totalExpenses = expenses?.reduce((sum, e) => sum + Number(e.amount), 0) || 0;

    res.json({ success: true, data: { ...profile, expense_count: expenses?.length || 0, total_expenses: totalExpenses } });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Failed to fetch employee' });
  }
};

// POST /api/employees
exports.create = async (req, res) => {
  try {
    const { name, email, phone, aadhaar_number, role = 'employee', assigned_workplace_id, password } = req.body;
    if (!name || !email || !password) {
      return res.status(400).json({ success: false, error: 'name, email, and password are required' });
    }

    // Create auth user
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { name, role },
    });
    if (authError) return res.status(400).json({ success: false, error: authError.message });

    // Update auto-created profile with full data
    const { data: profile, error: profileError } = await supabaseAdmin
      .from('profiles')
      .update({ name, phone, aadhaar_number, role, assigned_workplace_id, created_by: req.user.id })
      .eq('id', authData.user.id)
      .select()
      .single();

    if (profileError) return res.status(400).json({ success: false, error: profileError.message });

    // Update workplace assigned_employees array
    if (assigned_workplace_id) {
      await supabaseAdmin.rpc('array_append_unique', {
        table_name: 'workplaces',
        column_name: 'assigned_employees',
        row_id: assigned_workplace_id,
        new_value: authData.user.id,
      }).catch(() => {
        // Fallback: manual update
        supabaseAdmin
          .from('workplaces')
          .select('assigned_employees')
          .eq('id', assigned_workplace_id)
          .single()
          .then(({ data: wp }) => {
            if (wp) {
              const arr = [...(wp.assigned_employees || []), authData.user.id];
              supabaseAdmin.from('workplaces').update({ assigned_employees: arr }).eq('id', assigned_workplace_id);
            }
          });
      });
    }

    await logAudit(req.user.id, 'create_employee', 'profiles', profile.id, { email });
    res.status(201).json({ success: true, data: profile });
  } catch (err) {
    console.error('[employees.create]', err);
    res.status(500).json({ success: false, error: 'Failed to create employee' });
  }
};

// PUT /api/employees/:id
exports.update = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, phone, aadhaar_number, role, assigned_workplace_id, is_active, profile_photo_url } = req.body;

    const updateFields = {};
    if (name !== undefined) updateFields.name = name;
    if (phone !== undefined) updateFields.phone = phone;
    if (aadhaar_number !== undefined) updateFields.aadhaar_number = aadhaar_number;
    if (role !== undefined) updateFields.role = role;
    if (assigned_workplace_id !== undefined) updateFields.assigned_workplace_id = assigned_workplace_id;
    if (is_active !== undefined) updateFields.is_active = is_active;
    if (profile_photo_url !== undefined) updateFields.profile_photo_url = profile_photo_url;

    const { data, error } = await supabaseAdmin
      .from('profiles')
      .update(updateFields)
      .eq('id', id)
      .select()
      .single();

    if (error) return res.status(400).json({ success: false, error: error.message });

    await logAudit(req.user.id, 'update_employee', 'profiles', id, updateFields);
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Failed to update employee' });
  }
};

// PATCH /api/employees/:id/toggle-status
exports.toggleStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { data: current } = await supabaseAdmin.from('profiles').select('is_active').eq('id', id).single();
    if (!current) return res.status(404).json({ success: false, error: 'Employee not found' });

    const { data, error } = await supabaseAdmin
      .from('profiles')
      .update({ is_active: !current.is_active })
      .eq('id', id)
      .select()
      .single();

    if (error) return res.status(400).json({ success: false, error: error.message });

    await logAudit(req.user.id, 'toggle_employee_status', 'profiles', id, { is_active: data.is_active });
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Failed to toggle status' });
  }
};

// DELETE /api/employees/:id  (superadmin only — soft delete)
exports.remove = async (req, res) => {
  try {
    const { id } = req.params;
    const { data, error } = await supabaseAdmin
      .from('profiles')
      .update({ is_active: false })
      .eq('id', id)
      .select()
      .single();

    if (error) return res.status(400).json({ success: false, error: error.message });

    await logAudit(req.user.id, 'delete_employee', 'profiles', id, {});
    res.json({ success: true, data, message: 'Employee deactivated' });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Failed to deactivate employee' });
  }
};

// POST /api/employees/:id/upload-document
exports.uploadDocument = async (req, res) => {
  try {
    const { id } = req.params;
    const { document_type, file_url } = req.body;

    if (!['aadhaar', 'licence'].includes(document_type)) {
      return res.status(400).json({ success: false, error: 'document_type must be aadhaar or licence' });
    }

    const field = document_type === 'aadhaar' ? 'aadhaar_url' : 'driving_licence_url';
    const { data, error } = await supabaseAdmin
      .from('profiles')
      .update({ [field]: file_url })
      .eq('id', id)
      .select()
      .single();

    if (error) return res.status(400).json({ success: false, error: error.message });

    await logAudit(req.user.id, 'upload_document', 'profiles', id, { document_type });
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Failed to update document' });
  }
};
