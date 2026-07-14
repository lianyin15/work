# 学习打卡与成就激励系统

## 项目说明

轻量级学习打卡平台，支持用户创建打卡任务、每日打卡获取积分、自动发放成就徽章、查看积分排行榜。

## 技术栈

- **前端**: React 18 + Vite + React Router 6
- **后端**: Node.js + Express + mysql2
- **数据库**: MySQL 8.0+

## 项目结构

```
project-root/
  frontend/          # React 前端项目
  backend/           # Express 后端项目
  database/
    schema.sql       # 数据库建表脚本
    seed.sql         # 初始数据脚本（徽章配置）
  docs/
    requirement.md   # 需求说明
    api.md           # 接口文档
    acceptance.md    # 验收报告
```

## 启动步骤

### 1. 创建数据库

```sql
-- 在 MySQL 中执行
source database/schema.sql
source database/seed.sql
```

### 2. 启动后端

```bash
cd backend
npm install
# 如需自定义数据库连接，设置环境变量：
#   DB_HOST=127.0.0.1
#   DB_PORT=3306
#   DB_USER=root
#   DB_PASSWORD=your_password
#   DB_NAME=checkin_app
npm start
```

后端默认运行在 `http://localhost:3000`。

### 3. 启动前端

```bash
cd frontend
npm install
npm run dev
```

前端默认运行在 `http://localhost:5173`，已配置代理转发 `/api` 到后端。

### 4. 打开浏览器

访问 `http://localhost:5173`，注册账号后即可使用。

## 数据库表结构

| 表名 | 说明 |
|---|---|
| users | 用户（用户名、密码、昵称、积分） |
| tasks | 打卡任务（标题、描述、起止日期） |
| checkins | 打卡记录（关联任务和用户、日期、积分） |
| badges | 徽章配置（名称、图标、获得条件） |
| user_badges | 用户已获得徽章 |

## 积分规则

- 连续第 n 天打卡 = n 积分
- 中断后重新从 1 分开始

## 徽章列表

| 徽章 | 条件 |
|---|---|
| 🌱 首次打卡 | 完成第一次打卡 |
| 🔥 持之以恒 | 连续打卡 7 天 |
| 💎 坚如磐石 | 连续打卡 30 天 |
| ⭐ 打卡达人 | 累计打卡 50 次 |
| 👑 打卡王者 | 累计打卡 100 次 |
