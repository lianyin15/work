# 后端项目

## 启动方式

```bash
cd backend
npm install
# 环境变量（可选）
#   DB_HOST=127.0.0.1
#   DB_PORT=3306
#   DB_USER=root
#   DB_PASSWORD=
#   DB_NAME=checkin_app
npm start
```

## 接口清单

| 方法 | 路径 | 说明 | 需认证 |
|---|---|---|---|
| POST | /api/register | 注册 | 否 |
| POST | /api/login | 登录 | 否 |
| GET | /api/users/me | 当前用户信息 | 是 |
| GET | /api/tasks | 全部任务列表 | 是 |
| GET | /api/tasks/mine | 我的任务列表 | 是 |
| POST | /api/tasks | 创建任务 | 是 |
| GET | /api/tasks/:id | 任务详情 | 是 |
| POST | /api/checkins/:taskId | 打卡 | 是 |
| GET | /api/checkins/:taskId | 打卡记录 | 是 |
| GET | /api/checkins/stats/:taskId | 打卡统计 | 是 |
| GET | /api/leaderboard | 排行榜 | 否 |
| GET | /api/badges | 徽章列表及状态 | 是 |
