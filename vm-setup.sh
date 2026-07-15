#!/bin/bash
# ============================================
# VM 一键部署脚本 - 学习打卡激励系统
# CentOS 7.9
# ============================================

set -e

echo "===== 1. 安装 Docker ====="
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io
systemctl start docker
systemctl enable docker

echo "===== 2. 安装 Docker Compose ====="
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

echo "===== 3. 创建项目目录 ====="
mkdir -p /opt/checkin-app
cd /opt/checkin-app

echo "===== 4. 创建项目文件 ====="

# 4a. docker-compose.yml
cat > docker-compose.yml << 'DOCKERCOMPOSE'
services:
  mysql:
    image: mysql:8.4
    container_name: checkin-mysql
    environment:
      MYSQL_ROOT_PASSWORD: 123456
      MYSQL_DATABASE: checkin_app
    ports:
      - "3307:3306"
    volumes:
      - mysql_data:/var/lib/mysql
      - ./database/schema.sql:/docker-entrypoint-initdb.d/01-schema.sql
      - ./database/seed.sql:/docker-entrypoint-initdb.d/02-seed.sql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    build: ./backend
    container_name: checkin-backend
    environment:
      DB_HOST: mysql
      DB_PORT: "3306"
      DB_USER: root
      DB_PASSWORD: "123456"
      DB_NAME: checkin_app
    ports:
      - "3000:3000"
    depends_on:
      mysql:
        condition: service_healthy

  frontend:
    build: ./frontend
    container_name: checkin-frontend
    ports:
      - "80:80"
    depends_on:
      - backend

volumes:
  mysql_data:
DOCKERCOMPOSE

# 4b. database 目录
mkdir -p database
cat > database/schema.sql << 'SCHEMA'
CREATE DATABASE IF NOT EXISTS checkin_app DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE checkin_app;
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    nickname VARCHAR(50) NOT NULL,
    points INT NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE tasks (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    title VARCHAR(100) NOT NULL,
    description VARCHAR(500),
    start_date DATE NOT NULL,
    end_date DATE,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_tasks_user FOREIGN KEY (user_id) REFERENCES users(id)
);
CREATE TABLE checkins (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    task_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    checkin_date DATE NOT NULL,
    points INT NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_checkins_task FOREIGN KEY (task_id) REFERENCES tasks(id),
    CONSTRAINT fk_checkins_user FOREIGN KEY (user_id) REFERENCES users(id),
    UNIQUE KEY uk_task_date (task_id, checkin_date)
);
CREATE TABLE badges (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    description VARCHAR(200) NOT NULL,
    icon VARCHAR(50) NOT NULL DEFAULT 'star',
    condition_type VARCHAR(30) NOT NULL,
    condition_value INT NOT NULL
);
CREATE TABLE user_badges (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    badge_id BIGINT NOT NULL,
    earned_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ub_user FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT fk_ub_badge FOREIGN KEY (badge_id) REFERENCES badges(id),
    UNIQUE KEY uk_user_badge (user_id, badge_id)
);
SCHEMA

cat > database/seed.sql << 'SEED'
SET NAMES utf8mb4;
USE checkin_app;
INSERT INTO badges (name, description, icon, condition_type, condition_value) VALUES
    ('首次打卡', '完成第一次打卡', 'star', 'first_checkin', 1),
    ('持之以恒', '连续打卡 7 天', 'fire', 'streak_7', 7),
    ('坚如磐石', '连续打卡 30 天', 'diamond', 'streak_30', 30),
    ('打卡达人', '累计打卡 50 次', 'medal', 'total_50', 50),
    ('打卡王者', '累计打卡 100 次', 'crown', 'total_100', 100);
SEED

# 4c. backend 目录
mkdir -p backend/middleware

cat > backend/package.json << 'PKGBACK'
{
  "name": "checkin-app-backend",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "cors": "^2.8.5",
    "express": "^4.21.0",
    "jsonwebtoken": "^9.0.2",
    "mysql2": "^3.11.0"
  }
}
PKGBACK

cat > backend/db.js << 'DBJS'
const mysql = require('mysql2/promise');
const pool = mysql.createPool({
  host: process.env.DB_HOST || '127.0.0.1',
  port: parseInt(process.env.DB_PORT || '3306'),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '123456',
  database: process.env.DB_NAME || 'checkin_app',
  charset: 'utf8mb4',
  waitForConnections: true,
  connectionLimit: 10,
});
module.exports = pool;
DBJS

cat > backend/middleware/auth.js << 'AUTHJS'
const jwt = require('jsonwebtoken');
const JWT_SECRET = process.env.JWT_SECRET || 'checkin-app-secret-key';
function auth(req, res, next) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ error: '未登录' });
  }
  try {
    const payload = jwt.verify(header.slice(7), JWT_SECRET);
    req.userId = payload.userId;
    req.username = payload.username;
    next();
  } catch {
    return res.status(401).json({ error: '登录已过期' });
  }
}
module.exports = { auth, JWT_SECRET };
AUTHJS

