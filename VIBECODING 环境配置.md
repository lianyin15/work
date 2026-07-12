# VIBECODING 环境配置指南

## 适用对象

城院大三学生。如果你正在上《VIBECODING》这门课，或者想用 DeepSeek + OpenCode 在本地写代码，这份文档就是为你准备的。

**你需要完成的目标：** 在一台 Windows 11 电脑上，装好命令行工具和编辑器，跑通 OpenCode，连上 DeepSeek 的 API，能对一个真实项目做**只读分析**和**代码生成**。

---

## 本文最终目标

| 项目 | 说明 |
|------|------|
| 编辑器 | VS Code（最新版） |
| 运行环境 | Node.js 18+ |
| 包管理器 | npm（Node.js 自带）+ pnpm（可选） |
| AI 工具 | OpenCode CLI |
| AI 模型 | DeepSeek（deepseek-v4-pro） |
| 操作系统 | Windows 11（原生，不依赖 WSL） |

全部装完后你能做的事情：

1. 在任意项目目录执行 `opencode`，进入 AI 编程助手界面
2. 对项目做只读分析（问 AI 这个项目是干什么的）
3. 让 AI 帮你生成代码、修改代码
4. 在 VS Code 里直接使用 OpenCode 插件（可选）

---

## 需要提前准备的账号与软件

- **GitHub 账号**（注册地址：https://github.com/signup）—— 用于后续克隆代码、提交作业
- **DeepSeek 账号**（注册地址：https://platform.deepseek.com）—— 用于获取 AI 能力
- **稳定的网络连接**（学校校园网或自己的热点即可）
- **一台 Windows 11 电脑**（建议 16GB 内存以上）

---

## Windows 推荐环境

| 组件 | 推荐方案 | 最低要求 |
|------|----------|----------|
| 终端 | Windows Terminal（微软商店免费） | PowerShell 5.1+ |
| 编辑器 | VS Code | 任意文本编辑器 |
| 运行环境 | Node.js 18 LTS | Node.js 18+ |
| Shell | PowerShell（默认） | 兼容 |

> **Windows Terminal** 不是必须的，但比默认的 PowerShell 窗口好用很多，支持多标签、主题、快捷键。建议先花 2 分钟装一下。

---

## 第一步：安装 Git

### 操作步骤

1. 打开浏览器，进入 https://git-scm.com/download/win
2. 下载 Windows 版本（下载会自动开始）
3. 双击安装包，一路 **Next**，全部保持默认选项
4. 安装完成后，**重启** Windows Terminal 或 PowerShell

### 验证安装

在 PowerShell 中执行：

```powershell
git --version
```

你应该看到类似输出：

```
git version 2.47.0.windows.1
```

> ⚠️ 如果提示 `git` 不是命令，说明安装没有成功或 PATH 没有生效。请重新运行安装包，确保勾选了 "Add Git to PATH"（默认是勾上的）。如果安装时没注意，重装一次即可。

---

## 第二步：安装 Node.js

### 操作步骤

1. 打开浏览器，进入 https://nodejs.org
2. 下载 **LTS（长期支持版）**，当前推荐 **Node.js 18.x 或 20.x**
   - 选择左侧的"18.x LTS"或"20.x LTS"，不要选 "Current"（Current 是新特性版，不稳定）
3. 双击安装包，一路 **Next**，保持默认选项
4. 安装完成后，**重启** Windows Terminal 或 PowerShell

### 验证安装

```powershell
node --version
npm --version
```

你应该看到类似：

```
v18.20.4
10.8.2
```

> ⚠️ 两个命令都要输，都要有版本号。如果 `node` 能显示但 `npm` 报错，可能是 PATH 问题，重启终端后再试。如果还是不行，卸载重装 Node.js，安装时勾选 "Automatically install the necessary tools"。

---

## 第三步：安装 pnpm（可选但推荐）

pnpm 比 npm 更快、更省磁盘空间。后续课堂项目中可能会用到。

