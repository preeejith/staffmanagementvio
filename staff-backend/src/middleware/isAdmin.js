/**
 * Middleware: Require admin or superadmin role
 * Must be used AFTER authMiddleware
 */
function isAdmin(req, res, next) {
  if (!req.user) {
    return res.status(401).json({ success: false, error: 'Not authenticated' });
  }
  if (!['admin', 'superadmin'].includes(req.user.role)) {
    return res.status(403).json({ success: false, error: 'Admin access required' });
  }
  next();
}

/**
 * Middleware: Require superadmin role only
 */
function isSuperAdmin(req, res, next) {
  if (!req.user || req.user.role !== 'superadmin') {
    return res.status(403).json({ success: false, error: 'Superadmin access required' });
  }
  next();
}

module.exports = { isAdmin, isSuperAdmin };
