/**
 * Discover Jakarta API — Express + MySQL.
 * Same URL contract as the old PHP API: /index.php?action=... and /image.php?path=...
 *
 * Setup: copy .env.example to .env, npm install, npm start
 */

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const mysql = require('mysql2/promise');
const bcrypt = require('bcrypt');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');

// Default 3001 — must match Flutter `kApiBaseUrl` (see lib/config/api_config.dart).
const PORT = Number(process.env.PORT || 3001);
const uploadDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const pool = mysql.createPool({
  host: process.env.DB_HOST || '127.0.0.1',
  port: Number(process.env.DB_PORT || 3306),
  database: process.env.DB_NAME || 'discover_jakarta',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASS || '',
  waitForConnections: true,
  connectionLimit: 10,
});

const app = express();
app.disable('x-powered-by');
app.use(
  cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  }),
);
app.options('*', (_req, res) => res.sendStatus(204));

// No database — use this to verify the process is listening (Flutter "cannot reach" = TCP failed).
app.get('/health', (_req, res) => {
  res.type('application/json').send(JSON.stringify({ ok: true, service: 'discoverjakarta-api' }));
});

// Browsers open "http://host:port/" — there is no page at /; the Flutter app calls /index.php?action=...
app.get('/', (req, res) => {
  const host = req.get('host') || `127.0.0.1:${PORT}`;
  const proto = req.protocol || 'http';
  const base = `${proto}://${host}`;
  res.type('text/html').send(`<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>Discover Jakarta API</title></head>
<body style="font-family:sans-serif;max-width:40rem;margin:2rem;line-height:1.5">
<h1>Discover Jakarta API</h1>
<p>This is the backend only. There is no homepage — the <strong>Flutter app</strong> talks to <code>index.php</code> actions.</p>
<p><a href="${base}/health">Health check</a> (no DB required) — if this fails, the Flutter app cannot connect either.</p>
<p>Quick checks (need MySQL + imported schema):</p>
<ul>
<li><a href="${base}/index.php?action=categories">categories</a></li>
<li><a href="${base}/index.php?action=locations">locations</a></li>
<li><a href="${base}/index.php?action=pois&amp;location=central">pois (Central Jakarta)</a></li>
</ul>
<p>Run the Flutter app for login and the full UI.</p>
</body></html>`);
});

const upload = multer({
  storage: multer.diskStorage({
    destination: (_req, _file, cb) => cb(null, uploadDir),
    filename: (_req, file, cb) => {
      const ext = path.extname(file.originalname || '') || '.jpg';
      cb(null, `img_${Date.now()}_${crypto.randomBytes(8).toString('hex')}${ext}`);
    },
  }),
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const ok = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'].includes(file.mimetype);
    if (!ok) return cb(new Error('Invalid image type'));
    cb(null, true);
  },
});

/** PHP `password_hash()` often stores `$2y$`; Node `bcrypt` compares reliably after swapping to `$2a$`. */
function normalizeBcryptHash(hash) {
  if (typeof hash !== 'string') return hash;
  return hash.replace(/^\$2y\$/, '$2a$');
}

function bearerToken(req) {
  let h = req.get('authorization') || req.get('Authorization') || '';
  const m = h.match(/Bearer\s+(\S+)/i);
  if (m) return m[1];
  const body = req.body;
  if (body && typeof body.access_token === 'string') {
    const t = body.access_token.trim();
    if (t.length === 64 && /^[0-9a-f]+$/i.test(t)) return t;
  }
  return null;
}

async function requireAuth(req) {
  const token = bearerToken(req);
  if (!token || token.length !== 64) {
    const e = new Error('Unauthorized');
    e.statusCode = 401;
    throw e;
  }
  const [rows] = await pool.query(
    `SELECT a.id, a.username FROM sessions s
     JOIN account a ON a.id = s.account_id
     WHERE s.token = ? AND s.expires_at > NOW() LIMIT 1`,
    [token],
  );
  if (!rows.length) {
    const e = new Error('Unauthorized');
    e.statusCode = 401;
    throw e;
  }
  return rows[0];
}

function sendJson(res, status, obj) {
  res.status(status).type('application/json').send(JSON.stringify(obj));
}

