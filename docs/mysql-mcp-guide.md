# MySQL MCP 安装与连接指引

## 适用目标

这份手册面向课堂项目学生，目标是让本地 Agent 通过 MCP 连接自己的 MySQL 课程数据库，并在确认后可以直接执行 SQL 查询或修改数据。

完成后你能做到：

1. 本地安装并启动 MySQL。
2. 创建课程项目数据库和专用数据库账号。
3. 在 OpenCode 中配置 MySQL MCP 服务。
4. 让 Agent 查询表结构、读取数据，并在开启写权限后修改数据库。

> 本文以 Windows 11 + PowerShell + OpenCode 为主。其他 Agent 客户端可参考文末补充配置。

## 一、先了解 MCP 是什么

MCP 可以理解为 Agent 调用外部工具的统一接口。MySQL MCP 的调用链路是：

```text
OpenCode / Agent
  -> MySQL MCP Server
  -> 本地 MySQL 数据库
```

Agent 不会“凭空”操作数据库，它必须通过你配置的 MCP Server，并且只能使用你给它的数据库账号权限。

## 二、安全约定

请先遵守这几条规则，再继续配置：

- 只连接本机或课程练习数据库，不连接生产库、公司库、真实业务库。
- 不要把 MySQL 密码、API Key、Token 提交到 Git。
- 不要使用 `root` 账号给 Agent 操作项目数据库。
- 写权限默认关闭；确认能查询后，再按需开启 `INSERT`、`UPDATE`、`DELETE`。
- 让 Agent 修改数据前，先要求它说明将执行的 SQL。

## 三、准备环境

### 1. 检查 Node.js

当前推荐的 MySQL MCP 包 `@benborla29/mcp-server-mysql` 要求 Node.js 20+。在 PowerShell 中执行：

```powershell
node --version
npm --version
```

如果 `node --version` 小于 `v20.0.0`，请到 Node.js 官网下载安装 LTS 版本：

https://nodejs.org

安装完成后，关闭并重新打开 PowerShell，再检查一次版本。

### 2. 检查 MySQL

在 PowerShell 中执行：

```powershell
mysql --version
```

如果能看到版本号，说明 MySQL 客户端可用。建议使用 MySQL 8.0+。

如果提示 `mysql` 不是命令，请安装 MySQL Community Server：

https://dev.mysql.com/downloads/mysql/

Windows 安装时建议选择：

- MySQL Server 8.0 或更新版本
- MySQL Workbench，可选但推荐
- 端口保持默认 `3306`
- 记住你设置的 root 密码

安装完成后如果仍然找不到 `mysql` 命令，需要把 MySQL 的 `bin` 目录加入环境变量 `Path`。常见路径如下：

```text
C:\Program Files\MySQL\MySQL Server 8.0\bin
```

## 四、创建课程数据库和专用账号

打开 PowerShell，先用 root 登录 MySQL：

```powershell
mysql -u root -p
```

输入 root 密码后，执行下面的 SQL。请把库名、用户名和密码改成自己的项目名称。

```sql
CREATE DATABASE vibecoding_demo
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

CREATE USER 'vibecoding_agent'@'localhost'
  IDENTIFIED BY '请换成你自己的强密码';

GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, INDEX
  ON vibecoding_demo.*
  TO 'vibecoding_agent'@'localhost';

FLUSH PRIVILEGES;
```

> 如果只是想先验证查询能力，可以先只授权 `SELECT`。等确认 MCP 连接成功后，再补充 `INSERT`、`UPDATE`、`DELETE` 权限。

验证账号能否登录：

```powershell
mysql -u vibecoding_agent -p -h 127.0.0.1 -P 3306 vibecoding_demo
```

登录后执行：

```sql
SELECT DATABASE();
SHOW TABLES;
```

能看到当前数据库名，说明账号连接正常。

## 五、导入项目数据库脚本

在项目根目录执行：

```powershell
mysql -u vibecoding_agent -p -h 127.0.0.1 -P 3306 vibecoding_demo < database/schema.sql
mysql -u vibecoding_agent -p -h 127.0.0.1 -P 3306 vibecoding_demo < database/seed.sql
```

如果当前 `database/schema.sql` 和 `database/seed.sql` 还是模板注释，需要先根据你的项目需求补充真实建表和初始数据。

## 六、安装并测试 MySQL MCP Server

