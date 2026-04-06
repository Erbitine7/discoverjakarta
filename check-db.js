const mysql = require('mysql2/promise');
require('dotenv').config();

async function checkDatabase() {
  try {
    const pool = mysql.createPool({
      host: process.env.DB_HOST || '127.0.0.1',
      port: process.env.DB_PORT || 3306,
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASS || '',
      database: process.env.DB_NAME || 'discover_jakarta',
    });

    console.log('Testing database connection...');

    // Check if tables exist
    const [tables] = await pool.query('SHOW TABLES');
    console.log('Tables found:', tables.map(t => Object.values(t)[0]));

    // Check admin user
    const [accounts] = await pool.query('SELECT username FROM account');
    console.log('Accounts found:', accounts.map(a => a.username));

    if (accounts.length === 0) {
      console.log('\n❌ No admin user found! You need to import the database.');
      console.log('Run this command in MySQL:');
      console.log('SOURCE C:\\Users\\nicho\\Downloads\\porto\\presentasi flutter\\discoverjakarta\\database\\discover_jakarta.sql');
    } else {
      console.log('\n✅ Database imported successfully!');
    }

    await pool.end();
  } catch (error) {
    console.error('Database error:', error.message);
    console.log('\n❌ Cannot connect to database. Make sure MySQL is running.');
  }
}

checkDatabase();