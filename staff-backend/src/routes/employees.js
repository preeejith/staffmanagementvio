const express = require('express');
const router = express.Router();
const employeeController = require('../controllers/employeeController');
const auth = require('../middleware/auth');
const { isAdmin, isSuperAdmin } = require('../middleware/isAdmin');

router.get('/', auth, isAdmin, employeeController.getAll);
router.get('/:id', auth, isAdmin, employeeController.getById);
router.post('/', auth, isAdmin, employeeController.create);
router.put('/:id', auth, isAdmin, employeeController.update);
router.patch('/:id/toggle-status', auth, isAdmin, employeeController.toggleStatus);
router.delete('/:id', auth, isSuperAdmin, employeeController.remove);
router.post('/:id/upload-document', auth, isAdmin, employeeController.uploadDocument);

module.exports = router;