### 操作步骤

```powershell
npm install -g pnpm
```

### 验证安装

```powershell
pnpm --version
```

输出类似：

```
9.15.0
```

> 💡 如果这一步报错"权限不允许"，可以加上 `--force` 参数，或者以管理员身份运行 PowerShell。
>
> **以管理员身份运行 PowerShell 的方法：** 右键点击开始菜单 → "Windows PowerShell (管理员)" 或 "终端(管理员)"。

---

## 第四步：安装 VS Code 与建议插件

### 操作步骤

1. 打开浏览器，进入 https://code.visualstudio.com
2. 点击 **Download for Windows**（蓝色大按钮）
3. 下载完成后双击安装，**建议勾选以下选项**：
   - ☑ 将"通过 Code 打开"添加到资源管理器右键菜单
   - ☑ 将 Code 注册为受支持的文件编辑器
   - ☑ 添加到 PATH
4. 安装完成后启动 VS Code

### 建议安装的插件（课堂需要）

在 VS Code 左侧点扩展图标（或按 `Ctrl+Shift+X`），搜索并安装以下插件：

| 插件名 | 用途 |
|--------|------|
| **Chinese (Simplified) Language Pack** | 中文界面 |
| **GitLens** | 查看 Git 历史、代码是谁写的 |
| **Prettier** | 自动格式化代码 |
| **ESLint** | JavaScript/TypeScript 代码检查 |
| **Markdown Preview Enhanced** | 预览 Markdown 文件 |
| **GitHub Copilot**（可选，有学生账号再用） | AI 代码补全 |

### 验证安装

