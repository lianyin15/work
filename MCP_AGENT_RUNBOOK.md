# MCP Agent Runbook

## 用途

当用户要求“安装 MCP”“配置 MySQL MCP”“配置 Kubernetes MCP”“让 Agent 连接数据库或集群”时，Agent 先读取本文件，再按步骤引导和执行。

本文件面向 Agent，不是普通教程。执行时必须遵守项目根目录的 `AGENTS.md`：

- 改动前先说明计划。
- 不提交 API Key、密码、token、kubeconfig、证书。
- 本课程项目默认本地运行，不引入 Docker / K8S 作为基础要求。
- Kubernetes MCP 只作为进阶导览或教师指定环境使用。

详细背景文档：

- MySQL MCP：`docs/mysql-mcp-guide.md`
- Kubernetes MCP：`docs/kubernetes-mcp-server-guide.md`

## 总执行原则

1. 默认只做安全配置和只读验证。
2. 不在聊天中要求用户粘贴密码、token、kubeconfig 内容。
3. 需要密码时，让用户在本机终端设置环境变量，或让用户自行输入到本地配置文件。
4. 写入 `opencode.json` 时，只允许使用 `{env:...}` 环境变量占位符，不直接写明文密码。
5. 任何写操作必须先让 Agent 展示计划和将执行的 SQL / Kubernetes 资源变更，再等待用户明确确认。
6. 不用 root MySQL 账号给 Agent 操作数据库。
7. 不用 Kubernetes 管理员 kubeconfig 给 Agent 操作集群。
8. 若前置环境缺失，先说明缺什么和最小补齐方案，不强行继续。

## 第 0 步：确认任务范围

如果用户没有说清楚要配置哪个 MCP，先问一句：

```text
你希望我配置哪一项：MySQL MCP、Kubernetes MCP，还是两者都配置？默认我会先按只读安全模式配置。
```

如果用户说“两者都要”，按顺序执行：

1. MySQL MCP
2. Kubernetes MCP

原因：本课程核心验收依赖 MySQL，Kubernetes 是进阶项。

## 第 1 步：环境预检查

执行前先说明计划，然后运行这些只读命令收集环境信息。

通用检查：

```bash
pwd
node --version
npm --version
opencode --version
```

MySQL MCP 检查：

```bash
mysql --version
```

Kubernetes MCP 检查：

```bash
kubectl version --client
kubectl config current-context
```

如果命令不存在：

- `node` 不存在或版本低于 20：提示安装 Node.js 20+ LTS。
- `mysql` 不存在：提示安装 MySQL Community Server 或配置 MySQL `bin` 到 PATH。
- `kubectl` 不存在：提示 Kubernetes MCP 需要已有 Kubernetes / OpenShift 环境，本课程基础项目不强制配置。
- `opencode` 不存在：提示先完成 `VIBECODING 环境配置.md`。

## 第 2 步：配置文件策略

OpenCode 的 MCP 配置文件放在项目根目录：

```text
opencode.json
```

Agent 写入前必须：

1. 先检查文件是否存在。
2. 若存在，读取并保留已有配置，只追加或更新 `mcp` 中对应条目。
3. 若不存在，创建最小配置。
4. 配置中不得出现真实密码、token、kubeconfig 内容。
5. 写入后把 `opencode.json` 加入 `.git/info/exclude`。

检查和防误提交：

```bash
test -f opencode.json && sed -n '1,220p' opencode.json || true
printf '\nopencode.json\n' >> .git/info/exclude
```

如果运行环境是 Windows PowerShell，把最后一条换成：

```powershell
Add-Content .git\info\exclude "opencode.json"
```

## 第 3 步：MySQL MCP 执行流程

### 3.1 前置要求

确认：

- Node.js 20+
- MySQL 可连接
- 已有或准备创建课程数据库
- 已有或准备创建专用 MySQL 用户

推荐数据库示例：

```text
数据库：vibecoding_demo
用户：vibecoding_agent
主机：127.0.0.1
端口：3306
```

### 3.2 创建数据库和账号