推荐使用 `npx` 临时运行，不需要全局安装。

先测试包是否能启动：

```powershell
npx -y @benborla29/mcp-server-mysql
```

这个命令可能会因为没有数据库连接环境变量而退出，这是正常的。只要 npm 能下载并启动包，就说明安装链路基本可用。

## 七、在 OpenCode 中配置 MCP

在项目根目录创建或编辑 `opencode.json`。如果你不想把数据库密码放进项目文件，可以使用文末的“环境变量写法”。

### 方式 A：直接写在本地配置中

> 仅限本地练习。不要提交包含密码的 `opencode.json`。

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "mysql_course_db": {
      "type": "local",
      "command": [
        "npx",
        "-y",
        "@benborla29/mcp-server-mysql"
      ],
      "environment": {
        "MYSQL_HOST": "127.0.0.1",
        "MYSQL_PORT": "3306",
        "MYSQL_USER": "vibecoding_agent",
        "MYSQL_PASS": "请换成你的数据库密码",
        "MYSQL_DB": "vibecoding_demo",
        "ALLOW_INSERT_OPERATION": "false",
        "ALLOW_UPDATE_OPERATION": "false",
        "ALLOW_DELETE_OPERATION": "false"
      },
      "enabled": true,
      "timeout": 10000
    }
  }
}
```

为了避免误提交密码，建议把本地配置加入 `.git/info/exclude`：

```powershell
Add-Content .git\info\exclude "opencode.json"
```

### 方式 B：密码放在环境变量中

先在 PowerShell 当前窗口设置环境变量：

```powershell
$env:MYSQL_HOST="127.0.0.1"
$env:MYSQL_PORT="3306"
$env:MYSQL_USER="vibecoding_agent"
$env:MYSQL_PASS="请换成你的数据库密码"
$env:MYSQL_DB="vibecoding_demo"
```

再把 `opencode.json` 写成：

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "mysql_course_db": {
      "type": "local",
      "command": [
        "npx",
        "-y",
        "@benborla29/mcp-server-mysql"
      ],
      "environment": {
        "MYSQL_HOST": "{env:MYSQL_HOST}",
        "MYSQL_PORT": "{env:MYSQL_PORT}",
        "MYSQL_USER": "{env:MYSQL_USER}",
        "MYSQL_PASS": "{env:MYSQL_PASS}",
        "MYSQL_DB": "{env:MYSQL_DB}",
        "ALLOW_INSERT_OPERATION": "false",
        "ALLOW_UPDATE_OPERATION": "false",
        "ALLOW_DELETE_OPERATION": "false"
      },
      "enabled": true,
      "timeout": 10000
    }
  }
}
```

如果你希望每次打开 PowerShell 都自动有这些环境变量，可以用系统“环境变量”界面添加用户变量。课堂练习阶段更推荐先用当前窗口变量，避免把密码散落到太多地方。

## 八、启动 OpenCode 并验证连接

在项目根目录执行：

```powershell
opencode
```

进入 OpenCode 后，可以先问：

```text
请使用 mysql_course_db MCP 工具，查看当前数据库有哪些表。只允许查询，不要修改数据。
```

再问：

```text
请使用 mysql_course_db MCP 工具，查询当前数据库的表结构，并总结每张表的字段含义。
```

如果 Agent 能返回表名或表结构，说明 MCP 已经连接成功。

## 九、开启写权限并让 Agent 修改数据库

MySQL MCP Server 默认关闭写操作。确认查询正常后，如果要让 Agent 插入或更新数据，需要把对应开关改成 `true`。

常见写权限开关：

```json
{
  "ALLOW_INSERT_OPERATION": "true",
  "ALLOW_UPDATE_OPERATION": "true",
  "ALLOW_DELETE_OPERATION": "false"
}
```

建议课堂练习按这个顺序开启：

1. 先开启 `ALLOW_INSERT_OPERATION`，测试新增一条数据。
2. 再开启 `ALLOW_UPDATE_OPERATION`，测试修改刚刚新增的数据。
3. 默认不要开启 `ALLOW_DELETE_OPERATION`，除非你明确要测试删除。

修改 `opencode.json` 后，重启 OpenCode。

可以这样要求 Agent 执行写入：

```text
请使用 mysql_course_db MCP 工具，先展示你准备执行的 INSERT SQL。
等我确认后，再向测试表插入一条演示数据。
```