app.get('/image.php', (req, res) => {
  let p = String(req.query.path || '').trim();
  if (!p || p.includes('..')) {
    return sendJson(res, 400, { error: 'Invalid path' });
  }
  p = p.replace(/^\/+/, '');
  const resolvedUploads = path.resolve(uploadDir);
  const filePath = path.resolve(path.join(uploadDir, p));
  if (!filePath.startsWith(resolvedUploads + path.sep) && filePath !== resolvedUploads) {
    return sendJson(res, 404, { error: 'File not found' });
  }
  if (!fs.existsSync(filePath) || !fs.statSync(filePath).isFile()) {
    return sendJson(res, 404, { error: 'File not found' });
  }
  res.sendFile(filePath);
});

const jsonParser = express.json();

async function handleApi(req, res) {
  const action = req.query.action || '';
  const method = req.method;

  try {
    if (action === 'locations' && method === 'GET') {
      const [rows] = await pool.query(
        'SELECT id, slug, name, sort_order FROM locations ORDER BY sort_order, name',
      );
      return sendJson(res, 200, { data: rows });
    }

    if (action === 'categories' && method === 'GET') {
      const [rows] = await pool.query('SELECT id, name, slug FROM categories ORDER BY name');
      return sendJson(res, 200, { data: rows });
    }

    if (action === 'pois' && method === 'GET') {
      const slug = String(req.query.location || '');
      if (!slug) {
        return sendJson(res, 400, { error: 'location slug required' });
      }
      const [locRows] = await pool.query('SELECT id FROM locations WHERE slug = ? LIMIT 1', [slug]);
      if (!locRows.length) {
        return sendJson(res, 404, { error: 'Location not found' });
      }
      const locationId = locRows[0].id;
      const search = String(req.query.q || '').trim();
      const categoryId = req.query.category_id;
      let sql = `SELECT p.id, l.slug AS location_slug, p.title AS name, p.description, p.address, p.image_url,
        c.id AS category_id, c.name AS category_name
        FROM poi p
        JOIN locations l ON l.id = p.location_id
        JOIN categories c ON c.id = p.category_id
        WHERE p.location_id = ?`;
      const params = [locationId];
      if (categoryId !== undefined && categoryId !== '' && /^\d+$/.test(String(categoryId))) {
        sql += ' AND p.category_id = ?';
        params.push(Number(categoryId));
      }
      if (search !== '') {
        sql += ' AND (p.title LIKE ? OR p.description LIKE ? OR p.address LIKE ?)';
        const like = `%${search}%`;
        params.push(like, like, like);
      }
      sql += ' ORDER BY p.created_at DESC';
      const [rows] = await pool.query(sql, params);
      return sendJson(res, 200, { data: rows });
    }

    if (action === 'poi' && method === 'GET') {
      const id = req.query.id;
      if (id === undefined || id === '' || !/^\d+$/.test(String(id))) {
        return sendJson(res, 400, { error: 'id required' });
      }
      const [rows] = await pool.query(
        `SELECT p.id, l.slug AS location_slug, p.title AS name, p.description, p.address, p.image_url,
         c.id AS category_id, c.name AS category_name
         FROM poi p
         JOIN locations l ON l.id = p.location_id
         JOIN categories c ON c.id = p.category_id
         WHERE p.id = ? LIMIT 1`,
        [Number(id)],
      );
      if (!rows.length) {
        return sendJson(res, 404, { error: 'Not found' });
      }
      return sendJson(res, 200, { data: rows[0] });
    }

    if (action === 'login' && method === 'POST') {
      const { username, password } = req.body || {};
      const user = String(username || '').trim();
      const pass = String(password || '');
      if (!user || !pass) {
        return sendJson(res, 400, { error: 'username and password required' });
      }
      const [accRows] = await pool.query(
        'SELECT id, password_hash FROM account WHERE username = ? LIMIT 1',
        [user],
      );
      const acc = accRows[0];
      const storedHash = acc ? normalizeBcryptHash(acc.password_hash) : '';
      if (!acc || !(await bcrypt.compare(pass, storedHash))) {
        return sendJson(res, 401, { error: 'Invalid credentials' });
      }
      await pool.query('DELETE FROM sessions WHERE account_id = ?', [acc.id]);
      const token = crypto.randomBytes(32).toString('hex');
      const expires = new Date(Date.now() + 30 * 864e5);
      await pool.query('INSERT INTO sessions (account_id, token, expires_at) VALUES (?, ?, ?)', [
        acc.id,
        token,
        expires,
      ]);
      return sendJson(res, 200, { token, username: user });
    }

    if (action === 'logout' && method === 'POST') {
      const token = bearerToken(req);
      if (token) {
        await pool.query('DELETE FROM sessions WHERE token = ?', [token]);
      }
      return sendJson(res, 200, { ok: true });
    }

    if (action === 'poi' && method === 'POST') {
      await requireAuth(req);
      const id = Number(req.body.id || 0);
      const catId = Number(req.body.category_id || 0);
      const title = String(req.body.title || '').trim();
      const description = String(req.body.description || '').trim();
      const address = String(req.body.address || '').trim();
      let imageUrl = null;

      if (req.file) {
        imageUrl = req.file.filename;
      }

      if (id > 0) {
        if (catId < 1 || !title || !description) {
          return sendJson(res, 400, { error: 'category_id, title, description required' });
        }
        const [cats] = await pool.query('SELECT id FROM categories WHERE id = ? LIMIT 1', [catId]);
        if (!cats.length) {
          return sendJson(res, 400, { error: 'Invalid category' });
        }
        if (imageUrl !== null) {
          const [r] = await pool.query(
            'UPDATE poi SET category_id = ?, title = ?, description = ?, address = ?, image_url = ? WHERE id = ?',
            [catId, title, description, address, imageUrl, id],
          );
          return sendJson(res, 200, { ok: true, affected: r.affectedRows });
        }
        const [r] = await pool.query(
          'UPDATE poi SET category_id = ?, title = ?, description = ?, address = ? WHERE id = ?',
          [catId, title, description, address, id],
        );
        return sendJson(res, 200, { ok: true, affected: r.affectedRows });
      }

      const slug = String(req.body.location_slug || '').trim();
      if (!slug || catId < 1 || !title || !description) {
        return sendJson(res, 400, { error: 'location_slug, category_id, title, description required' });
      }
      const [locs] = await pool.query('SELECT id FROM locations WHERE slug = ? LIMIT 1', [slug]);
      if (!locs.length) {
        return sendJson(res, 400, { error: 'Invalid location' });
      }
      const [cats] = await pool.query('SELECT id FROM categories WHERE id = ? LIMIT 1', [catId]);
      if (!cats.length) {
        return sendJson(res, 400, { error: 'Invalid category' });
      }
      const locationRowId = locs[0].id;
      const [ins] = await pool.query(
        'INSERT INTO poi (location_id, category_id, title, description, address, image_url) VALUES (?, ?, ?, ?, ?, ?)',
        [locationRowId, catId, title, description, address, imageUrl || ''],
      );
      return sendJson(res, 200, { id: Number(ins.insertId) });
    }

    if (action === 'poi' && method === 'DELETE') {
      await requireAuth(req);
      const id = req.query.id;
      if (id === undefined || id === '' || !/^\d+$/.test(String(id))) {
        return sendJson(res, 400, { error: 'id required' });
      }
      const [r] = await pool.query('DELETE FROM poi WHERE id = ?', [Number(id)]);
      return sendJson(res, 200, { ok: true, affected: r.affectedRows });
    }

    return sendJson(res, 404, { error: 'Unknown action' });
  } catch (err) {
    if (err.statusCode === 401) {
      return sendJson(res, 401, { error: 'Unauthorized' });
    }
    console.error(err);
    return sendJson(res, 500, { error: err.message || 'Server error' });
  }
}

app.get('/index.php', handleApi);

app.delete('/index.php', handleApi);

app.post('/index.php', (req, res, next) => {
  const action = req.query.action;
  if (action === 'login') {
    return jsonParser(req, res, (err) => {
      if (err) return next(err);
      handleApi(req, res);
    });
  }
  if (action === 'logout') {
    return handleApi(req, res);
  }
  if (action === 'poi') {
    return upload.single('image')(req, res, (err) => {
      if (err) return next(err);
      handleApi(req, res);
    });
  }
  handleApi(req, res);
});

app.use((err, _req, res, _next) => {
  if (err instanceof multer.MulterError) {
    if (err.code === 'LIMIT_FILE_SIZE') {
      return sendJson(res, 400, { error: 'Image too large (max 5MB)' });
    }
  }
  if (err && err.message === 'Invalid image type') {
    return sendJson(res, 400, { error: 'Invalid image type' });
  }
  console.error(err);
  return sendJson(res, 500, { error: 'Server error' });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Discover Jakarta API listening on port ${PORT}`);
  console.log(`  Health:  http://127.0.0.1:${PORT}/health`);
  console.log(`  Flutter: http://127.0.0.1:${PORT}/index.php?action=categories`);
});
