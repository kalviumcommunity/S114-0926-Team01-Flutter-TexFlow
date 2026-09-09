const alertService = require('../services/alertService');

const getAlerts = async (req, res, next) => {
  try {
    const { resolved } = req.query;
    const alerts = await alertService.getAlerts(resolved === 'true');
    res.json(alerts);
  } catch (error) {
    next(error);
  }
};

const resolveAlert = async (req, res, next) => {
  try {
    const { id } = req.params;
    const alert = await alertService.resolveAlert(id);
    res.json(alert);
  } catch (error) {
    next(error);
  }
};

const getDashboard = async (req, res, next) => {
  try {
    const stats = await alertService.getDashboardStats();
    res.json(stats);
  } catch (error) {
    next(error);
  }
};

module.exports = { getAlerts, resolveAlert, getDashboard };