cat > backend/server.js << 'SRVJS'
const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const pool = require('./db');
const { auth, JWT_SECRET } = require('./middleware/auth');

const app = express();
app.use(cors());
app.use(express.json());

app.post('/api/register', async (req, res) => {
  const { username, password, nickname } = req.body;
  if (!username || !password || !nickname) return res.status(400).json({ error: '缺少必填字段' });
  try {
    const [rows] = await pool.query('SELECT id FROM users WHERE username = ?', [username]);
    if (rows.length > 0) return res.status(409).json({ error: '用户名已存在' });
    const [result] = await pool.query('INSERT INTO users (username, password, nickname) VALUES (?, ?, ?)', [username, password, nickname]);
    const token = jwt.sign({ userId: result.insertId, username }, JWT_SECRET, { expiresIn: '7d' });
    res.status(201).json({ token, user: { id: result.insertId, username, nickname, points: 0 } });
  } catch (err) { console.error(err); res.status(500).json({ error: '服务器错误' }); }
});

app.post('/api/login', async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) return res.status(400).json({ error: '缺少用户名或密码' });
  try {
    const [rows] = await pool.query('SELECT * FROM users WHERE username = ?', [username]);
    if (rows.length === 0 || rows[0].password !== password) return res.status(401).json({ error: '用户名或密码错误' });
    const user = rows[0];
    const token = jwt.sign({ userId: user.id, username }, JWT_SECRET, { expiresIn: '7d' });
    res.json({ token, user: { id: user.id, username, nickname: user.nickname, points: user.points } });
  } catch (err) { console.error(err); res.status(500).json({ error: '服务器错误' }); }
});

app.get('/api/users/me', auth, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT id, username, nickname, points, created_at FROM users WHERE id = ?', [req.userId]);
    if (rows.length === 0) return res.status(404).json({ error: '用户不存在' });
    res.json(rows[0]);
  } catch (err) { console.error(err); res.status(500).json({ error: '服务器错误' }); }
});

app.get('/api/tasks', auth, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT t.*, u.nickname AS creator_name, (SELECT COUNT(*) FROM checkins c WHERE c.task_id = t.id AND c.user_id = t.user_id) AS checkin_count FROM tasks t JOIN users u ON t.user_id = u.id ORDER BY t.created_at DESC');
    res.json(rows);
  } catch (err) { console.error(err); res.status(500).json({ error: '服务器错误' }); }
});

app.get('/api/tasks/mine', auth, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT t.*, (SELECT COUNT(*) FROM checkins c WHERE c.task_id = t.id AND c.user_id = t.user_id) AS checkin_count FROM tasks t WHERE t.user_id = ? ORDER BY t.created_at DESC', [req.userId]);
    res.json(rows);
  } catch (err) { console.error(err); res.status(500).json({ error: '服务器错误' }); }
});

app.post('/api/tasks', auth, async (req, res) => {
  const { title, description, start_date, end_date } = req.body;
  if (!title || !start_date) return res.status(400).json({ error: '标题和开始日期必填' });
  try {
    const [result] = await pool.query('INSERT INTO tasks (user_id, title, description, start_date, end_date) VALUES (?, ?, ?, ?, ?)', [req.userId, title, description || null, start_date, end_date || null]);
    res.status(201).json({ id: result.insertId, title, description, start_date, end_date });
  } catch (err) { console.error(err); res.status(500).json({ error: '服务器错误' }); }
});

app.get('/api/tasks/:id', auth, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT t.*, u.nickname AS creator_name FROM tasks t JOIN users u ON t.user_id = u.id WHERE t.id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ error: '任务不存在' });
    res.json(rows[0]);
  } catch (err) { console.error(err); res.status(500).json({ error: '服务器错误' }); }
});

