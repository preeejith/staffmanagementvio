const express = require('express');
const router = express.Router();
const workplaceController = require('../controllers/workplaceController');
const auth = require('../middleware/auth');
const { isAdmin } = require('../middleware/isAdmin');

router.get('/', auth, workplaceController.getAll);
router.get('/:id', auth, workplaceController.getById);
router.post('/', auth, isAdmin, workplaceController.create);
router.put('/:id', auth, isAdmin, workplaceController.update);
router.patch('/:id/assign', auth, isAdmin, workplaceController.assignEmployees);
router.patch('/:id/toggle-status', auth, isAdmin, workplaceController.toggleStatus);

module.exports = router;
