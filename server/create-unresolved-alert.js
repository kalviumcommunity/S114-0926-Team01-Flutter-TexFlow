const { PrismaClient } = require('@prisma/client');
const p = new PrismaClient();

async function test() {
  const spinning = await p.productionStage.findFirst({ 
    where: { name: 'Spinning', order: 2 },
    orderBy: { createdAt: 'desc' }
  });
  
  // Create an UNRESOLVED alert
  const alert = await p.bottleneckAlert.create({
    data: {
      stageId: spinning.id,
      message: 'Test unresolved bottleneck',
      severity: 'high',
      resolved: false,
    },
  });
  
  console.log('Created unresolved alert:', alert);
  await p.$disconnect();
}

test();