app.post('/api/checkins/:taskId', auth, async (req, res) => {
  const taskId = parseInt(req.params.taskId);
  const today = new Date().toISOString().slice(0, 10);
  try {
    const [tasks] = await pool.query('SELECT * FROM tasks WHERE id = ?', [taskId]);
    if (tasks.length === 0) return res.status(404).json({ error: '任务不存在' });
    const [existing] = await pool.query('SELECT id FROM checkins WHERE task_id = ? AND user_id = ? AND checkin_date = ?', [taskId, req.userId, today]);
    if (existing.length > 0) return res.status(409).json({ error: '今天已打卡' });

    const [allDates] = await pool.query('SELECT DISTINCT checkin_date FROM checkins WHERE user_id = ? ORDER BY checkin_date DESC', [req.userId]);
    let streak = 1;
    if (allDates.length > 0) {
      const dates = allDates.map(r => r.checkin_date);
      let count = 1;
      for (let i = 0; i < dates.length - 1; i++) {
        const diff = (new Date(dates[i]) - new Date(dates[i + 1])) / (1000 * 60 * 60 * 24);
        if (diff === 1) count++; else break;
      }
      const yesterday = new Date(today);
      yesterday.setDate(yesterday.getDate() - 1);
      const yesterdayStr = yesterday.toISOString().slice(0, 10);
      if (dates[0] === yesterdayStr) streak = count + 1;
      else if (dates[0] !== today) streak = 1;
      else streak = count;
    }
    const points = streak;
    const [result] = await pool.query('INSERT INTO checkins (task_id, user_id, checkin_date, points) VALUES (?, ?, ?, ?)', [taskId, req.userId, today, points]);
    await pool.query('UPDATE users SET points = points + ? WHERE id = ?', [points, req.userId]);
    await checkAndAwardBadges(req.userId, pool);
    res.status(201).json({ id: result.insertId, checkin_date: today, points, streak });
  } catch (err) { console.error(err); res.status(500).json({ error: '服务器错误' }); }
});

async function checkAndAwardBadges(userId, pool) {
  try {
    const [checkins] = await pool.query('SELECT checkin_date FROM checkins WHERE user_id = ? ORDER BY checkin_date ASC', [userId]);
    if (checkins.length === 0) return;
    const totalCheckins = checkins.length;
    const [badges] = await pool.query('SELECT * FROM badges');
    const [owned] = await pool.query('SELECT badge_id FROM user_badges WHERE user_id = ?', [userId]);
    const ownedIds = new Set(owned.map(r => r.badge_id));
    for (const badge of badges) {
      if (ownedIds.has(badge.id)) continue;
      let earned = false;
      if (badge.condition_type === 'first_checkin' && totalCheckins >= 1) earned = true;
      else if (badge.condition_type === 'total_50' && totalCheckins >= 50) earned = true;
      else if (badge.condition_type === 'total_100' && totalCheckins >= 100) earned = true;
      else if (badge.condition_type === 'streak_7' || badge.condition_type === 'streak_30') {
        const target = badge.condition_value;
        let currentStreak = 1;
        for (let i = 1; i < checkins.length; i++) {
          const diff = (new Date(checkins[i].checkin_date) - new Date(checkins[i - 1].checkin_date)) / (1000 * 60 * 60 * 24);
          if (diff === 1) { currentStreak++; if (currentStreak >= target) { earned = true; break; } }
          else currentStreak = 1;
        }
      }
      if (earned) await pool.query('INSERT INTO user_badges (user_id, badge_id) VALUES (?, ?)', [userId, badge.id]);
    }
  } catch (err) { console.error('徽章检查失败:', err); }
}

app.get('/api/checkins/:taskId', auth, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM checkins WHERE task_id = ? AND user_id = ? ORDER BY checkin_date DESC', [req.params.taskId, req.userId]);
    res.json(rows);
  } catch (err) { console.error(err); res.status(500).json({ error: '服务器错误' }); }
});

app.get('/api/checkins/stats/:taskId', auth, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT COUNT(*) AS total, SUM(points) AS total_points FROM checkins WHERE task_id = ? AND user_id = ?', [req.params.taskId, req.userId]);
    const [todayCheckin] = await pool.query('SELECT id FROM checkins WHERE task_id = ? AND user_id = ? AND checkin_date = CURDATE()', [req.params.taskId, req.userId]);
    rows[0].checked_in_today = todayCheckin.length > 0;
    res.json(rows[0]);
  } catch (err) { console.error(err); res.status(500).json({ error: '服务器错误' }); }
});

app.get('/api/leaderboard', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT id, username, nickname, points FROM users ORDER BY points DESC LIMIT 50');
    res.json(rows);
  } catch (err) { console.error(err); res.status(500).json({ error: '服务器错误' }); }
});

app.get('/api/badges', auth, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT b.*, ub.earned_at IS NOT NULL AS earned, ub.earned_at FROM badges b LEFT JOIN user_badges ub ON ub.badge_id = b.id AND ub.user_id = ? ORDER BY b.id', [req.userId]);
    res.json(rows);
  } catch (err) { console.error(err); res.status(500).json({ error: '服务器错误' }); }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => { console.log('Server running on http://localhost:' + PORT); });
SRVJS

cat > backend/Dockerfile << 'DOCKERBACK'
FROM node:18-alpine
WORKDIR /app
COPY package.json ./
RUN npm install --production
COPY . .
EXPOSE 3000
CMD ["node", "server.js"]
DOCKERBACK

# 4d. frontend 目录
mkdir -p frontend/src/{components,context,pages,utils}

