# 数据库脚本

## 说明

此目录存放数据库相关脚本。

## 文件说明

| 文件名 | 作用 |
|---|---|
| schema.sql | 建表语句：创建数据库、创建表结构 |
| seed.sql | 初始数据：插入测试数据或基础字典数据 |

## 使用方式

```bash
mysql -u 你的用户名 -p
```

```sql
CREATE DATABASE your_project DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE your_project;
SOURCE database/schema.sql;
SOURCE database/seed.sql;
```
