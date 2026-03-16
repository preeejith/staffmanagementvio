require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

const authRoutes         = require('./src/routes/auth');
const employeeRoutes     = require('./src/routes/employees');
const workplaceRoutes    = require('./src/routes/workplaces');
const expenseRoutes      = require('./src/routes/expenses');
const bannerRoutes       = require('./src/routes/banners');
const announcementRoutes = require('./src/routes/announcements');

const app = express();

// ── Security & parsing ──────────────────────────────────────
app.use(helmet());
app.use(cors({
  origin: ['http://localhost:5173', 'http://localhost:3001'],
  credentials: true,
}));
app.use(express.json({ limit: '10mb' }));

// ── Health check ────────────────────────────────────────────
app.get('/api/health', (req, res) => {
  res.json({ success: true, message: 'Server is running', timestamp: new Date().toISOString() });
});

// ── Routes ──────────────────────────────────────────────────
app.use('/api/auth',          authRoutes);
app.use('/api/employees',     employeeRoutes);
app.use('/api/workplaces',    workplaceRoutes);
app.use('/api/expenses',      expenseRoutes);
app.use('/api/banners',       bannerRoutes);
app.use('/api/announcements', announcementRoutes);

// ── 404 handler ─────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ success: false, error: 'Route not found' });
});

// ── Global error handler ────────────────────────────────────
app.use((err, req, res, next) => {
  console.error('[Global Error]', err);
  res.status(500).json({ success: false, error: 'Internal server error' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Staff backend running on http://localhost:${PORT}`);
});
