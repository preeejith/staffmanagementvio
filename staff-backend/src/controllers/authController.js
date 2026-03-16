const { supabaseClient, supabaseAdmin } = require('../config/supabase');

// ── Helper: log admin action ─────────────────────────────────
async function logAudit(adminId, action, targetTable, targetId, details = {}) {
  try {
    await supabaseAdmin.from('audit_logs').insert({
      admin_id: adminId,
      action,
      target_table: targetTable,
      target_id: targetId,
      details,
    });
  } catch (e) {
    console.error('[audit_log]', e.message);
  }
}

// POST /api/auth/login
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ success: false, error: 'Email and password are required' });
    }

    const { data, error } = await supabaseClient.auth.signInWithPassword({ email, password });
    if (error) return res.status(401).json({ success: false, error: error.message });

    const { data: profile, error: profileError } = await supabaseClient
      .from('profiles')
      .select('*')
      .eq('id', data.user.id)
      .single();

    if (profileError || !profile) {
      return res.status(404).json({ success: false, error: 'User profile not found' });
    }

    if (!profile.is_active) {
      return res.status(403).json({ success: false, error: 'Account is deactivated' });
    }

    res.json({
      success: true,
      data: {
        user: profile,
        session: {
          access_token: data.session.access_token,
          refresh_token: data.session.refresh_token,
          expires_at: data.session.expires_at,
        },
      },
    });
  } catch (err) {
    console.error('[login]', err);
    res.status(500).json({ success: false, error: 'Login failed' });
  }
};

// POST /api/auth/logout
exports.logout = async (req, res) => {
  try {
    await supabaseClient.auth.signOut();
    res.json({ success: true, message: 'Logged out successfully' });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Logout failed' });
  }
};

// POST /api/auth/forgot-password
exports.forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ success: false, error: 'Email is required' });

    const { error } = await supabaseAdmin.auth.resetPasswordForEmail(email, {
      redirectTo: 'http://localhost:5173/reset-password',
    });
    if (error) return res.status(400).json({ success: false, error: error.message });

    res.json({ success: true, message: 'Password reset email sent' });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Failed to send reset email' });
  }
};

// POST /api/auth/reset-password  (admin only)
exports.resetPassword = async (req, res) => {
  try {
    const { userId, newPassword } = req.body;
    if (!userId || !newPassword) {
      return res.status(400).json({ success: false, error: 'userId and newPassword are required' });
    }

    const { error } = await supabaseAdmin.auth.admin.updateUserById(userId, {
      password: newPassword,
    });
    if (error) return res.status(400).json({ success: false, error: error.message });

    await logAudit(req.user.id, 'reset_password', 'profiles', userId, { reset_by: req.user.email });
    res.json({ success: true, message: 'Password reset successfully' });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Password reset failed' });
  }
};

// GET /api/auth/me
exports.getMe = async (req, res) => {
  try {
    res.json({ success: true, data: req.user });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Failed to fetch profile' });
  }
};
