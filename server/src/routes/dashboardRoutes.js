const express = require('express');
const router = express.Router();
const { getAlerts, resolveAlert, getDashboard } = require('../controllers/dashboardController');
const { authenticate } = require('../middleware/auth');

router.get('/', authenticate, getDashboard);
router.get('/alerts', authenticate, getAlerts);
router.patch('/alerts/:id/resolve', authenticate, resolveAlert);

module.exports = router;
