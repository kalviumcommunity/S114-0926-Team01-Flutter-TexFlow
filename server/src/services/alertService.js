const prisma = require('../config/database');

const getAlerts = async (resolved = false) => {
  return prisma.bottleneckAlert.findMany({
    where: { resolved },
    include: { stage: true },
    orderBy: { createdAt: 'desc' },
  });
};

const resolveAlert = async (alertId) => {
  return prisma.bottleneckAlert.update({
    where: { id: alertId },
    data: { resolved: true, resolvedAt: new Date() },
  });
};

const getDashboardStats = async () => {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);

  const totalToday = await prisma.productionLog.aggregate({
    where: { logTime: { gte: today, lt: tomorrow } },
    _sum: { quantity: true },
    _count: true,
  });

  const activeAlerts = await prisma.bottleneckAlert.count({
    where: { resolved: false },
  });

  const recentLogs = await prisma.productionLog.findMany({
    take: 10,
    include: { stage: true },
    orderBy: { logTime: 'desc' },
  });

  return {
    totalQuantity: totalToday._sum.quantity || 0,
    totalEntries: totalToday._count,
    activeAlerts,
    recentLogs,
  };
};

module.exports = { getAlerts, resolveAlert, getDashboardStats };
