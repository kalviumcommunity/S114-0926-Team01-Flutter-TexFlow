const { PrismaClient } = require('@prisma/client');
const p = new PrismaClient();

async function test() {
  const alerts = await p.bottleneckAlert.findMany();
  console.log('All alerts:', JSON.stringify(alerts, null, 2));
  
  const stages = await p.productionStage.findMany({ orderBy: { order: 'asc' } });
  console.log('\nStages:', JSON.stringify(stages, null, 2));
  
  const logs = await p.productionLog.findMany({ include: { stage: true }, orderBy: { logTime: 'asc' } });
  console.log('\nLogs:', JSON.stringify(logs, null, 2));
  
  await p.$disconnect();
}

test();