const productionService = require('../services/productionService');

const createLog = async (req, res, next) => {
  try {
    const { stageId, quantity, unit, shift, notes } = req.body;
    const log = await productionService.createLog(
      req.user.id, stageId, quantity, unit, shift, notes
    );
    res.status(201).json(log);
  } catch (error) {
    next(error);
  }
};

const getLogs = async (req, res, next) => {
  try {
    const { shift, stageId, date } = req.query;
    const logs = await productionService.getLogs({ shift, stageId, date });
    res.json(logs);
  } catch (error) {
    next(error);
  }
};

const getStages = async (req, res, next) => {
  try {
    const stages = await productionService.getStages();
    res.json(stages);
  } catch (error) {
    next(error);
  }
};

const getStageTotals = async (req, res, next) => {
  try {
    const { shift, date } = req.query;
    const totals = await productionService.getStageTotals(shift, date);
    res.json(totals);
  } catch (error) {
    next(error);
  }
};

module.exports = { createLog, getLogs, getStages, getStageTotals };
