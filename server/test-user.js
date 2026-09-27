const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const p = new PrismaClient();

async function test() {
  try {
    const h = await bcrypt.hash('password123', 10);
    const u = await p.user.create({
      data: {
        name: 'Test',
        email: 'test@test.com',
        password: h,
        role: 'supervisor'
      }
    });
    console.log('Created user:', u);
  } catch (e) {
    console.error('Error:', e);
  } finally {
    await p.$disconnect();
  }
}

test();