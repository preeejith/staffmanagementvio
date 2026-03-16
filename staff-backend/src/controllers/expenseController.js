const { supabaseAdmin } = require('../config/supabase');

async function logAudit(adminId, action, targetTable, targetId, details = {}) {
  try {
    await supabaseAdmin.from('audit_logs').insert({ admin_id: adminId, action, target_table: targetTable, target_id: targetId, details });
  } catch (e) { console.error('[audit_log]', e.message); }
}

// GET /api/expenses  (admin: all; employee: own)
exports.getAll = async (req, res) => {
  try {
    const { employee_id, workplace_id, status, from_date, to_date, min_amount, max_amount, search } = req.query;
    const isAdmin = ['admin', 'superadmin'].includes(req.user.role);

    let query = supabaseAdmin
      .from('expenses')
      .select('*, employee:profiles(id, name, email, profile_photo_url), workplace:workplaces(id, name)')
      .order('submitted_at', { ascending: false });

    if (!isAdmin) {
      query = query.eq('employee_id', req.user.id);
    } else {
      if (employee_id) query = query.eq('employee_id', employee_id);
      if (workplace_id) query = query.eq('workplace_id', workplace_id);
    }

    if (status) query = query.eq('status', status);
    if (from_date) query = query.gte('date', from_date);
    if (to_date) query = query.lte('date', to_date);
    if (min_amount) query = query.gte('amount', Number(min_amount));
    if (max_amount) query = query.lte('amount', Number(max_amount));
    if (search) query = query.ilike('description', `%${search}%`);

    const { data, error } = await query;
    if (error) return res.status(400).json({ success: false, error: error.message });

    const total_amount = data.reduce((sum, e) => sum + Number(e.amount), 0);
    const pending_count = data.filter(e => e.status === 'pending').length;

    res.json({
      success: true,
      data,
      summary: { total_amount, total_count: data.length, pending_count },
    });
  } catch (err) {
    console.error('[expenses.getAll]', err);
    res.status(500).json({ success: false, error: 'Failed to fetch expenses' });
  }
};

// GET /api/expenses/export  (admin: CSV)
exports.exportCSV = async (req, res) => {
  try {
    const { employee_id, workplace_id, status, from_date, to_date } = req.query;

    let query = supabaseAdmin
      .from('expenses')
      .select('date, description, amount, status, admin_notes, employee:profiles(name), workplace:workplaces(name)')
      .order('submitted_at', { ascending: false });

    if (employee_id) query = query.eq('employee_id', employee_id);
    if (workplace_id) query = query.eq('workplace_id', workplace_id);
    if (status) query = query.eq('status', status);
    if (from_date) query = query.gte('date', from_date);
    if (to_date) query = query.lte('date', to_date);

    const { data, error } = await query;
    if (error) return res.status(400).json({ success: false, error: error.message });

    const headers = ['Date', 'Employee', 'Workplace', 'Description', 'Amount', 'Status', 'Admin Notes'];
    const rows = data.map(e => [
      e.date,
      e.employee?.name || '',
      e.workplace?.name || '',
      `"${(e.description || '').replace(/"/g, '""')}"`,
      e.amount,
      e.status,
      `"${(e.admin_notes || '').replace(/"/g, '""')}"`,
    ]);

    const csv = [headers.join(','), ...rows.map(r => r.join(','))].join('\n');

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', `attachment; filename="expenses_${Date.now()}.csv"`);
    res.send(csv);
  } catch (err) {
    res.status(500).json({ success: false, error: 'CSV export failed' });
  }
};

// GET /api/expenses/:id
exports.getById = async (req, res) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('expenses')
      .select('*, employee:profiles(id, name, email, profile_photo_url), workplace:workplaces(id, name)')
      .eq('id', req.params.id)
      .single();

    if (error || !data) return res.status(404).json({ success: false, error: 'Expense not found' });

    // Authorization: employee can only see own
    if (!['admin', 'superadmin'].includes(req.user.role) && data.employee_id !== req.user.id) {
      return res.status(403).json({ success: false, error: 'Access denied' });
    }

    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Failed to fetch expense' });
  }
};

// POST /api/expenses  (employee)
exports.create = async (req, res) => {
  try {
    const { date, description, amount, workplace_id, bill_image_urls = [] } = req.body;
    if (!description || !amount) {
      return res.status(400).json({ success: false, error: 'description and amount are required' });
    }

    const { data, error } = await supabaseAdmin
      .from('expenses')
      .insert({
        employee_id: req.user.id,
        workplace_id: workplace_id || req.user.assigned_workplace_id,
        date: date || new Date().toISOString().split('T')[0],
        description,
        amount: Number(amount),
        bill_image_urls,
        status: 'pending',
      })
      .select()
      .single();

    if (error) return res.status(400).json({ success: false, error: error.message });
    res.status(201).json({ success: true, data });
  } catch (err) {
    console.error('[expenses.create]', err);
    res.status(500).json({ success: false, error: 'Failed to create expense' });
  }
};

// PATCH /api/expenses/:id/status  (admin)
exports.updateStatus = async (req, res) => {
  try {
    const { status, admin_notes } = req.body;
    if (!['approved', 'rejected'].includes(status)) {
      return res.status(400).json({ success: false, error: 'status must be approved or rejected' });
    }

    const { data, error } = await supabaseAdmin
      .from('expenses')
      .update({ status, admin_notes: admin_notes || null })
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) return res.status(400).json({ success: false, error: error.message });

    await logAudit(req.user.id, `expense_${status}`, 'expenses', req.params.id, { status, admin_notes });
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Failed to update expense status' });
  }
};
