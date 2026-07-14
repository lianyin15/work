const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const pool = require('./db');
const { auth, JWT_SECRET } = require('./middleware/auth');

const app = express();
app.use(cors());
app.use(express.json());

// === 用户相关 ===

app.post('/api/register', async (req, res) => {
  const { username, password, nickname } = req.body;
  if (!username || !password || !nickname) {
    return res.status(400).json({ error: '缺少必填字段' });
  }
  try {
    const [rows] = await pool.query('SELECT id FROM users WHERE username = ?', [username]);
    if (rows.length > 0) {
      return res.status(409).json({ error: '用户名已存在' });
    }
    const [result] = await pool.query(
      'INSERT INTO users (username, password, nickname) VALUES (?, ?, ?)',
      [username, password, nickname]
    );
    const token = jwt.sign({ userId: result.insertId, username }, JWT_SECRET, { expiresIn: '7d' });
    res.status(201).json({ token, user: { id: result.insertId, username, nickname, points: 0 } });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: '服务器错误' });
  }
});

app.post('/api/login', async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) {
    return res.status(400).json({ error: '缺少用户名或密码' });
  }
  try {
    const [rows] = await pool.query('SELECT * FROM users WHERE username = ?', [username]);
    if (rows.length === 0 || rows[0].password !== password) {
      return res.status(401).json({ error: '用户名或密码错误' });
    }
    const user = rows[0];
    const token = jwt.sign({ userId: user.id, username }, JWT_SECRET, { expiresIn: '7d' });
    res.json({ token, user: { id: user.id, username, nickname: user.nickname, points: user.points } });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: '服务器错误' });
  }
});

app.get('/api/users/me', auth, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT id, username, nickname, points, created_at FROM users WHERE id = ?', [req.userId]);
    if (rows.length === 0) return res.status(404).json({ error: '用户不存在' });
    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: '服务器错误' });
  }
});

// === 任务相关 ===

app.get('/api/tasks', auth, async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT t.*, u.nickname AS creator_name,
        (SELECT COUNT(*) FROM checkins c WHERE c.task_id = t.id AND c.user_id = t.user_id) AS checkin_count
       FROM tasks t JOIN users u ON t.user_id = u.id
       ORDER BY t.created_at DESC`
    );
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: '服务器错误' });
  }
});

app.get('/api/tasks/mine', auth, async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT t.*,
        (SELECT COUNT(*) FROM checkins c WHERE c.task_id = t.id AND c.user_id = t.user_id) AS checkin_count
       FROM tasks t WHERE t.user_id = ?
       ORDER BY t.created_at DESC`,
      [req.userId]
    );
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: '服务器错误' });
  }
});

app.post('/api/tasks', auth, async (req, res) => {
  const { title, description, start_date, end_date } = req.body;
  if (!title || !start_date) {
    return res.status(400).json({ error: '标题和开始日期必填' });
  }
  try {
    const [result] = await pool.query(
      'INSERT INTO tasks (user_id, title, description, start_date, end_date) VALUES (?, ?, ?, ?, ?)',
      [req.userId, title, description || null, start_date, end_date || null]
    );
    res.status(201).json({ id: result.insertId, title, description, start_date, end_date });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: '服务器错误' });
  }
});

