const express = require('express');
const router = express.Router();
const expenseController = require('../controllers/expenseController');
const auth = require('../middleware/auth');
const { isAdmin } = require('../middleware/isAdmin');

router.get('/export', auth, isAdmin, expenseController.exportCSV);
router.get('/', auth, expenseController.getAll);
router.get('/:id', auth, expenseController.getById);
router.post('/', auth, expenseController.create);
router.patch('/:id/status', auth, isAdmin, expenseController.updateStatus);

module.exports = router;
