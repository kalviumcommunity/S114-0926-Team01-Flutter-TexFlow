const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const stages = [
    { name: 'Raw Material Intake', description: 'Receiving and inspection of raw materials', order: 1 },
    { name: 'Spinning', description: 'Converting fiber into yarn', order: 2 },
    { name: 'Weaving', description: 'Interlacing yarns to form fabric', order: 3 },
    { name: 'Dyeing', description: 'Coloring the fabric', order: 4 },
    { name: 'Finishing', description: 'Final treatment and quality check', order: 5 },
    { name: 'Cutting & Packing', description: 'Cutting fabric to spec and packaging', order: 6 },
  ];

  for (const stage of stages) {
    await prisma.productionStage.upsert({
      where: { id: stage.name.toLowerCase().replace(/\s+/g, '-') },
      update: {},
      create: stage,
    });
  }

  console.log('Production stages seeded successfully');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
