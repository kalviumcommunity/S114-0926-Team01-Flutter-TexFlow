const authService = require('./src/services/authService');

async function test() {
  try {
    const result = await authService.login('test@test.com', 'password123');
    console.log('Login result:', result);
  } catch (e) {
    console.error('Error:', e.message);
  }
}

test();