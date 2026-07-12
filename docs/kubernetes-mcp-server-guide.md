# Kubernetes MCP Server 使用导览

## 适用目标

这份文档用于了解和试用 `kubernetes-mcp-server`，让 Agent 能通过 MCP 查看 Kubernetes 或 OpenShift 集群信息，并在明确授权后执行有限的集群操作。

请注意：本课程项目的基础要求仍然是前后端分离、本地启动、连接 MySQL，不要求部署到 Kubernetes。这份导览是进阶参考，不改变当前项目“不引入 Docker / K8S、本地运行”的开发边界。

完成阅读后你应该知道：

1. `kubernetes-mcp-server` 能做什么，不能随便做什么。
2. 如何用只读模式把 Agent 连接到已有 Kubernetes 集群。
3. 如何在 OpenCode 里配置 Kubernetes MCP。
4. 如何用自然语言让 Agent 查看命名空间、Pod、事件、日志。
5. 需要修改集群资源时，如何降低误操作风险。

## 一、它是什么

`kubernetes-mcp-server` 是一个面向 Kubernetes / OpenShift 的 MCP Server。Agent 通过它可以调用 Kubernetes API，完成集群观察、排障和资源管理。

典型调用链路：

```text
OpenCode / Agent
  -> kubernetes-mcp-server
  -> kubeconfig 指向的 Kubernetes API Server
  -> Kubernetes / OpenShift 集群
```

它不是课程项目运行必需组件。只有当你已经有 Kubernetes 集群，或者教师安排了云原生扩展实验时，才需要继续配置。

## 二、安全约定

Kubernetes MCP 的风险比 MySQL MCP 更高，因为它可能影响整个集群。请先遵守这些规则：

- 初次接入必须使用 `--read-only`。
- 不要把管理员 kubeconfig 直接交给 Agent。
- 优先创建专用 ServiceAccount，并只授予只读或命名空间级权限。
- 不要让 Agent 读取 `Secret`、云厂商凭证、生产命名空间里的敏感资源。
- 让 Agent 修改资源前，必须先要求它说明计划、目标 namespace、资源名和预期变更。
- 不要在生产集群、他人共享集群、学校公共集群上测试写操作。

## 三、前置条件

你需要先具备：

- 一个已经可用的 Kubernetes 或 OpenShift 集群。
- 本机已安装并配置 `kubectl`。
- 本机已安装 Node.js 和 npm，方便通过 `npx` 启动 MCP Server。
- 当前用户有权限创建 ServiceAccount 和 RBAC，或者教师已经提供了专用 kubeconfig。

验证 `kubectl`：

```powershell
kubectl version --client
kubectl config current-context
kubectl get namespaces
```

如果这些命令无法成功执行，请先完成 Kubernetes / OpenShift 课堂环境配置，再继续配置 MCP。

## 四、先用帮助命令确认 MCP Server 可运行

在 PowerShell 中执行：

```powershell
npx -y kubernetes-mcp-server@latest --help
```

能看到参数说明，说明包可以下载并运行。常用参数如下：

| 参数 | 用途 | 建议 |
|---|---|---|
| `--read-only` | 只读模式，禁止写操作 | 初次接入必须使用 |
| `--kubeconfig <path>` | 指定 kubeconfig 文件 | 推荐使用专用只读 kubeconfig |
| `--disable-destructive` | 禁用删除、更新等破坏性操作 | 非只读模式下建议开启 |
| `--disable-multi-cluster` | 禁用多集群，只使用当前 context | 学生练习建议开启 |
| `--toolsets` | 控制启用的工具集合 | 默认启用 `core,config` 已够用 |
| `--list-output` | 设置列表输出格式，如 `table` 或 `yaml` | 默认 `table` 适合阅读 |

## 五、推荐方案：创建只读 ServiceAccount

如果教师已经给你提供了专用 kubeconfig，可以跳过本节，直接看“配置 OpenCode”。

下面命令用于创建一个只读账号。它适合学习和排障观察，不适合部署或修改资源。

### 1. 创建命名空间和 ServiceAccount

```powershell
kubectl create namespace mcp
kubectl create serviceaccount mcp-viewer -n mcp
```

### 2. 授予只读权限

集群级只读：

```powershell
kubectl create clusterrolebinding mcp-viewer-crb `
  --clusterrole=view `
  --serviceaccount=mcp:mcp-viewer
```

如果只允许查看某个 namespace，例如 `default`，可以改用命名空间级 RoleBinding：

```powershell
kubectl create rolebinding mcp-viewer-rb `
  --role=view `
  --serviceaccount=mcp:mcp-viewer `
  -n default
