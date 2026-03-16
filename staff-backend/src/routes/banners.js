const express = require('express');
const router = express.Router();
const bannerController = require('../controllers/bannerController');
const auth = require('../middleware/auth');
const { isAdmin } = require('../middleware/isAdmin');

router.get('/', auth, bannerController.getAll);
router.post('/', auth, isAdmin, bannerController.create);
router.patch('/reorder', auth, isAdmin, bannerController.reorder);
router.put('/:id', auth, isAdmin, bannerController.update);
router.patch('/:id/toggle', auth, isAdmin, bannerController.toggle);
router.delete('/:id', auth, isAdmin, bannerController.remove);

module.exports = router;