如果用户还没有数据库和账号，让用户在本地 MySQL 中执行。Agent 可以展示 SQL，但不要要求用户把 root 密码发到聊天里。

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

如果用户只想先只读验证，授权可以先用：

```sql
GRANT SELECT ON vibecoding_demo.* TO 'vibecoding_agent'@'localhost';
```

### 3.3 让用户设置环境变量

不要把真实密码写入仓库文件。让用户在启动 OpenCode 的同一个终端里设置：

PowerShell：

```powershell
$env:MYSQL_HOST="127.0.0.1"
$env:MYSQL_PORT="3306"
$env:MYSQL_USER="vibecoding_agent"
$env:MYSQL_PASS="这里换成你的数据库密码"
$env:MYSQL_DB="vibecoding_demo"
```

macOS / Linux：

```bash
export MYSQL_HOST="127.0.0.1"
export MYSQL_PORT="3306"
export MYSQL_USER="vibecoding_agent"
export MYSQL_PASS="这里换成你的数据库密码"
export MYSQL_DB="vibecoding_demo"
```

如果用户不愿在环境变量里设置密码，停止自动配置，提示改读 `docs/mysql-mcp-guide.md` 中“直接写在本地配置中”的方式，并提醒不要提交。

### 3.4 写入 OpenCode 配置

在 `opencode.json` 的 `mcp` 下加入或更新：

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

如果同时配置 Kubernetes MCP，不要覆盖另一个 MCP 条目，要合并到同一个 `mcp` 对象里。

### 3.5 验证 MySQL MCP

让用户重启 OpenCode：

```bash
opencode
```

然后让用户向 Agent 输入：

```text
请使用 mysql_course_db MCP 工具，查看当前数据库有哪些表。只允许查询，不要修改数据。
```

如果成功，再输入：

```text
请使用 mysql_course_db MCP 工具，查询当前数据库的表结构，并总结每张表的字段含义。
```

### 3.6 开启 MySQL 写操作

只有用户明确要求“让 Agent 修改数据库”时才执行。

先说明风险，再把配置改成：

```json
"ALLOW_INSERT_OPERATION": "true",
"ALLOW_UPDATE_OPERATION": "true",
"ALLOW_DELETE_OPERATION": "false"
```

不要默认开启 delete。

验证提示词：

```text
请使用 mysql_course_db MCP 工具，先展示你准备执行的 INSERT 或 UPDATE SQL。
等我确认后，再执行。执行后请 SELECT 查询证明修改成功。
```

## 第 4 步：Kubernetes MCP 执行流程

### 4.1 前置要求

Kubernetes MCP 仅在用户已有 Kubernetes / OpenShift 集群时配置。不要为本课程基础项目创建集群。

确认：

- `kubectl` 可用。
- `kubectl config current-context` 指向正确学习集群。
- 用户有教师提供的只读 kubeconfig，或能创建专用 ServiceAccount。

### 4.2 只读模式优先

先测试 MCP Server 能启动：

```bash
npx -y kubernetes-mcp-server@latest --help
```

让用户设置 kubeconfig 路径。优先使用专用只读 kubeconfig。

PowerShell：

```powershell
$env:KUBECONFIG="$HOME\.kube\mcp-viewer.kubeconfig"
```

macOS / Linux：

```bash
export KUBECONFIG="$HOME/.kube/mcp-viewer.kubeconfig"
```

如果用户还没有只读 kubeconfig，引导阅读并执行：

```text
docs/kubernetes-mcp-server-guide.md 的“五、推荐方案：创建只读 ServiceAccount”
```

### 4.3 写入 OpenCode 配置