```

验证权限：

```powershell
kubectl auth can-i list pods --as=system:serviceaccount:mcp:mcp-viewer --all-namespaces
```

如果返回 `yes`，说明集群级只读权限已生效。如果你只做 namespace 级授权，验证时去掉 `--all-namespaces` 并加 `-n default`。

### 3. 生成临时 token

```powershell
$TOKEN = kubectl create token mcp-viewer --duration=2h -n mcp
```

这个 token 有有效期。过期后需要重新生成并更新 kubeconfig。

### 4. 生成专用 kubeconfig

下面命令会生成 `$HOME\.kube\mcp-viewer.kubeconfig`。它只包含 `mcp-viewer` 这个 ServiceAccount 的凭证。

```powershell
$KUBECONFIG_FILE = "$HOME\.kube\mcp-viewer.kubeconfig"
$API_SERVER = kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'
$CA_FILE = kubectl config view --minify -o jsonpath='{.clusters[0].cluster.certificate-authority}'
$TEMP_CA_CREATED = $false

if ([string]::IsNullOrWhiteSpace($CA_FILE)) {
  $CA_DATA = kubectl config view --minify --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}'
  $CA_FILE = "$env:TEMP\k8s-ca-$PID.crt"
  [IO.File]::WriteAllBytes($CA_FILE, [Convert]::FromBase64String($CA_DATA))
  $TEMP_CA_CREATED = $true
}

kubectl config --kubeconfig="$KUBECONFIG_FILE" set-cluster mcp-viewer-cluster `
  --server="$API_SERVER" `
  --certificate-authority="$CA_FILE" `
  --embed-certs=true

kubectl config --kubeconfig="$KUBECONFIG_FILE" set-credentials mcp-viewer `
  --token="$TOKEN"

kubectl config --kubeconfig="$KUBECONFIG_FILE" set-context mcp-viewer-context `
  --cluster=mcp-viewer-cluster `
  --user=mcp-viewer

kubectl config --kubeconfig="$KUBECONFIG_FILE" use-context mcp-viewer-context

if ($TEMP_CA_CREATED) {
  Remove-Item $CA_FILE
}
```

验证专用 kubeconfig：

```powershell
kubectl --kubeconfig="$HOME\.kube\mcp-viewer.kubeconfig" get pods -A
```

## 六、配置 OpenCode

推荐先把 kubeconfig 路径设置成当前 PowerShell 窗口环境变量：

```powershell
$env:KUBECONFIG="$HOME\.kube\mcp-viewer.kubeconfig"
```

然后在项目根目录创建或编辑 `opencode.json`：

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

为了避免误提交本地配置，建议把 `opencode.json` 加入 `.git/info/exclude`：

```powershell
Add-Content .git\info\exclude "opencode.json"
```

启动 OpenCode：

```powershell
opencode
```

进入 OpenCode 后先问：

```text
请使用 kubernetes_readonly MCP 工具，读取当前 Kubernetes context 和 namespaces。只允许查询，不要修改任何资源。
```

再问：

```text
请使用 kubernetes_readonly MCP 工具，查看 default namespace 下的 pods，并按 Running、Pending、Failed 分类说明。
```

如果 Agent 能返回 namespace 或 Pod 信息，说明连接成功。

## 七、常用导览问法

以下问法适合只读模式：

```text
请使用 kubernetes_readonly MCP 工具，列出所有 namespace，并指出哪些 namespace 看起来是系统命名空间。
```

```text
请使用 kubernetes_readonly MCP 工具，查看 default namespace 最近的 warning events，并按可能原因分类。
```

```text
请使用 kubernetes_readonly MCP 工具，查看某个 Pod 的最近 100 行日志，并总结错误线索。不要输出完整日志，除非我要求。
```

```text
请使用 kubernetes_readonly MCP 工具，检查某个 Deployment 的 replicas、availableReplicas、selector 和关联 Pod 状态。
```

```text
请使用 kubernetes_readonly MCP 工具，做一次集群健康检查，只总结异常项和建议下一步排查命令。
```

如果你启用了 Helm toolset，可以问：

```text
请使用 Kubernetes MCP 的 helm 工具，列出当前集群里的 Helm releases。只读查看，不要安装或卸载。
```

## 八、Toolsets 怎么选

`kubernetes-mcp-server` 支持按 toolset 控制功能范围。默认启用 `config` 和 `core`，一般已经够学生练习使用。

| Toolset | 作用 | 是否推荐学生默认开启 |
|---|---|---|
| `config` | 查看和管理 kubeconfig 相关信息 | 默认开启 |
| `core` | Pod、事件、通用资源等核心 Kubernetes 操作 | 默认开启 |
| `helm` | Helm release 和 chart 操作 | 有 Helm 课程时再开启 |
| `tekton` | Tekton Pipeline / Task 操作 | 有 Tekton 环境时再开启 |
| `kiali` | Istio / Kiali 观测相关操作 | 有服务网格环境时再开启 |
| `kubevirt` | KubeVirt 虚拟机相关操作 | 有 KubeVirt 环境时再开启 |
| `kcp` | kcp workspace 多租户相关操作 | 一般不用 |

只启用核心工具：

```json
"command": [
  "npx",
  "-y",
  "kubernetes-mcp-server@latest",
  "--read-only",
  "--toolsets",
  "core,config"
]
```

启用 Helm：

```json
"command": [
  "npx",
  "-y",
  "kubernetes-mcp-server@latest",
  "--read-only",
  "--toolsets",
  "core,config,helm"
]
```

## 九、需要修改资源时怎么做

只有在隔离的学习集群、教师允许的 namespace、明确知道后果时，才考虑写操作。

### 1. 先改权限，不要直接用管理员 kubeconfig

推荐创建一个只允许操作单个 namespace 的 ServiceAccount。例如只允许 Agent 在 `sandbox` namespace 里创建和修改 Deployment / Service / ConfigMap：

```powershell
kubectl create namespace sandbox
kubectl create serviceaccount mcp-operator -n sandbox
```

创建 `mcp-operator-role.yaml`：

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: mcp-operator-role
  namespace: sandbox
rules:
  - apiGroups: [""]
    resources: ["pods", "services", "configmaps"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
  - apiGroups: [""]
    resources: ["pods/log"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
```