cat > frontend/package.json << 'PKGFRONT'
{
  "name": "checkin-app-frontend",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": { "dev": "vite", "build": "vite build", "preview": "vite preview" },
  "dependencies": { "react": "^18.3.1", "react-dom": "^18.3.1", "react-router-dom": "^6.26.0" },
  "devDependencies": { "@vitejs/plugin-react": "^4.3.1", "vite": "^5.4.2" }
}
PKGFRONT

cat > frontend/vite.config.js << 'VITECFG'
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
export default defineConfig({
  plugins: [react()],
  server: { port: 5173, proxy: { '/api': 'http://backend:3000' } },
});
VITECFG

cat > frontend/index.html << 'INDEXHTML'
<!DOCTYPE html>
<html lang="zh-CN">
<head><meta charset="UTF-8" /><meta name="viewport" content="width=device-width, initial-scale=1.0" /><title>学习打卡激励系统</title></head>
<body><div id="root"></div><script type="module" src="/src/main.jsx"></script></body>
</html>
INDEXHTML

cat > frontend/nginx.conf << 'NGINXCONF'
server {
    listen 80;
    location / { root /usr/share/nginx/html; index index.html; try_files $uri $uri/ /index.html; }
    location /api/ { proxy_pass http://backend:3000; proxy_set_header Host $host; proxy_set_header X-Real-IP $remote_addr; }
}
NGINXCONF

cat > frontend/Dockerfile << 'DOCKERFRONT'
FROM node:18-alpine AS builder
WORKDIR /app
COPY package.json ./
RUN npm install
COPY . .
RUN npm run build
FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
DOCKERFRONT

# React 源码文件
cat > frontend/src/main.jsx << 'MAINJSX'
import React from 'react';import ReactDOM from 'react-dom/client';import { BrowserRouter } from 'react-router-dom';import App from './App';import './index.css';
ReactDOM.createRoot(document.getElementById('root')).render(<BrowserRouter><App /></BrowserRouter>);
MAINJSX

cat > frontend/src/index.css << 'CSS'
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:#f0f2f5;color:#333}
.page{max-width:900px;margin:0 auto;padding:20px}
.card{background:#fff;border-radius:12px;padding:24px;margin-bottom:16px;box-shadow:0 1px 4px rgba(0,0,0,.08)}
.card-title{font-size:18px;font-weight:600;margin-bottom:16px}
.btn{display:inline-flex;align-items:center;justify-content:center;padding:8px 20px;border-radius:8px;border:none;font-size:14px;cursor:pointer;gap:6px}
.btn-primary{background:#1677ff;color:#fff}.btn-primary:hover{background:#4096ff}
.btn-success{background:#52c41a;color:#fff}.btn-success:hover{background:#73d13d}
.btn-default{background:#fff;color:#333;border:1px solid #d9d9d9}.btn-default:hover{border-color:#1677ff;color:#1677ff}
input,textarea,select{width:100%;padding:10px 12px;border:1px solid #d9d9d9;border-radius:8px;font-size:14px;outline:none}
.form-group{margin-bottom:16px}.form-group label{display:block;margin-bottom:6px;font-weight:500;font-size:14px}
.navbar{background:#fff;border-bottom:1px solid #e8e8e8;padding:0 20px;position:sticky;top:0;z-index:100}
.navbar-inner{max-width:900px;margin:0 auto;display:flex;align-items:center;height:56px;gap:24px}
.navbar-brand{font-weight:700;font-size:18px;color:#1677ff}
.navbar-links{display:flex;gap:16px;flex:1}.navbar-links a{color:#666;font-size:14px;padding:4px 8px;border-radius:6px}
.navbar-links a:hover,.navbar-links a.active{color:#1677ff;background:#e6f4ff;text-decoration:none}
.navbar-right{display:flex;align-items:center;gap:12px}.navbar-user{font-size:14px;color:#666}
.auth-page{display:flex;justify-content:center;align-items:center;min-height:100vh}
.auth-card{background:#fff;border-radius:16px;padding:40px;width:400px;box-shadow:0 4px 24px rgba(0,0,0,.08)}
.auth-card h1{text-align:center;margin-bottom:8px;font-size:24px}
.task-list{display:grid;gap:12px}
.task-item{display:flex;justify-content:space-between;align-items:center;padding:16px;background:#fff;border-radius:10px;box-shadow:0 1px 3px rgba(0,0,0,.06)}
.task-item-title{font-size:16px;font-weight:500;margin-bottom:4px}
.task-item-meta{font-size:13px;color:#999;display:flex;gap:16px}
.checkin-header{text-align:center;padding:32px 0}
.checkin-points{font-size:48px;font-weight:700;color:#1677ff}
.leaderboard-item{display:flex;align-items:center;padding:12px 16px;border-bottom:1px solid #f0f0f0;gap:16px}
.leaderboard-rank{width:28px;height:28px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-weight:600;background:#f0f0f0}
.leaderboard-rank.top1{background:#ffd700;color:#fff}.leaderboard-rank.top2{background:#c0c0c0;color:#fff}.leaderboard-rank.top3{background:#cd7f32;color:#fff}
.leaderboard-name{flex:1;font-weight:500}.leaderboard-points{font-weight:600;color:#1677ff}
.badge-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(140px,1fr));gap:12px}
.badge-card{text-align:center;padding:20px 12px;background:#fafafa;border-radius:12px;border:1px solid #f0f0f0}
.badge-card.earned{background:#fffbe6;border-color:#ffe58f}
.badge-icon{font-size:36px;margin-bottom:8px}.badge-name{font-size:14px;font-weight:500}.badge-desc{font-size:12px;color:#999;margin-top:4px}
.profile-header{text-align:center;padding:24px 0}.profile-nickname{font-size:24px;font-weight:600}
.profile-points{font-size:40px;font-weight:700;color:#1677ff;margin-top:12px}
CSS

cat > frontend/src/App.jsx << 'APPJSX'
import React from 'react';import { Routes, Route, Navigate } from 'react-router-dom';import { AuthProvider, useAuth } from './context/AuthContext';import Layout from './components/Layout';import LoginPage from './pages/LoginPage';import RegisterPage from './pages/RegisterPage';import HomePage from './pages/HomePage';import CreateTaskPage from './pages/CreateTaskPage';import TaskDetailPage from './pages/TaskDetailPage';import LeaderboardPage from './pages/LeaderboardPage';import ProfilePage from './pages/ProfilePage';
function ProtectedRoute({ children }){const{user,loading}=useAuth();if(loading)return<div className="loading">加载中...</div>;return user?children:<Navigate to="/login"/>}
export default function App(){return(<AuthProvider><Routes><Route path="/login" element={<LoginPage/>}/><Route path="/register" element={<RegisterPage/>}/><Route element={<ProtectedRoute><Layout/></ProtectedRoute>}><Route path="/" element={<HomePage/>}/><Route path="/tasks/create" element={<CreateTaskPage/>}/><Route path="/tasks/:id" element={<TaskDetailPage/>}/><Route path="/leaderboard" element={<LeaderboardPage/>}/><Route path="/profile" element={<ProfilePage/>}/></Route></Routes></AuthProvider>)}
APPJSX

cat > frontend/src/utils/api.js << 'APIJS'
export async function fetchWithAuth(getToken, url){const token=getToken();const res=await fetch(url,{headers:{Authorization:`Bearer ${token}`}});if(!res.ok){const data=await res.json().catch(()=>({}));throw new Error(data.error||'请求失败')}return res.json()}
export async function postWithAuth(getToken, url, body){const token=getToken();const res=await fetch(url,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify(body)});const data=await res.json();if(!res.ok)throw new Error(data.error||'操作失败');return data}
APIJS

cat > frontend/src/context/AuthContext.jsx << 'AUTHCTX'
import React,{createContext,useContext,useState,useEffect}from 'react';
const AuthContext=createContext(null);const API='/api';
function storeToken(t){localStorage.setItem('token',t)}
function getToken(){return localStorage.getItem('token')}
function clearToken(){localStorage.removeItem('token')}
export function AuthProvider({children}){const[user,setUser]=useState(null);const[loading,setLoading]=useState(true);
useEffect(()=>{const t=getToken();if(t){fetch(`${API}/users/me`,{headers:{Authorization:`Bearer ${t}`}}).then(r=>r.ok?r.json():null).then(d=>{if(d)setUser(d);else clearToken()}).catch(()=>clearToken()).finally(()=>setLoading(false))}else setLoading(false)},[])
async function login(u,p){const r=await fetch(`${API}/login`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({username:u,password:p})});const d=await r.json();if(!r.ok)throw new Error(d.error||'登录失败');storeToken(d.token);setUser(d.user);return d}
async function register(u,p,n){const r=await fetch(`${API}/register`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({username:u,password:p,nickname:n})});const d=await r.json();if(!r.ok)throw new Error(d.error||'注册失败');storeToken(d.token);setUser(d.user);return d}
function logout(){clearToken();setUser(null)}
function refreshUser(){const t=getToken();if(t)fetch(`${API}/users/me`,{headers:{Authorization:`Bearer ${t}`}}).then(r=>r.ok?r.json():null).then(d=>{if(d)setUser(d)})}
return(<AuthContext.Provider value={{user,loading,login,register,logout,refreshUser,getToken:()=>getToken()}}>{children}</AuthContext.Provider>)}
export function useAuth(){return useContext(AuthContext)}
AUTHCTX

cat > frontend/src/components/Layout.jsx << 'LAYOUT'
import React from 'react';import{Outlet,NavLink,useNavigate}from'react-router-dom';import{useAuth}from'../context/AuthContext';
export default function Layout(){const{user,logout}=useAuth();const navigate=useNavigate();function handleLogout(){logout();navigate('/login')}
return(<div><nav className="navbar"><div className="navbar-inner"><NavLink to="/" className="navbar-brand">打卡激励</NavLink><div className="navbar-links"><NavLink to="/" end>任务列表</NavLink><NavLink to="/tasks/create">创建任务</NavLink><NavLink to="/leaderboard">排行榜</NavLink><NavLink to="/profile">个人中心</NavLink></div><div className="navbar-right"><span className="navbar-user">{user?.nickname}({user?.points}分)</span><button className="navbar-logout" style={{fontSize:13,color:'#ff4d4f',cursor:'pointer',background:'none',border:'none'}} onClick={handleLogout}>退出</button></div></div></nav><div className="page"><Outlet/></div></div>)}
LAYOUT

cat > frontend/src/pages/LoginPage.jsx << 'LOGIN'
import React,{useState}from'react';import{Link,useNavigate}from'react-router-dom';import{useAuth}from'../context/AuthContext';
export default function LoginPage(){const{login,user}=useAuth();const navigate=useNavigate();const[form,setForm]=useState({username:'',password:''});const[error,setError]=useState('');if(user){navigate('/',{replace:true});return null}
async function handleSubmit(e){e.preventDefault();setError('');try{await login(form.username,form.password);navigate('/')}catch(err){setError(err.message)}}
return(<div className="auth-page"><div className="auth-card"><h1>学习打卡激励系统</h1><p className="subtitle" style={{color:'#999',marginBottom:24,textAlign:'center'}}>登录你的账号</p><form onSubmit={handleSubmit}><div className="form-group"><label>用户名</label><input value={form.username}onChange={e=>setForm({...form,username:e.target.value})}required/></div><div className="form-group"><label>密码</label><input type="password"value={form.password}onChange={e=>setForm({...form,password:e.target.value})}required/></div>{error&&<div style={{color:'#ff4d4f',fontSize:13,marginTop:8}}>{error}</div>}<button type="submit"className="btn btn-primary"style={{width:'100%',marginTop:8}}>登录</button></form><div style={{textAlign:'center',marginTop:16,fontSize:14}}>没有账号？<Link to="/register">注册</Link></div></div></div>)}
LOGIN

cat > frontend/src/pages/RegisterPage.jsx << 'REGISTER'
import React,{useState}from'react';import{Link,useNavigate}from'react-router-dom';import{useAuth}from'../context/AuthContext';
export default function RegisterPage(){const{register,user}=useAuth();const navigate=useNavigate();const[form,setForm]=useState({username:'',password:'',nickname:''});const[error,setError]=useState('');if(user){navigate('/',{replace:true});return null}
async function handleSubmit(e){e.preventDefault();setError('');try{await register(form.username,form.password,form.nickname);navigate('/')}catch(err){setError(err.message)}}
return(<div className="auth-page"><div className="auth-card"><h1>学习打卡激励系统</h1><p className="subtitle" style={{color:'#999',marginBottom:24,textAlign:'center'}}>创建新账号</p><form onSubmit={handleSubmit}><div className="form-group"><label>用户名</label><input value={form.username}onChange={e=>setForm({...form,username:e.target.value})}required/></div><div className="form-group"><label>昵称</label><input value={form.nickname}onChange={e=>setForm({...form,nickname:e.target.value})}required/></div><div className="form-group"><label>密码</label><input type="password"value={form.password}onChange={e=>setForm({...form,password:e.target.value})}required/></div>{error&&<div style={{color:'#ff4d4f',fontSize:13,marginTop:8}}>{error}</div>}<button type="submit"className="btn btn-primary"style={{width:'100%',marginTop:8}}>注册</button></form><div style={{textAlign:'center',marginTop:16,fontSize:14}}>已有账号？<Link to="/login">登录</Link></div></div></div>)}
REGISTER

cat > frontend/src/pages/HomePage.jsx << 'HOME'
import React,{useState,useEffect}from'react';import{Link}from'react-router-dom';import{useAuth}from'../context/AuthContext';import{fetchWithAuth}from'../utils/api';
export default function HomePage(){const{getToken}=useAuth();const[tasks,setTasks]=useState([]);const[loading,setLoading]=useState(true);const[tab,setTab]=useState('all');
useEffect(()=>{const e=tab==='mine'?'/api/tasks/mine':'/api/tasks';fetchWithAuth(getToken,e).then(d=>setTasks(d)).catch(console.error).finally(()=>setLoading(false))},[tab,getToken]);
if(loading)return<div className="loading">加载中...</div>;return(<div><div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:20}}><h2>任务列表</h2><Link to="/tasks/create"className="btn btn-primary">创建任务</Link></div><div style={{display:'flex',gap:8,marginBottom:16}}><button className={`btn ${tab==='all'?'btn-primary':'btn-default'}`}onClick={()=>setTab('all')}>全部</button><button className={`btn ${tab==='mine'?'btn-primary':'btn-default'}`}onClick={()=>setTab('mine')}>我的任务</button></div>{tasks.length===0?<p style={{color:'#999',textAlign:'center',padding:40}}>暂无任务</p>:<div className="task-list">{tasks.map(t=>(<Link to={`/tasks/${t.id}`}key={t.id}className="task-item"style={{textDecoration:'none',color:'inherit'}}><div className="task-item-left"><div className="task-item-title">{t.title}</div><div className="task-item-meta"><span>创建者:{t.creator_name}</span><span>{t.start_date}{t.end_date?` ~ ${t.end_date}`:''}</span><span>打卡{t.checkin_count}次</span></div></div><div className="task-item-right"><span className={`task-badge ${t.is_active?'active':''}`}>{t.is_active?'进行中':'已结束'}</span><span style={{color:'#999'}}>→</span></div></Link>))}</div>)}
HOME

cat > frontend/src/pages/CreateTaskPage.jsx << 'CREATE'
import React,{useState}from'react';import{useNavigate}from'react-router-dom';import{useAuth}from'../context/AuthContext';
export default function CreateTaskPage(){const{getToken}=useAuth();const navigate=useNavigate();const[form,setForm]=useState({title:'',description:'',start_date:'',end_date:''});const[error,setError]=useState('');const[submitting,setSubmitting]=useState(false);
async function handleSubmit(e){e.preventDefault();if(!form.title||!form.start_date){setError('标题和开始日期必填');return}setSubmitting(true);setError('');try{const token=getToken();const res=await fetch('/api/tasks',{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify(form)});const data=await res.json();if(!res.ok)throw new Error(data.error||'创建失败');navigate(`/tasks/${data.id}`)}catch(err){setError(err.message)}finally{setSubmitting(false)}}
return(<div><h2 style={{marginBottom:20}}>创建打卡任务</h2><div className="card"><form onSubmit={handleSubmit}><div className="form-group"><label>任务标题 *</label><input value={form.title}onChange={e=>setForm({...form,title:e.target.value})}placeholder="如：每天复习高数"required/></div><div className="form-group"><label>任务描述</label><textarea value={form.description}onChange={e=>setForm({...form,description:e.target.value})}placeholder="描述你的打卡目标..."/></div><div className="form-group"><label>开始日期 *</label><input type="date"value={form.start_date}onChange={e=>setForm({...form,start_date:e.target.value})}required/></div><div className="form-group"><label>结束日期（可选）</label><input type="date"value={form.end_date}onChange={e=>setForm({...form,end_date:e.target.value})}/></div>{error&&<div className="form-error">{error}</div>}<div className="form-actions"><button type="submit"className="btn btn-primary"disabled={submitting}>{submitting?'创建中...':'创建任务'}</button><button type="button"className="btn btn-default"onClick={()=>navigate('/')}>取消</button></div></form></div></div>)}
CREATE

cat > frontend/src/pages/TaskDetailPage.jsx << 'DETAIL'
import React,{useState,useEffect}from'react';import{useParams,useNavigate}from'react-router-dom';import{useAuth}from'../context/AuthContext';import{fetchWithAuth,postWithAuth}from'../utils/api';
export default function TaskDetailPage(){const{id}=useParams();const navigate=useNavigate();const{getToken}=useAuth();const[task,setTask]=useState(null);const[stats,setStats]=useState(null);const[checkins,setCheckins]=useState([]);const[loading,setLoading]=useState(true);const[checkingIn,setCheckingIn]=useState(false);const[message,setMessage]=useState('');
useEffect(()=>{fetchWithAuth(getToken,`/api/tasks/${id}`).then(t=>setTask(t));fetchWithAuth(getToken,`/api/checkins/stats/${id}`).then(s=>setStats(s));fetchWithAuth(getToken,`/api/checkins/${id}`).then(c=>setCheckins(c)).catch(console.error).finally(()=>setLoading(false))},[id,getToken]);
async function handleCheckin(){setCheckingIn(true);setMessage('');try{const r=await postWithAuth(getToken,`/api/checkins/${id}`,{});setMessage(`打卡成功！获得 ${r.points} 积分（连续 ${r.streak} 天）`);const[s,c]=await Promise.all([fetchWithAuth(getToken,`/api/checkins/stats/${id}`),fetchWithAuth(getToken,`/api/checkins/${id}`)]);setStats(s);setCheckins(c)}catch(err){setMessage(err.message)}finally{setCheckingIn(false)}}
if(loading)return<div className="loading">加载中...</div>;if(!task)return<div className="loading">任务不存在</div>;
return(<div><button className="btn btn-default"onClick={()=>navigate('/')}style={{marginBottom:16}}>← 返回</button><div className="card"><h2>{task.title}</h2><p style={{color:'#666',marginTop:8}}>{task.description||'暂无描述'}</p><div style={{display:'flex',gap:24,marginTop:16,fontSize:14,color:'#999'}}><span>创建者:{task.creator_name}</span><span>开始:{task.start_date}</span>{task.end_date&&<span>结束:{task.end_date}</span>}</div></div>{stats&&(<div className="card"><div className="checkin-header"><div className="checkin-points">{stats.total_points}</div><div className="checkin-label">累计获得积分</div><div style={{marginTop:8,color:'#999',fontSize:14}}>已打卡 {stats.total} 天</div><div style={{marginTop:16}}><button className={`btn ${stats.checked_in_today?'btn-default':'btn-success'}`}onClick={handleCheckin}disabled={checkingIn||stats.checked_in_today}style={{fontSize:16,padding:'12px 32px'}}>{stats.checked_in_today?'今日已打卡 ✓':(checkingIn?'打卡中...':'今日打卡')}</button></div>{message&&<div style={{marginTop:12,color:message.includes('成功')?'#52c41a':'#ff4d4f',fontSize:14}}>{message}</div>}</div></div>)}<div className="card"><div className="card-title">打卡记录</div>{checkins.length===0?<p style={{color:'#999',textAlign:'center',padding:20}}>暂无打卡记录</p>:<div>{checkins.map(c=>(<div key={c.id}style={{display:'flex',justifyContent:'space-between',padding:'10px 0',borderBottom:'1px solid #f0f0f0',fontSize:14}}><span style={{color:'#666'}}>{c.checkin_date}</span><span style={{color:'#1677ff',fontWeight:500}}>+{c.points}分</span></div>))}</div>}</div></div>)}
DETAIL

cat > frontend/src/pages/LeaderboardPage.jsx << 'LEADER'
import React,{useState,useEffect}from'react';
export default function LeaderboardPage(){const[users,setUsers]=useState([]);const[loading,setLoading]=useState(true);
useEffect(()=>{fetch('/api/leaderboard').then(r=>r.json()).then(d=>setUsers(d)).catch(console.error).finally(()=>setLoading(false))},[])
if(loading)return<div className="loading">加载中...</div>;return(<div><h2 style={{marginBottom:20}}>积分排行榜</h2><div className="card">{users.length===0?<p style={{color:'#999',textAlign:'center',padding:20}}>暂无用户</p>:users.map((u,i)=>(<div className="leaderboard-item"key={u.id}><div className={`leaderboard-rank ${i===0?'top1':i===1?'top2':i===2?'top3':''}`}>{i+1}</div><div className="leaderboard-name">{u.nickname}</div><div className="leaderboard-points">{u.points}分</div></div>))}</div></div>)}
LEADER

cat > frontend/src/pages/ProfilePage.jsx << 'PROFILE'
import React,{useState,useEffect}from'react';import{useAuth}from'../context/AuthContext';import{fetchWithAuth}from'../utils/api';
export default function ProfilePage(){const{user,getToken,refreshUser}=useAuth();const[badges,setBadges]=useState([]);const[loading,setLoading]=useState(true);
useEffect(()=>{fetchWithAuth(getToken,'/api/badges').then(d=>setBadges(d)).catch(console.error).finally(()=>setLoading(false));refreshUser()},[getToken,refreshUser]);
return(<div><div className="card"><div className="profile-header"><div className="profile-nickname">{user?.nickname}</div><div className="profile-username"style={{color:'#999',fontSize:14}}>@{user?.username}</div><div className="profile-points">{user?.points}</div><div className="profile-points-label"style={{fontSize:14,color:'#999'}}>总积分</div></div></div><div className="card"><div className="card-title">我的徽章</div>{loading?<div className="loading">加载中...</div>:badges.length===0?<p style={{color:'#999',textAlign:'center',padding:20}}>暂无徽章</p>:<div className="badge-grid">{badges.map(b=>(<div className={`badge-card ${b.earned?'earned':''}`}key={b.id}><div className="badge-icon">{b.icon}</div><div className="badge-name">{b.name}</div><div className="badge-desc">{b.description}</div><div className="badge-status"style={{fontSize:11,marginTop:6,color:b.earned?'#faad14':'#999'}}>{b.earned?`已获得 ${b.earned_at?new Date(b.earned_at).toLocaleDateString():''}`:'未获得'}</div></div>))}</div>}</div></div>)}
PROFILE

echo "===== 5. 构建并启动 ====="
cd /opt/checkin-app
docker-compose build
docker-compose up -d

echo "===== 完成 ====="
echo "访问 http://$(curl -s ifconfig.me):80 使用系统"
echo "后端 API: http://$(curl -s ifconfig.me):3000"
