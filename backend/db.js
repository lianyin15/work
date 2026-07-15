const mysql = require('mysql2/promise');

const pool = mysql.createPool({
  host: process.env.DB_HOST || '127.0.0.1',
  port: parseInt(process.env.DB_PORT || '3306'),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '123456',
  database: process.env.DB_NAME || 'checkin_app',
  charset: 'utf8mb4',
  dateStrings: ['DATE'],
  waitForConnections: true,
  connectionLimit: 10,
});

module.exports = pool;