应用 RBAC：

```powershell
kubectl apply -f mcp-operator-role.yaml
kubectl create rolebinding mcp-operator-rb `
  --role=mcp-operator-role `
  --serviceaccount=sandbox:mcp-operator `
  -n sandbox
```

再按前面的 token 和 kubeconfig 步骤，为 `mcp-operator` 生成专用 kubeconfig。

### 2. OpenCode 写模式配置

写模式不要加 `--read-only`。如果你只想阻止删除等高风险操作，可以保留 `--disable-destructive`，但它也可能限制部分更新类操作。需要完整写入能力时，应该依靠 RBAC 限制范围，而不是交给管理员权限。

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "kubernetes_sandbox": {
      "type": "local",
      "command": [
        "npx",
        "-y",
        "kubernetes-mcp-server@latest",
        "--disable-multi-cluster",
        "--toolsets",
        "core,config"
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

### 3. 写操作提示词模板

先让 Agent 给出计划：

```text
请使用 kubernetes_sandbox MCP 工具，准备在 sandbox namespace 创建一个 nginx Deployment 和 Service。
先输出你计划创建或修改的资源清单、命名空间、风险点和回滚方式，不要立刻执行。
```

确认后再执行：

```text
确认执行。执行后请查询 Deployment、Service 和 Pod 状态，证明变更已经生效。
```

回滚前也先确认：

```text
请先说明你准备回滚哪些 Kubernetes 资源，以及执行后会影响什么。等我确认后再操作。
```

## 十、排障清单

### 1. `kubectl` 能用，MCP 不能用

检查：

- `opencode.json` 是否在项目根目录。
- `KUBECONFIG` 环境变量是否指向存在的文件。
- OpenCode 是否在设置环境变量的同一个 PowerShell 窗口启动。
- `npx -y kubernetes-mcp-server@latest --help` 是否能正常输出。

### 2. 提示权限不足

用 `kubectl auth can-i` 检查 ServiceAccount 权限：

```powershell
kubectl auth can-i list pods --as=system:serviceaccount:mcp:mcp-viewer --all-namespaces
```

如果返回 `no`，说明 RBAC 没有正确绑定，或者你正在访问未授权 namespace。

### 3. Token 过期

重新生成 token：

```powershell
$TOKEN = kubectl create token mcp-viewer --duration=2h -n mcp
kubectl config --kubeconfig="$HOME\.kube\mcp-viewer.kubeconfig" set-credentials mcp-viewer --token="$TOKEN"
```

然后重启 OpenCode。

### 4. Agent 看到了多个集群

学生练习建议加上：

```text
--disable-multi-cluster
```

并确认 kubeconfig 只有课堂需要的 context。

### 5. 不希望 Agent 访问 Secret

只读 RBAC 的内置 `view` 角色通常不会授予读取 Secret 的权限。更严格的场景可以使用 `kubernetes-mcp-server` 的 TOML 配置拒绝特定资源类型，例如：

```toml
read_only = true
toolsets = ["core", "config"]

[[denied_resources]]
group = ""
version = "v1"
kind = "Secret"
```

再用 `--config` 启动：

```powershell
npx -y kubernetes-mcp-server@latest --config "$HOME\.config\kubernetes-mcp-server\config.toml"
```

## 十一、建议记录到 agent-log.md

如果课堂要求记录 Agent 使用过程，可以记录：

1. 使用的集群环境：本地实验集群、教师提供集群或云厂商练习集群。
2. 是否使用专用 ServiceAccount。
3. 是否启用 `--read-only`。
4. Agent 查询了哪些资源。
5. 如果执行了写操作，记录变更前计划、确认过程、执行结果和回滚方式。

不要记录 kubeconfig 内容、token、证书、真实集群地址或任何密码。

## 十二、参考资料

- `kubernetes-mcp-server` npm 包：https://www.npmjs.com/package/kubernetes-mcp-server
- Kubernetes MCP Server GitHub：https://github.com/containers/kubernetes-mcp-server
- Kubernetes MCP Server 配置参考：https://github.com/containers/kubernetes-mcp-server/blob/main/docs/configuration.md
- Kubernetes MCP Server Kubernetes 接入指南：https://github.com/containers/kubernetes-mcp-server/blob/main/docs/getting-started-kubernetes.md
- OpenCode MCP 配置文档：https://opencode.ai/docs/mcp-servers/
- Kubernetes RBAC 官方文档：https://kubernetes.io/docs/reference/access-authn-authz/rbac/
