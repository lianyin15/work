# Agent 使用过程记录

## 阶段 1：需求确认

- 项目选题：学习打卡与成就激励系统（来自模板 README 的实践项目选题列表）
- 确认核心功能：任务创建、每日打卡、积分、徽章、排行榜
- 技术栈：React + Vite（前端）、Express + mysql2（后端）、MySQL（数据库）

## 阶段 2：数据设计

- 设计 5 张表：users, tasks, checkins, badges, user_badges
- 编写 database/schema.sql 和 database/seed.sql

## 阶段 3：后端实现

- Express 项目初始化，安装 cors、mysql2、jsonwebtoken 依赖
- 实现 12 个 REST API 接口（用户、任务、打卡、排行榜、徽章）
- 连续打卡逻辑：查询历史打卡日期，计算连续天数，递增积分
- 徽章自动检测：首次打卡、连续 7/30 天、累计 50/100 次
- JWT 鉴权中间件

## 阶段 4：前端实现

- React + Vite 项目初始化
- AuthContext 管理登录状态和 token
- 实现 6 个页面：登录、注册、任务列表、创建任务、任务详情、排行榜、个人中心
- Vite 代理配置转发 /api 到后端

## 阶段 5：文档

## 改动清单

| 文件 | 说明 |
|---|---|
| database/schema.sql | 建表脚本（5 张表） |
| database/seed.sql | 初始徽章数据 |
| backend/package.json | 后端依赖配置 |
| backend/db.js | 数据库连接池 |
| backend/middleware/auth.js | JWT 鉴权中间件 |
| backend/server.js | 后端全部 API 路由和业务逻辑 |
| backend/README.md | 后端启动说明和接口清单 |
| frontend/package.json | 前端依赖配置 |
| frontend/vite.config.js | Vite 配置（代理） |
| frontend/index.html | HTML 入口 |
| frontend/src/main.jsx | React 入口 |
| frontend/src/index.css | 全局样式 |
| frontend/src/App.jsx | 路由配置 |
| frontend/src/context/AuthContext.jsx | 认证上下文 |
| frontend/src/utils/api.js | API 请求工具函数 |
| frontend/src/components/Layout.jsx | 导航布局 |
| frontend/src/pages/LoginPage.jsx | 登录页 |
| frontend/src/pages/RegisterPage.jsx | 注册页 |
| frontend/src/pages/HomePage.jsx | 任务列表页 |
| frontend/src/pages/CreateTaskPage.jsx | 创建任务页 |
| frontend/src/pages/TaskDetailPage.jsx | 任务详情与打卡页 |
| frontend/src/pages/LeaderboardPage.jsx | 排行榜页 |
| frontend/src/pages/ProfilePage.jsx | 个人中心页 |
| frontend/README.md | 前端启动说明和页面清单 |
| docs/requirement.md | 需求说明 |
| docs/api.md | 接口文档 |
| docs/acceptance.md | 验收报告 |
| README.md | 项目说明与完整启动步骤 |
| agent-log.md | 本文件 |
