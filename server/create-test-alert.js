const { PrismaClient } = require('@prisma/client');
const p = new PrismaClient();

async function test() {
  // Get the correct stage IDs
  const rawMaterial = await p.productionStage.findFirst({ 
    where: { name: 'Raw Material Intake', order: 1 },
    orderBy: { createdAt: 'desc' }
  });
  const spinning = await p.productionStage.findFirst({ 
    where: { name: 'Spinning', order: 2 },
    orderBy: { createdAt: 'desc' }
  });
  
  console.log('Raw Material Intake (latest):', rawMaterial.id);
  console.log('Spinning (latest):', spinning.id);
  
  // Create a test alert for Spinning
  const alert = await p.bottleneckAlert.create({
    data: {
      stageId: spinning.id,
      message: 'Test bottleneck at Spinning: 50 units vs 100 from Raw Material Intake',
      severity: 'medium',
    },
  });
  
  console.log('Created alert:', alert);
  
  // Now resolve it
  const resolved = await p.bottleneckAlert.update({
    where: { id: alert.id },
    data: { resolved: true, resolvedAt: new Date() },
  });
  
  console.log('Resolved alert:', resolved);
  
  await p.$disconnect();
}

test();