app.get('/api/tasks/:id', auth, async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT t.*, u.nickname AS creator_name
       FROM tasks t JOIN users u ON t.user_id = u.id WHERE t.id = ?`,
      [req.params.id]
    );
    if (rows.length === 0) return res.status(404).json({ error: '任务不存在' });
    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: '服务器错误' });
  }
});

// === 打卡相关 ===

app.post('/api/checkins/:taskId', auth, async (req, res) => {
  const taskId = parseInt(req.params.taskId);
  const today = new Date().toISOString().slice(0, 10);

  try {
    const [tasks] = await pool.query('SELECT * FROM tasks WHERE id = ?', [taskId]);
    if (tasks.length === 0) return res.status(404).json({ error: '任务不存在' });

    const [existing] = await pool.query(
      'SELECT id FROM checkins WHERE task_id = ? AND user_id = ? AND checkin_date = ?',
      [taskId, req.userId, today]
    );
    if (existing.length > 0) {
      return res.status(409).json({ error: '今天已打卡' });
    }

    const [allDates] = await pool.query(
      'SELECT DISTINCT checkin_date FROM checkins WHERE user_id = ? ORDER BY checkin_date DESC',
      [req.userId]
    );

    let streak = 1;
    if (allDates.length > 0) {
      const dates = allDates.map(r => r.checkin_date);
      let count = 1;
      for (let i = 0; i < dates.length - 1; i++) {
        const diff = (new Date(dates[i]) - new Date(dates[i + 1])) / (1000 * 60 * 60 * 24);
        if (diff === 1) count++;
        else break;
      }
      const yesterday = new Date(today);
      yesterday.setDate(yesterday.getDate() - 1);
      const yesterdayStr = yesterday.toISOString().slice(0, 10);
      if (dates[0] === yesterdayStr) streak = count + 1;
      else if (dates[0] !== today) streak = 1;
      else streak = count;
    }

    const points = streak;

    const [result] = await pool.query(
      'INSERT INTO checkins (task_id, user_id, checkin_date, points) VALUES (?, ?, ?, ?)',
      [taskId, req.userId, today, points]
    );

    await pool.query('UPDATE users SET points = points + ? WHERE id = ?', [points, req.userId]);

    await checkAndAwardBadges(req.userId, pool);

    res.status(201).json({ id: result.insertId, checkin_date: today, points, streak });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: '服务器错误' });
  }
});

async function checkAndAwardBadges(userId, pool) {
  try {
    const [checkins] = await pool.query(
      'SELECT checkin_date FROM checkins WHERE user_id = ? ORDER BY checkin_date ASC',
      [userId]
    );

    if (checkins.length === 0) return;

    const totalCheckins = checkins.length;
    const [badges] = await pool.query('SELECT * FROM badges');
    const [owned] = await pool.query('SELECT badge_id FROM user_badges WHERE user_id = ?', [userId]);
    const ownedIds = new Set(owned.map(r => r.badge_id));

    for (const badge of badges) {
      if (ownedIds.has(badge.id)) continue;
      let earned = false;

      if (badge.condition_type === 'first_checkin' && totalCheckins >= 1) {
        earned = true;
      } else if (badge.condition_type === 'total_50' && totalCheckins >= 50) {
        earned = true;
      } else if (badge.condition_type === 'total_100' && totalCheckins >= 100) {
        earned = true;
      } else if (badge.condition_type === 'streak_7' || badge.condition_type === 'streak_30') {
        const target = badge.condition_value;
        let currentStreak = 1;
        for (let i = 1; i < checkins.length; i++) {
          const diff = (new Date(checkins[i].checkin_date) - new Date(checkins[i - 1].checkin_date)) / (1000 * 60 * 60 * 24);
          if (diff === 1) {
            currentStreak++;
            if (currentStreak >= target) { earned = true; break; }
          } else {
            currentStreak = 1;
          }
        }
      }

      if (earned) {
        await pool.query('INSERT INTO user_badges (user_id, badge_id) VALUES (?, ?)', [userId, badge.id]);
      }
    }
  } catch (err) {
    console.error('徽章检查失败:', err);
  }
}

app.get('/api/checkins/:taskId', auth, async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT * FROM checkins WHERE task_id = ? AND user_id = ? ORDER BY checkin_date DESC',
      [req.params.taskId, req.userId]
    );
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: '服务器错误' });
  }
});

app.get('/api/checkins/stats/:taskId', auth, async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT COUNT(*) AS total, SUM(points) AS total_points FROM checkins WHERE task_id = ? AND user_id = ?',
      [req.params.taskId, req.userId]
    );
    const [todayCheckin] = await pool.query(
      'SELECT id FROM checkins WHERE task_id = ? AND user_id = ? AND checkin_date = CURDATE()',
      [req.params.taskId, req.userId]
    );
    rows[0].checked_in_today = todayCheckin.length > 0;
    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: '服务器错误' });
  }
});

// === 排行榜 ===

app.get('/api/leaderboard', async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT id, username, nickname, points FROM users ORDER BY points DESC LIMIT 50'
    );
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: '服务器错误' });
  }
});

// === 徽章 ===

app.get('/api/badges', auth, async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT b.*, ub.earned_at IS NOT NULL AS earned, ub.earned_at
       FROM badges b
       LEFT JOIN user_badges ub ON ub.badge_id = b.id AND ub.user_id = ?
       ORDER BY b.id`,
      [req.userId]
    );
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: '服务器错误' });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
