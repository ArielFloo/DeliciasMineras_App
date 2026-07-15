const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');

const app = express();
app.use(cors()); 
app.use(express.json());


const pool = new Pool({
  user: 'bd2026bl',
  host: 'plop.inf.udec.cl',
  database: 'bd2026bl',
  password: 'bd2026bl',
  port: 5432,
  ssl: { rejectUnauthorized: false } 
});

app.post('/query', async (req, res) => {
  const { sql } = req.body;
  try {
    const result = await pool.query(sql);
    res.json({ success: true, data: result.rows, fields: result.fields });
  } catch (err) {
    res.status(400).json({ success: false, error: err.message });
  }
});

app.listen(3000, () => {
  console.log('Servidor puente SQL corriendo en http://localhost:3000');
});