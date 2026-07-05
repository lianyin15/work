# HZCU VIBECODING 课程项目

## 项目说明

本项目是 **HZCU VIBECODING** 课程的实践项目骨架模板。

你可以基于这个骨架，使用任意技术栈完成你的课程项目。

## 目录结构

```
project-root/
  frontend/          # 前端项目（React / Vue / 其他均可）
  backend/           # 后端项目（Spring Boot / Express / Django / 其他均可）
  database/
    schema.sql       # 数据库建表脚本（必填）
    seed.sql         # 数据库初始数据脚本（必填）
  docs/
    requirement.md   # 需求说明
    api.md           # 接口文档
    acceptance.md    # 验收报告
  README.md          # 本文件 - 项目说明与启动方式
  AGENTS.md          # Agent 工作规则
  agent-log.md       # Agent 使用过程记录
```

## 如何开始

1. 在 `frontend/` 和 `backend/` 目录下搭建各自的项目脚手架
2. 按 `database/schema.sql` 设计表结构并在本地 MySQL 中执行
3. 按 `docs/api.md` 确认并记录接口
4. 完成开发后提交完整的 `README.md`、`agent-log.md`、`docs/`、`database/` 内容

## 技术栈

本模板不做技术栈限制。你可以自由选择任意的前端、后端、数据库组合，只要能满足课程验收标准。

## 课程验收标准

- 前端可以打开并操作
- 后端可以启动并响应请求
- 数据库真实连接并持久化数据
- 主业务链路可以完整操作
- 页面操作后数据库有变化
- README 能指导别人启动
- agent-log.md 能说明 Agent 使用过程
