const express = require('express');
const router = express.Router();
const announcementController = require('../controllers/announcementController');
const auth = require('../middleware/auth');
const { isAdmin } = require('../middleware/isAdmin');

router.get('/', auth, announcementController.getAll);
router.post('/', auth, isAdmin, announcementController.create);
router.put('/:id', auth, isAdmin, announcementController.update);
router.patch('/:id/toggle', auth, isAdmin, announcementController.toggle);

module.exports = router;
