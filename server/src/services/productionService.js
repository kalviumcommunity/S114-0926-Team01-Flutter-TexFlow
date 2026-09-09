const prisma = require('../config/database');

const createLog = async (userId, stageId, quantity, unit, shift, notes) => {
  const log = await prisma.productionLog.create({
    data: { userId, stageId, quantity, unit, shift, notes },
    include: { stage: true, user: { select: { name: true } } },
  });

  await checkForBottleneck(stageId, quantity, shift);

  return log;
};

const getLogs = async (filters = {}) => {
  const where = {};
  if (filters.shift) where.shift = filters.shift;
  if (filters.stageId) where.stageId = filters.stageId;
  if (filters.date) {
    const start = new Date(filters.date);
    const end = new Date(filters.date);
    end.setDate(end.getDate() + 1);
    where.logTime = { gte: start, lt: end };
  }

  return prisma.productionLog.findMany({
    where,
    include: { stage: true, user: { select: { name: true } } },
    orderBy: { logTime: 'desc' },
  });
};

const getStages = async () => {
  return prisma.productionStage.findMany({ orderBy: { order: 'asc' } });
};

const getStageTotals = async (shift, date) => {
  const where = {};
  if (shift) where.shift = shift;
  if (date) {
    const start = new Date(date);
    const end = new Date(date);
    end.setDate(end.getDate() + 1);
    where.logTime = { gte: start, lt: end };
  }

  const logs = await prisma.productionLog.groupBy({
    by: ['stageId'],
    where,
    _sum: { quantity: true },
    _count: true,
  });

  return logs;
};

const checkForBottleneck = async (stageId, quantity, shift) => {
  const stage = await prisma.productionStage.findUnique({ where: { id: stageId } });
  if (!stage || stage.order === 1) return;

  const prevStage = await prisma.productionStage.findFirst({
    where: { order: stage.order - 1 },
  });

  if (!prevStage) return;

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);

  const prevTotal = await prisma.productionLog.aggregate({
    where: {
      stageId: prevStage.id,
      shift,
      logTime: { gte: today, lt: tomorrow },
    },
    _sum: { quantity: true },
  });

  const currentTotal = await prisma.productionLog.aggregate({
    where: {
      stageId,
      shift,
      logTime: { gte: today, lt: tomorrow },
    },
    _sum: { quantity: true },
  });

  const prevQty = prevTotal._sum.quantity || 0;
  const currentQty = (currentTotal._sum.quantity || 0) + quantity;

  if (prevQty > 0 && currentQty < prevQty * 0.7) {
    await prisma.bottleneckAlert.create({
      data: {
        stageId,
        message: `Bottleneck at ${stage.name}: ${currentQty} units vs ${prevQty} from ${prevStage.name}`,
        severity: currentQty < prevQty * 0.5 ? 'high' : 'medium',
      },
    });
  }
};

module.exports = { createLog, getLogs, getStages, getStageTotals };