在 VS Code 中按 `Ctrl+``（反引号）打开终端，确认终端使用的是 PowerShell：

```powershell
echo $PSVersionTable.PSVersion
```

能显示版本号就 OK。

> 💡 如果 VS Code 内置终端默认不是 PowerShell，点击终端下拉菜单选择 "PowerShell" 即可。

---

## 第五步：安装 OpenCode CLI

OpenCode 是一个命令行 AI 编程工具。我们主推 **npm 全局安装**。

### 操作步骤

```powershell
npm install -g opencode-ai
```

安装过程可能需要 30~60 秒，取决于网速。

### 验证安装

```powershell
opencode --version
```

输出类似：

```
1.x.x
```

如果提示 `opencode` 不是命令，重启 PowerShell 再试。

> ⚠️ Windows 上全局安装的 npm 包通常会被放在 `%AppData%\npm` 目录。如果重启终端后仍然找不到，请检查环境变量 `PATH` 是否包含以下路径：
>
> ```
> C:\Users\你的用户名\AppData\Roaming\npm
> ```
>
> 检查方法：在 PowerShell 中执行 `$env:Path`，看看这个路径在不在里面。如果不在，可以手动加：
>
> ```powershell
> [Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", "User") + ";%AppData%\npm", "User")
> ```
>
> 然后重启终端。

### 备选安装方式（如果 npm 安装失败）

如果你的电脑 npm 安装一直失败（网络问题或权限问题），可以试试以下两种方式之一：

**方式 A：使用 Chocolatey 安装**

```powershell
# 先安装 Chocolatey（以管理员身份运行 PowerShell）
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# 安装 OpenCode
choco install opencode
```

**方式 B：使用 Scoop 安装**

```powershell
# 先安装 Scoop
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex

# 安装 OpenCode
scoop bucket add opencode https://github.com/opencodelabs/scoop-bucket
scoop install opencode
```

**方式 C：直接下载安装包（推荐备用）**

如果上面几种方式都失败，可以直接从 OpenCode 官方下载页下载安装包：

1. 打开浏览器，访问 https://opencode.ai/zh/download
2. 下载 Windows (x64) 版本
3. 双击下载的安装包，按照提示完成安装

> 课堂默认走 **方式 A（npm 安装）**，如果有困难再尝试方式 B 或 C。

---

## 第六步：注册 DeepSeek 并创建 API Key

### 操作步骤

1. 打开浏览器，进入 https://platform.deepseek.com
2. 点击右上角 **Sign Up**，用邮箱注册（也可以用 Google / GitHub 登录）
3. 注册成功后登录
4. 进入 API Keys 页面：https://platform.deepseek.com/api_keys
5. 点击 **Create API Key**（或者类似按钮）
   - 给你的 Key 起个名字，比如 `vibecoding-class`
   - 创建后**复制并保存**这个 Key（它只出现一次！）
   - 格式类似：`sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

### ⚠️ 三个非常重要的提醒

| 编号 | 提醒内容 |
|------|----------|
| 🔴 | **API Key 不要截图发到班级群、不要提交到 Git 仓库。** 任何人拿到你的 Key 都能用你的额度。 |
| 🔴 | **DeepSeek 的新账号通常有免费额度（约 100 万 tokens/月），但用完后需要充值才能继续使用。** 上课前检查一下账户余额。 |
| 🔴 | **模型名注意**：请使用 `deepseek-v4-pro` 或 `deepseek-v4-flash`。旧模型名 `deepseek-chat` 和 `deepseek-reasoner` 将于 2026 年 7 月 24 日停用，不要使用。 |

### 验证 API Key

在 https://platform.deepseek.com/api_keys 页面能看到你创建的 Key 列表，状态为 "Active" 就代表可用。

---

## 第七步：启动 OpenCode 并连接 DeepSeek

### 操作步骤

1. 打开 Windows Terminal 或 PowerShell
2. 随便进入一个目录（比如桌面或者一个练习文件夹）：

```powershell
cd ~/Desktop
```

3. 启动 OpenCode：

```powershell
opencode
```

4. 第一次启动会进入 TUI（终端用户界面）。你会在终端里看到一个交互界面。
5. 在输入框（底部）中输入命令：

```
/connect
```

6. 此时 TUI 会显示可用的 AI 提供商列表。在搜索框中输入 `DeepSeek`。
7. 选中 **DeepSeek**（用方向键上下选择，按回车确认）。
8. 系统会提示你输入 API Key。**粘贴**刚才在 DeepSeek 网站复制的 Key。
   - 粘贴操作：在 Windows Terminal 中，**右键点击**即可粘贴（不用按 Ctrl+V）
9. 如果连接成功，你会看到类似 "Connected to DeepSeek" 的提示。

> 💡 第一次使用 OpenCode 时，TUI 底部会显示可用的操作命令。如果不小心退出了，重新输入 `opencode` 即可。

### 备选：使用桌面版连接

如果你安装了 OpenCode 桌面版，也可以在图形界面中配置：

1. 打开 OpenCode 桌面版
2. 点击右下角 **Settings** → **Providers**
3. 搜索 **DeepSeek**，粘贴你的 API Key，点击连接
4. 回到主界面，在底部模型选单中选择 `deepseek-v4-pro`

### 验证连接

在 OpenCode TUI 中输入：

```
/status
```

如果显示已连接到 DeepSeek，就说明配置好了。

如果 `/connect` 过程中输错了 Key，可以重新运行 `/connect` 重新配置。如果一直不成功，检查：
- API Key 是否复制完整（有没有漏字符）
- DeepSeek 账号是否还有余额

---

## 第八步：选择模型

### 操作步骤

在 OpenCode TUI 中输入：

```
/models
```

TUI 会列出可用的模型。找到并选择 **`deepseek-v4-pro`**（按方向键移动，按回车选择）。

> 如果列表中看不到 `deepseek-v4-pro`，试试 `deepseek-v4-flash`。⚠️ 不要使用 `deepseek-chat` 或 `deepseek-reasoner`，这两个旧模型将于 2026 年 7 月 24 日停用。

### 验证模型已生效

在 OpenCode TUI 中输入：

```
/status
```

确认当前模型显示为 `deepseek-v4-pro`。

### 测试模型能否正常回复

在 OpenCode TUI 底部的输入框里，输入一个最简单的问候：

```
你好
```

如果一切正常，DeepSeek 会在几秒内回复你。这表示：
- ✅ OpenCode CLI 安装正确
- ✅ DeepSeek API Key 有效
- ✅ 模型连接正常

> 如果等了 30 秒还没回复，检查：网络是否正常、API Key 是否正确、DeepSeek 账号是否还有余额。

---

## 第九步：第一次进入项目如何开始

假设你已经有一个项目目录（比如从 GitHub 克隆下来的课堂项目，或者你自己的练习代码）。

### 操作步骤

1. 打开 PowerShell，进入项目目录：

```powershell
cd D:\my-project
```

2. 启动 OpenCode：

```powershell
opencode
```

3. **理解 OpenCode 的两种工作模式**

OpenCode 有两个核心模式，按 `Tab` 键切换：

| 模式 | 右下角显示 | 能力 | 什么时候用 |
|---|---|---|---|
| **Plan 模式** | `Plan` | 只读分析、提问、出计划，**不会改代码** | 刚进入项目、需要了解代码、出开发计划 |
| **Build 模式** | `Build` | 搜索文件、编写代码、执行命令、**可以改文件** | 确认计划后、正式开始实现 |

> 💡 **课堂铁律：先用 Plan 模式看项目、出计划，确认无误后再切 Build 模式写代码。**

4. **不要急着让 AI 修改代码**，先在 **Plan 模式**下做只读提问，了解这个项目：

```
请说明当前目录下有哪些文件，只做分析，不要修改任何文件。
```

5. 让 AI 看完项目结构后，如果你确认这个项目可以安全修改，再使用 `/init` 命令让 AI 正式接管项目上下文：

```
/init
```

> `/init` 会让 OpenCode 读取项目结构、配置文件，后续 AI 的代码生成会更准确。

6. 之后就可以正常提需求了。切到 **Build 模式**，例如：

```
这个项目的 README.md 缺少安装步骤，帮我补充安装说明，写在 README.md 里。
```

### 最推荐的第一次提问模板（只读分析）

```
请说明当前目录下有哪些文件，只做分析，不要修改任何文件。
```

这个提问的好处：
- **安全**：AI 只看不说，不会改你的代码
- **验证**：能确认 OpenCode 和 DeepSeek 是否正常连通
- **熟悉**：让你看看 AI 是怎么理解项目结构的

---

## 课堂建议操作顺序

如果你的课堂时间有限，建议按照这个顺序操作（总共约 30~40 分钟）：

| 步骤 | 内容 | 预计时间 |
|------|------|----------|
| 1 | 注册 DeepSeek 并创建 API Key | 5 分钟 |
| 2 | 安装 Git（检查是否已有） | 3 分钟 |
| 3 | 安装 Node.js | 5 分钟 |
| 4 | 安装 VS Code + 插件 | 5 分钟 |
| 5 | 安装 OpenCode CLI | 3 分钟 |
| 6 | 启动 OpenCode，连接 DeepSeek | 5 分钟 |
| 7 | 选择模型，做第一个只读提问 | 5 分钟 |
| 8 | 自由练习 | 剩余时间 |

> 💡 **建议课前提早完成第 1~5 步**，因为下载安装需要联网，课堂上如果网络拥堵会影响进度。

---

## 最小验收清单

完成配置后，逐项打勾 ✓：

| 编号 | 检查项 | 验证命令 |
|------|--------|----------|
| ☐ | Git 安装正常 | `git --version` |
| ☐ | Node.js 安装正常 | `node --version` 和 `npm --version` |
| ☐ | OpenCode CLI 安装正常 | `opencode --version` |
| ☐ | VS Code 安装正常 | 能在开始菜单找到 VS Code |
| ☐ | DeepSeek 账号已注册 | 能登录 platform.deepseek.com |
| ☐ | API Key 已创建 | 在 API Keys 页面看到 Active 状态的 Key |
| ☐ | OpenCode 已连接 DeepSeek | 在 OpenCode 中执行 `/status` 显示已连接 |
| ☐ | 模型已选择 | `/status` 显示当前模型为 `deepseek-v4-pro` |
| ☐ | 第一个只读提问成功 | AI 正确回答了项目文件列表 |

---

## 常见问题排查

### 课堂最常见错误

| 问题 | 原因 | 解决办法 |
|------|------|----------|
| **`node` 不是命令** | Node.js 没装好，或 PATH 没生效 | 重启终端；如果还不行，卸载 Node.js 重装，安装时勾选"Add to PATH" |
| **`npm` 能显示，`opencode` 找不到** | npm 全局包安装目录不在 PATH 里 | 手动把 `%AppData%\npm` 加到环境变量 PATH 中，重启终端 |
| **`npm install -g opencode-ai` 报错（ERR!）** | 网络问题、权限问题 | 检查网络；以管理员身份运行 PowerShell；或者等一会儿再试 |
| **`/connect` 后找不到 DeepSeek** | 输入搜索词不对 | 输入 `DeepSeek`（大小写不敏感），用方向键选中 |
| **连接成功但提问没反应 / 报错** | API Key 无效或余额不足 | 检查 Key 是否复制完整；登录 DeepSeek 平台检查余额 |
| **粘贴 API Key 没反应** | Windows Terminal 粘贴方式不对 | **右键点击**终端窗口即可粘贴，不是 Ctrl+V |
| **AI 回答很慢** | 网络延迟或 DeepSeek 服务繁忙 | 等一下再试，通常 5~30 秒内会有响应 |
| **`/models` 没有 `deepseek-v4-pro`** | 模型列表未刷新 | 再执行一次 `/models`；或者先用 `deepseek-chat` |

### 其他问题

**Q：提示"磁盘空间不足"**
A：Node.js 和 VS Code 加起来不到 1GB，Git 不到 200MB，一般不会空间不足。如果 C 盘确实满了，可以把项目文件放在 D 盘或其他盘操作。

**Q：PowerShell 执行策略报错**
A：如果提示"因为在此系统上禁止运行脚本"，以管理员身份运行 PowerShell，执行：

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Q：VS Code 终端里字体太小**
A：按 `Ctrl +`（加号）放大，`Ctrl -`（减号）缩小。

**Q：一个 API Key 能在多台电脑上用吗？**
A：可以。API Key 跟账户走，不跟电脑走。你可以在自己的笔记本和实验室电脑上用同一个 Key，**但不要分享给同学**。每人注册自己的账号。

---

## 补充说明

### 关于 WSL（Windows Subsystem for Linux）

本文档全程基于 **Windows 11 原生环境**（PowerShell + Node.js + VS Code）进行操作。对于课堂来说，原生环境完全够用。

但有一个情况可以考虑后续改用 WSL：**如果发现 OpenCode 在 Windows 原生终端中出现偶尔的兼容性问题**（比如某些命令行为与 macOS/Linux 不一致、文件路径格式问题等），可以后续安装 WSL：

```
wsl --install
```

然后**在 WSL 内部**（Ubuntu 环境）重新安装 Node.js、OpenCode 等工具。操作步骤与本指南基本一致，只是终端环境变成了 Linux 命令行。

> **课堂现阶段不需要装 WSL。** 先把本文档的步骤走通，后续有需要再装。

### 使用建议

- **课后练习**：建议用自己的笔记本熟悉环境，不要只在实验室电脑上操作
- **作业提交**：OpenCode + DeepSeek 都可以用来辅助完成作业，但**请理解 AI 生成的每一行代码**，这是这门课的核心理念
- **遇到问题**：先看上面的"常见问题排查"，解决不了的在班级群提问，描述清楚"你执行了什么命令、看到了什么报错"

---

© 城院 VIBECODING 课程
