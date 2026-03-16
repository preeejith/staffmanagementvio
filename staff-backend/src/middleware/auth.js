const { supabaseClient } = require('../config/supabase');

/**
 * Middleware: Verify Bearer JWT and attach user to req.user
 */
async function authMiddleware(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ success: false, error: 'Missing or invalid Authorization header' });
    }

    const token = authHeader.split(' ')[1];
    const { data: { user }, error } = await supabaseClient.auth.getUser(token);

    if (error || !user) {
      return res.status(401).json({ success: false, error: 'Invalid or expired token' });
    }

    // Fetch profile for role / workplace info
    const { data: profile, error: profileError } = await supabaseClient
      .from('profiles')
      .select('*')
      .eq('id', user.id)
      .single();

    if (profileError || !profile) {
      return res.status(401).json({ success: false, error: 'User profile not found' });
    }

    if (!profile.is_active) {
      return res.status(403).json({ success: false, error: 'Account is deactivated' });
    }

    req.user = profile;
    req.token = token;
    next();
  } catch (err) {
    console.error('[authMiddleware]', err);
    res.status(500).json({ success: false, error: 'Authentication error' });
  }
}

module.exports = authMiddleware;