在 `opencode.json` 的 `mcp` 下加入或更新：

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "kubernetes_readonly": {
      "type": "local",
      "command": [
        "npx",
        "-y",
        "kubernetes-mcp-server@latest",
        "--read-only",
        "--disable-multi-cluster",
        "--list-output",
        "table"
      ],
      "environment": {
        "KUBECONFIG": "{env:KUBECONFIG}"
      },
      "enabled": true,
      "timeout": 15000
    }
  }
}
```

### 4.4 验证 Kubernetes MCP

让用户重启 OpenCode，然后输入：

```text
请使用 kubernetes_readonly MCP 工具，读取当前 Kubernetes context 和 namespaces。只允许查询，不要修改任何资源。
```

继续验证：

```text
请使用 kubernetes_readonly MCP 工具，查看 default namespace 下的 pods，并按 Running、Pending、Failed 分类说明。
```

### 4.5 Kubernetes 写操作

只有用户明确要求，并且满足以下条件时才继续：

- 是学习集群或隔离 namespace。
- 使用专用 ServiceAccount。
- RBAC 只允许目标 namespace。
- 用户明确确认要关闭 `--read-only`。

不要使用管理员 kubeconfig。

写操作前必须让 Agent 输出：

```text
目标 namespace：
将创建或修改的资源：
预期影响：
回滚方式：
需要用户确认的命令或 YAML：
```

用户确认后再执行。

## 第 5 步：同时配置 MySQL 和 Kubernetes

如果用户要求两者都配置，最终 `opencode.json` 形态应类似：

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
    },
    "kubernetes_readonly": {
      "type": "local",
      "command": [
        "npx",
        "-y",
        "kubernetes-mcp-server@latest",
        "--read-only",
        "--disable-multi-cluster",
        "--list-output",
        "table"
      ],
      "environment": {
        "KUBECONFIG": "{env:KUBECONFIG}"
      },
      "enabled": true,
      "timeout": 15000
    }
  }
}
```

## 第 6 步：记录到 agent-log.md

配置完成后，询问用户是否需要记录到 `agent-log.md`。如果记录，只写无敏感信息：

```markdown
## MCP 配置记录

- 配置项：MySQL MCP / Kubernetes MCP
- 配置文件：opencode.json，已加入 .git/info/exclude
- MySQL：使用环境变量注入连接信息，默认关闭 delete
- Kubernetes：使用 read-only 模式和 KUBECONFIG 环境变量
- 验证方式：通过 Agent 查询表结构 / namespaces / pods
- 风险：不要提交密码、token、kubeconfig；写操作需人工确认
```

## 第 7 步：常见失败处理

### Node 版本不足

说明：

```text
当前 MySQL MCP 推荐 Node.js 20+。请安装 Node.js LTS 20+ 后重启终端。
```

### npm 下载失败

说明：

```text
可能是网络问题。先确认 npm 能访问，再重试 npx 命令。
```

### OpenCode 看不到 MCP 工具

检查：

1. `opencode.json` 是否在项目根目录。
2. 是否重启 OpenCode。
3. `enabled` 是否为 `true`。
4. 环境变量是否在启动 OpenCode 的同一个终端中设置。
5. `npx -y ... --help` 是否能运行。

### MySQL 能命令行连接，MCP 失败

检查：

1. `MYSQL_HOST` 是否用 `127.0.0.1`。
2. `MYSQL_PORT` 是否正确。
3. `MYSQL_USER` 是否有目标库权限。
4. `MYSQL_DB` 是否存在。
5. 密码是否只在本地环境变量中设置。

### Kubernetes kubectl 能用，MCP 失败

检查：

1. `KUBECONFIG` 是否指向正确文件。
2. OpenCode 是否从同一终端启动。
3. ServiceAccount token 是否过期。
4. RBAC 是否允许 `list pods` 或 `list namespaces`。
5. 是否误连到多集群，必要时使用 `--disable-multi-cluster`。

## Agent 完成标准

满足以下条件才算完成：

- 已说明改了哪些文件。
- `opencode.json` 只使用环境变量占位符，不含真实密码或 token。
- `opencode.json` 已加入 `.git/info/exclude`，或已明确提醒用户不要提交。
- MySQL MCP 至少完成只读查询验证，或明确说明卡在哪一步。
- Kubernetes MCP 至少完成只读查询验证，或明确说明没有集群 / kubeconfig 所以无法继续。
- 已说明如何启动 OpenCode 和如何验证。
- 已说明风险和待确认点。
