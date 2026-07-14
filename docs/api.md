# 接口文档

**Base URL**: `http://localhost:3000/api`

## 用户接口

### POST /api/register

注册新用户。

Body:
```json
{ "username": "user1", "password": "123456", "nickname": "用户一" }
```

Response (201):
```json
{ "token": "jwt...", "user": { "id": 1, "username": "user1", "nickname": "用户一", "points": 0 } }
```

### POST /api/login

用户登录。

Body:
```json
{ "username": "user1", "password": "123456" }
```

Response (200):
```json
{ "token": "jwt...", "user": { "id": 1, "username": "user1", "nickname": "用户一", "points": 0 } }
```

### GET /api/users/me

获取当前登录用户信息（需认证）。

Response:
```json
{ "id": 1, "username": "user1", "nickname": "用户一", "points": 10, "created_at": "2026-07-13 09:00:00" }
```

## 任务接口

### GET /api/tasks

获取所有任务列表（需认证）。

### GET /api/tasks/mine

获取当前用户创建的任务（需认证）。

### POST /api/tasks

创建打卡任务（需认证）。

Body:
```json
{ "title": "每天学习英语", "description": "背单词30分钟", "start_date": "2026-07-13", "end_date": "2026-08-13" }
```

Response (201):
```json
{ "id": 1, "title": "每天学习英语", "description": "背单词30分钟", "start_date": "2026-07-13", "end_date": "2026-08-13" }
```

### GET /api/tasks/:id

获取任务详情（需认证）。

## 打卡接口

### POST /api/checkins/:taskId

对指定任务进行今日打卡（需认证）。

Response (201):
```json
{ "id": 1, "checkin_date": "2026-07-13", "points": 1, "streak": 1 }
```

### GET /api/checkins/:taskId

获取指定任务的打卡记录（需认证）。

Response:
```json
[{ "id": 1, "task_id": 1, "user_id": 1, "checkin_date": "2026-07-13", "points": 1, "created_at": "..." }]
```

### GET /api/checkins/stats/:taskId

获取指定任务的打卡统计（需认证）。

Response:
```json
{ "total": 3, "total_points": 6, "checked_in_today": false }
```

## 排行榜接口

### GET /api/leaderboard

获取积分排行榜（无需认证）。

Response:
```json
[{ "id": 1, "username": "user1", "nickname": "用户一", "points": 15 }]
```

## 徽章接口

### GET /api/badges

获取所有徽章及当前用户获得状态（需认证）。

Response:
```json
[{ "id": 1, "name": "首次打卡", "description": "完成第一次打卡", "icon": "🌱", "condition_type": "first_checkin", "condition_value": 1, "earned": 1, "earned_at": "..." }]
```
