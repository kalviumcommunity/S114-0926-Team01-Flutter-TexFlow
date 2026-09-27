const authService = require('./src/services/authService');

async function test() {
  try {
    console.log('Testing login...');
    const result = await authService.login('test@test.com', 'password123');
    console.log('Login result:', JSON.stringify(result, null, 2));
  } catch (e) {
    console.error('Error:', e.message, e.stack);
  }
}

test();