# HZCU VIBECODING 课程项目

## 项目说明

本项目是 **HZCU VIBECODING** 课程的实践项目骨架模板。

你可以基于这个骨架，使用任意技术栈完成你的课程项目。

## 环境配置

环境配置视频教程（OpenCode 安装、DeepSeek 连接、VS Code 配置）：
[https://www.bilibili.com/video/BV151T26CE33/](https://www.bilibili.com/video/BV151T26CE33/)

> 如果本地环境还未配置好，请先看这个视频，跟着做一遍。

## 开发工作流 Skill

本项目内置了 4 个 Agent Skill，对应 VIBECODING 课程实践的 4 个开发阶段。在 OpenCode 中按阶段依次调用。

| Skill | 阶段 | 用法 | 说明 |
|---|---|---|---|
| `vibecoding-require` | 1️⃣ 需求明确 | `skill vibecoding-require` | 把模糊想法写成有边界、可验收的任务契约 |
| `vibecoding-plan` | 2️⃣ 生成计划并审查 | `skill vibecoding-plan` | 先出完整 Plan，人工审查后再允许写代码 |
| `vibecoding-build` | 3️⃣ 实现 | `skill vibecoding-build` | 后端→前端→联调，分步推进，每步只改对应目录 |
| `vibecoding-verify` | 4️⃣ 验收 | `skill vibecoding-verify` | 页面/接口/数据库三方同时验证 |

### 使用流程

在项目目录下启动 OpenCode 后，按阶段依次调用：

```
# 阶段 1：明确需求
skill vibecoding-require

# 阶段 2：生成开发计划（确认需求后再调用）
skill vibecoding-plan

# 阶段 3：开始实现（确认计划后再调用）
skill vibecoding-build

# 阶段 4：验收检查（项目完成后调用）
skill vibecoding-verify
```

Skill 文件位于 `.agents/skills/` 目录下，可直接查看每个 Skill 的详细指令。

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

推荐按以下顺序，配合内置的 Agent Skill 完成项目：

1. **`skill vibecoding-require`** — 明确需求，把想法写成任务契约
2. **`skill vibecoding-plan`** — 出开发计划，审查后再推进
3. **`skill vibecoding-build`** — 分步实现：后端 → 前端 → 联调
4. **`skill vibecoding-verify`** — 验收检查，确认主链路跑通

具体操作：在 `frontend/` 和 `backend/` 目录下搭建各自的脚手架，然后按 Skill 流程分阶段推进。

## 提交物清单

项目完成后必须提交以下内容：

| 提交物 | 说明 |
|---|---|
| `frontend/` + `backend/` | 完整可运行的代码 |
| `database/schema.sql` + `seed.sql` | 建表与初始数据脚本 |
| `README.md` | 项目说明与完整启动步骤 |
| `agent-log.md` | Agent 使用过程记录 |
| `docs/api.md` | 接口文档 |
| `docs/requirement.md` | 需求说明 |
| `docs/acceptance.md` | 验收报告 |

## 实践项目选题

所有项目统一要求：前后端分离、本地启动、MySQL 持久化、至少 3 个页面、5 个接口、2 张表。

| 难度 | 题目 | 描述 | 核心功能 |
|---|---|---|---|
| 入门 | 校园失物招领平台 | 线上统一失物招领入口，拾获者发布、失主检索认领 | 发布拾物/失物信息；列表与关键词搜索；认领申请与处理；状态流转 |
| 入门 | 学习打卡与成就激励系统 | 轻量打卡平台，积分与徽章激励 | 创建打卡任务；每日打卡；连续天数统计；积分计算；成就徽章自动发放 |
| 中级 | 课程设计组队招募系统 | 课程组队线上招募与审核平台 | 发布组队需求；技能标签维护；队伍搜索；入队申请与队长审核 |
| 中级 | 实验报告匿名互评系统 | 在线提交实验报告并匿名互评 | 教师创建互评任务；学生提交报告；系统分配互评；匿名评分；成绩汇总 |
| 高级 | 实验室设备预约与耗材管理 | 设备预约冲突检测与耗材库存管理 | 设备预约与冲突检测；预约审核；耗材入库/领用；库存预警 |

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
