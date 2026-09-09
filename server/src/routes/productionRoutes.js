const express = require('express');
const router = express.Router();
const { createLog, getLogs, getStages, getStageTotals } = require('../controllers/productionController');
const { authenticate } = require('../middleware/auth');

router.get('/stages', getStages);
router.get('/logs', authenticate, getLogs);
router.post('/logs', authenticate, createLog);
router.get('/totals', authenticate, getStageTotals);

module.exports = router;