确认 SQL 没问题后，再回复：

```text
确认执行。执行后请再 SELECT 查询刚插入的数据，证明写入成功。
```

## 十、推荐验收步骤

完成配置后，请按下面顺序截图或记录到 `agent-log.md`：

1. `node --version` 显示 Node.js 20+。
2. `mysql --version` 显示 MySQL 客户端可用。
3. `mysql -u vibecoding_agent -p -h 127.0.0.1 -P 3306 vibecoding_demo` 能登录。
4. OpenCode 能通过 MCP 查询 `SHOW TABLES;`。
5. 开启 `ALLOW_INSERT_OPERATION=true` 后，Agent 能插入一条测试数据。
6. 使用 MySQL 命令行或 Workbench 查询，确认数据库确实发生变化。

## 十一、常见问题

### 1. `node --version` 是 18，可以用吗？

不建议。当前 `@benborla29/mcp-server-mysql` 要求 Node.js 20+。请升级 Node.js LTS。

### 2. `mysql` 命令找不到

说明 MySQL 客户端没有安装，或 MySQL `bin` 目录没有加入 `Path`。把下面路径加入用户环境变量后，重启 PowerShell：

```text
C:\Program Files\MySQL\MySQL Server 8.0\bin
```

### 3. Agent 提示没有 MCP 工具

检查三点：

- `opencode.json` 是否放在项目根目录。
- `mcp.mysql_course_db.enabled` 是否为 `true`。
- 修改配置后是否重启了 OpenCode。

### 4. 能查询，不能插入或更新

先检查 MCP 写权限开关：

```json
"ALLOW_INSERT_OPERATION": "true",
"ALLOW_UPDATE_OPERATION": "true"
```

再检查 MySQL 账号权限：

```sql
SHOW GRANTS FOR 'vibecoding_agent'@'localhost';
```

### 5. 连接被拒绝

常见原因：

- MySQL 服务没有启动。
- 端口不是 `3306`。
- `MYSQL_HOST` 写成了错误地址。
- MySQL 用户只允许 `localhost`，但配置里用了其他主机名。

可以先用命令行确认连接：

```powershell
mysql -u vibecoding_agent -p -h 127.0.0.1 -P 3306 vibecoding_demo
```

## 十二、其他 Agent 客户端补充

### Codex CLI

如果使用 Codex CLI，可以用 MCP 包官方文档中的添加命令：

```bash
codex mcp add mcp_server_mysql \
  --env MYSQL_HOST="127.0.0.1" \
  --env MYSQL_PORT="3306" \
  --env MYSQL_USER="vibecoding_agent" \
  --env MYSQL_PASS="请换成你的数据库密码" \
  --env MYSQL_DB="vibecoding_demo" \
  --env ALLOW_INSERT_OPERATION="false" \
  --env ALLOW_UPDATE_OPERATION="false" \
  --env ALLOW_DELETE_OPERATION="false" \
  -- npx -y @benborla29/mcp-server-mysql
```

### Claude Desktop / 通用 MCP 客户端

多数 MCP 客户端使用 `mcpServers` 配置：

```json
{
  "mcpServers": {
    "mcp_server_mysql": {
      "command": "npx",
      "args": [
        "-y",
        "@benborla29/mcp-server-mysql"
      ],
      "env": {
        "MYSQL_HOST": "127.0.0.1",
        "MYSQL_PORT": "3306",
        "MYSQL_USER": "vibecoding_agent",
        "MYSQL_PASS": "请换成你的数据库密码",
        "MYSQL_DB": "vibecoding_demo",
        "ALLOW_INSERT_OPERATION": "false",
        "ALLOW_UPDATE_OPERATION": "false",
        "ALLOW_DELETE_OPERATION": "false"
      }
    }
  }
}
```

## 十三、参考资料

- `@benborla29/mcp-server-mysql` npm 包：https://www.npmjs.com/package/@benborla29/mcp-server-mysql
- MySQL MCP Server GitHub：https://github.com/benborla/mcp-server-mysql
- MySQL MCP Server 安装说明：https://github.com/benborla/mcp-server-mysql/blob/main/docs/INSTALLATION.md
- OpenCode MCP 配置文档：https://opencode.ai/docs/mcp-servers/
- MySQL Community Server 下载：https://dev.mysql.com/downloads/mysql/
