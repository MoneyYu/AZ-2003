# AZ-2003｜Azure Container Apps Portal Demo — **全整合版 Runbook**

> **適用對象**：手動用 Azure Portal 建立所有資源，展示 Azure Container Apps 的完整功能。
>
> **Demo 時間預估**：90–120 分鐘（完整版）；45–60 分鐘（精簡版只做基礎 + 4 個必選）

---

## 📋 Demo 架構總覽

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Azure Container Apps Demo                        │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │               Container Apps Environment                          │  │
│  │                    aca-az2003-demo-env                            │  │
│  │  ┌────────────────┐    ┌─────────────────┐   ┌────────────────┐  │  │
│  │  │   fubon-web    │    │ fubon-quote-api │   │ fubon-audit-job│  │  │
│  │  │  External ☁️   │───▶│  Internal 🔒    │   │   Manual 📋    │  │  │
│  │  │   Port 3000    │Dapr│   Port 8000     │   │                │  │  │
│  │  │ Dapr: web      │    │ Dapr: api       │   │                │  │  │
│  │  └────────────────┘    └─────────────────┘   └────────────────┘  │  │
│  │          │                     ▲                                  │  │
│  │  ┌───────┴─────────────────────┴──────────────────────────────┐  │  │
│  │  │                  Azure Files Volume                         │  │  │
│  │  │              /mnt/files (persistent)                        │  │  │
│  │  └────────────────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│  ┌──────────────────┐                                                   │
│  │       ACR        │  fubon-web / fubon-quote-api / fubon-audit-job   │
│  │ acraz2003<random>│  images                                          │
│  └──────────────────┘                                                   │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## ✅ ACA 功能展示清單

| # | 功能 | 展示重點 | 預估時間 |
|---|------|---------|---------|
| 1 | **Ingress** | External vs Internal、FQDN、TLS termination | 5 min |
| 2 | **Dapr** | Service Invocation、Sidecar、app-id | 10 min |
| 3 | **Revisions** | Immutable snapshot、revision-scope changes | 5 min |
| 4 | **Traffic Split** | Blue/Green、A/B testing、權重分配 | 10 min |
| 5 | **Scale** | HTTP concurrency、scale-to-zero、KEDA | 10 min |
| 6 | **Secrets** | secretRef、不改 code 改設定 | 5 min |
| 7 | **Volume** | Azure Files persistent mount | 10 min |
| 8 | **Jobs** | Manual/Schedule/Event trigger | 10 min |
| 9 | **Console** | 即時 debug、執行命令 | 3 min |
| 10 | **Logs** | Log Analytics、即時查看 | 5 min |

---

## 📦 Demo 物件命名（固定命名，方便講解）

| 資源類型 | 名稱 | 說明 |
|---------|------|------|
| Resource Group | `rg-az2003-aca-demo` | 所有資源集中管理 |
| Log Analytics | `la-az2003-demo` | ACA logs 儲存 |
| ACR | `acraz2003<你的名字縮寫>` | 容器映像庫 |
| Storage Account | `stfubon<MMddHHmmss>` | Volume 用 |
| File Share | `fubonshare` | 持久化儲存 |
| Environment | `aca-az2003-demo-env` | ACA 執行環境 |
| Container App | `fubon-web` | 前端 UI（External） |
| Container App | `fubon-quote-api` | 報價 API（Internal） |
| Container App Job | `fubon-audit-job` | 審核批次工作 |

---

## 🚀 Part A：基礎建設（Portal + 本機 Docker）

### A1. 建立 Resource Group

**Portal 路徑**
```
Azure Portal → Resource groups → Create
```

**設定**
| 欄位 | 值 |
|-----|-----|
| Subscription | 你的訂閱 |
| Resource group | `rg-az2003-aca-demo` |
| Region | East Asia（或離你最近的區域） |

**💬 講解重點（10 秒）**
> RG 是這次 Demo 的「資源邊界」，Demo 結束一鍵刪除就清理乾淨。

---

### A2. 建立 Log Analytics Workspace

**Portal 路徑**
```
Azure Portal → Log Analytics workspaces → Create
```

**設定**
| 欄位 | 值 |
|-----|-----|
| Resource group | `rg-az2003-aca-demo` |
| Name | `la-az2003-demo` |
| Region | 同 RG |

**💬 講解重點（10 秒）**
> ACA Environment 會用這個 workspace 來存 logs，待會可以直接在 Portal 查看 container logs 和 job 執行結果。

---

### A3. 建立 Azure Container Registry（ACR）

**Portal 路徑**
```
Azure Portal → Container registries → Create
```

**設定**
| 欄位 | 值 |
|-----|-----|
| Resource group | `rg-az2003-aca-demo` |
| Registry name | `acraz2003<你的名字>` |
| Location | 同 RG |
| SKU | Basic |

**💬 講解重點（15 秒）**
> ACR 是 Azure 原生的容器映像庫，等等我們會把三個服務的 image push 上去，ACA 直接從這裡拉取。

---

### A4. Build & Push 三個 Images

> ⚠️ 這一步建議用**本機 Docker + az CLI**，因為 build/push 的過程很適合展示。

**開啟終端機（PowerShell 或 Bash），進入 demo 專案目錄**

```powershell
# 切換到 demo 專案目錄
cd "c:\Users\tzyu\Source\Repos\AZ-2003\DEMO\20260114-Fubon\demo\az2003-aca-demo-fubon\src"

# 或者用 Tailwind 版本
# cd "c:\Users\tzyu\Source\Repos\AZ-2003\DEMO\20260114-Fubon\demo\az2003-aca-demo-fubon-tailwind\src"
```

**ACR 登入**
```powershell
# 設定你的 ACR 名稱
$ACR_NAME = "acraz2003<你的名字>"

# 登入 ACR
az acr login -n $ACR_NAME

# 取得 ACR login server
$ACR_SERVER = az acr show -n $ACR_NAME --query loginServer -o tsv
Write-Host "ACR Server: $ACR_SERVER"
```

**Build & Push**
```powershell
# Build images
docker build -t "$ACR_SERVER/fubon-web:1.0.0" ./web
docker build -t "$ACR_SERVER/fubon-quote-api:1.0.0" ./api
docker build -t "$ACR_SERVER/fubon-audit-job:1.0.0" ./job

# Push images
docker push "$ACR_SERVER/fubon-web:1.0.0"
docker push "$ACR_SERVER/fubon-quote-api:1.0.0"
docker push "$ACR_SERVER/fubon-audit-job:1.0.0"
```

**驗證（Portal）**
```
ACR → Repositories → 應該看到三個 repo
```

**💬 講解重點（30 秒）**
> 我們用 Dockerfile 把三個服務打包成容器映像：
> - `fubon-web`：Node.js 前端 UI
> - `fubon-quote-api`：Python FastAPI 報價計算
> - `fubon-audit-job`：批次審核腳本
>
> Push 完後可以在 ACR Repositories 看到這三個 image。

---

### A5. 建立 Container Apps Environment

**Portal 路徑**
```
Azure Portal → Container Apps environments → Create
```

**設定**
| Tab | 欄位 | 值 |
|-----|------|-----|
| Basics | Environment name | `aca-az2003-demo-env` |
| Basics | Region | 同 RG |
| Monitoring | Log Analytics workspace | 選 `la-az2003-demo` |

**💬 講解重點（20 秒）**
> Container Apps Environment 是 ACA 的「安全邊界」：
> - 同一個 Environment 內的 Apps 共享 VNet boundary
> - Internal ingress 的服務只能被同 Environment 的服務存取
> - Dapr 的 service discovery 也在 Environment 範圍內運作

---

## 🌐 Part B：部署 Container Apps

### B1. 部署 `fubon-quote-api`（Internal Ingress + Dapr）

**Portal 路徑**
```
Azure Portal → Container Apps → Create
```

**設定**
| Tab | 欄位 | 值 |
|-----|------|-----|
| Basics | Container app name | `fubon-quote-api` |
| Basics | Container Apps Environment | `aca-az2003-demo-env` |
| Container | Image source | Azure Container Registry |
| Container | Registry | 選你的 ACR |
| Container | Image | `fubon-quote-api` |
| Container | Image tag | `1.0.0` |
| Ingress | Enable ingress | ✅ |
| Ingress | Ingress traffic | **Accepting traffic from anywhere within the Container Apps Environment** (Internal) |
| Ingress | Target port | `8000` |
| Dapr | Enable Dapr | ✅ |
| Dapr | App ID | `fubon-quote-api` |
| Dapr | App port | `8000` |
| Dapr | Protocol | HTTP |

**Environment Variables（在 Container tab）**
| Name | Value |
|------|-------|
| `APP_VERSION` | `1.0.0` |
| `DEPLOYMENT_LABEL` | `blue` |
| `BASE_RATE` | `0.0026` |
| `PRICING_FACTOR` | `1.00` |

**💬 講解重點（30 秒）**
> 這是報價計算的後端 API：
> - **Internal Ingress**：只允許同一個 Environment 內的服務存取，外部無法直接呼叫
> - **Dapr 啟用**：設定 app-id 後，其他服務可以用 `http://localhost:3500/v1.0/invoke/fubon-quote-api/method/...` 呼叫

---

### B2. 部署 `fubon-web`（External Ingress + Dapr）

**Portal 路徑**
```
Azure Portal → Container Apps → Create
```

**設定**
| Tab | 欄位 | 值 |
|-----|------|-----|
| Basics | Container app name | `fubon-web` |
| Basics | Container Apps Environment | `aca-az2003-demo-env` |
| Container | Image source | Azure Container Registry |
| Container | Registry | 選你的 ACR |
| Container | Image | `fubon-web` |
| Container | Image tag | `1.0.0` |
| Ingress | Enable ingress | ✅ |
| Ingress | Ingress traffic | **Accepting traffic from anywhere** (External) |
| Ingress | Target port | `3000` |
| Dapr | Enable Dapr | ✅ |
| Dapr | App ID | `fubon-web` |
| Dapr | App port | `3000` |
| Dapr | Protocol | HTTP |

**Environment Variables（在 Container tab）**
| Name | Value |
|------|-------|
| `APP_VERSION` | `1.0.0` |
| `DEPLOYMENT_LABEL` | `blue` |
| `DAPR_ENABLED` | `true` |
| `QUOTE_API_APP_ID` | `fubon-quote-api` |

**💬 講解重點（30 秒）**
> 這是使用者看到的前端 UI：
> - **External Ingress**：開啟後 ACA 自動提供 HTTPS FQDN，不需要額外設定 Load Balancer 或 Public IP
> - **Dapr 呼叫**：web 透過 Dapr sidecar 呼叫 `fubon-quote-api`，不需要知道對方的 IP 或 FQDN

---

### B3. 驗證部署

**取得 FQDN**
```
Container Apps → fubon-web → Overview → Application Url
```

**測試**
1. 開啟瀏覽器，貼上 FQDN
2. 按「版本資訊」→ 應該看到 version/revision/label
3. 按「產生報價」→ 應該看到報價結果

---

## 🎯 Part C：展示 ACA 功能

### C1. 功能展示 1：Ingress（External vs Internal）

**Portal 路徑**
```
Container Apps → fubon-web → Ingress
Container Apps → fubon-quote-api → Ingress
```

**你要展示的畫面**
- `fubon-web`：Traffic = **Accepting traffic from anywhere**
- `fubon-quote-api`：Traffic = **Limited to Container Apps Environment**

**💬 講解重點（45 秒）**
> ACA Ingress 提供三種模式：
> 1. **External**：對外開放，自動獲得 HTTPS FQDN + TLS termination
> 2. **Internal**：僅 Environment 內可存取（適合微服務間通訊）
> 3. **Disabled**：不開放任何網路存取
>
> 你不需要額外設定 Load Balancer、Public IP、或 SSL 憑證，ACA 全部幫你處理。

---

### C2. 功能展示 2：Dapr（Service Invocation）

**在 UI 按「產生報價」，觀察 JSON 輸出**

```json
{
  "via": "dapr",
  "web": { "version": "1.0.0", "revision": "...", "label": "blue" },
  "quote": { ... }
}
```

**💬 講解重點（60 秒）**
> Dapr 是 ACA 內建的分散式應用程式執行階段：
>
> **運作原理**：
> 1. 啟用 Dapr 後，ACA 在每個 App replica 旁邊注入一個 Sidecar
> 2. 你的程式呼叫 `http://localhost:3500/v1.0/invoke/<app-id>/method/<path>`
> 3. Sidecar 自動做 service discovery、負載均衡、mTLS、retry
>
> **為什麼用 Dapr？**
> - 程式碼只寫「我要呼叫哪個服務」，不寫具體 IP/FQDN
> - 服務擴縮、重新部署、換實例，呼叫端程式碼不用改
> - 自動 mTLS 加密服務間通訊

**如果要展示 Dapr vs Direct URL 的差異**

把 `fubon-web` 的 `DAPR_ENABLED` 改成 `false`：
```
Container Apps → fubon-web → Revisions → Create new revision
→ 修改 Environment variable：DAPR_ENABLED = false
```

再按「產生報價」，會看到 `"via": "direct"`（但會失敗，因為 direct URL 找不到 internal service）

---

### C3. 功能展示 3：Revisions（不可變快照）

**Portal 路徑**
```
Container Apps → fubon-web → Revisions and replicas
```

**你要展示的畫面**
- 目前有一個 active revision
- 點進去看 revision 的 Container / Env vars 設定

**💬 講解重點（30 秒）**
> Revision 是 Container App 的「不可變快照」：
> - 每次你改 container image、env vars、secrets reference、volume mounts，就會產生新 revision
> - 舊 revision 不會被修改，可以隨時回滾
> - ACA 最多保留 100 個 revisions

---

### C4. 功能展示 4：Traffic Split（Blue/Green）

**Step 1：啟用 Multiple revision mode**
```
Container Apps → fubon-web → Revisions and replicas
→ 將 Revision mode 改為 "Multiple: Several revisions active simultaneously"
```

**Step 2：建立 Green 版本**

先 build & push 新版本（或直接改 env var 也會產生新 revision）：
```powershell
# 方法 A：push 新 tag
docker build -t "$ACR_SERVER/fubon-web:1.0.1" ./web
docker push "$ACR_SERVER/fubon-web:1.0.1"

# 然後在 Portal 建新 revision 用 1.0.1
```

或者：
```
Container Apps → fubon-web → Revisions → Create new revision
→ 修改 Environment variables：
   APP_VERSION = 1.0.1
   DEPLOYMENT_LABEL = green
```

**Step 3：設定 Traffic Split**
```
Container Apps → fubon-web → Revisions and replicas
→ Traffic 欄位：
   Blue revision: 80%
   Green revision: 20%
→ Save
```

**Step 4：驗證**

重複按 UI 的「版本資訊」，你會看到：
- 約 80% 的請求返回 `"label": "blue"`
- 約 20% 的請求返回 `"label": "green"`

**💬 講解重點（45 秒）**
> Traffic Split 讓你做 Blue/Green 或 A/B testing：
> - 設定權重（百分比）把流量導向不同 revision
> - 可以先導 10% 流量到新版本，驗證沒問題再逐步增加
> - 如果新版本有問題，把權重調回 100% 給舊版本就能即時回滾

---

### C5. 功能展示 5：Scale（HTTP Concurrency + Scale-to-Zero）

**Step 1：設定 Scale rule**
```
Container Apps → fubon-web → Scale
→ Min replicas: 0
→ Max replicas: 10
→ Add scale rule:
   Type: HTTP scaling
   Concurrent requests: 5（設低一點容易看到效果）
```

**Step 2：產生流量**

```powershell
# 取得 FQDN
$FQDN = "<your-fubon-web-fqdn>"

# 用 PowerShell 產生流量
1..300 | ForEach-Object { Invoke-WebRequest -Uri "https://$FQDN/api/version" -UseBasicParsing | Out-Null; Write-Host "." -NoNewline }
```

或用 curl（如果有裝）：
```bash
for i in {1..300}; do curl -s https://$FQDN/api/version > /dev/null; done
```

**Step 3：觀察 replicas**
```
Container Apps → fubon-web → Metrics
→ Metric: Replica Count
→ 或到 Scale 頁面看 Replicas 數量
```

**Step 4：等待 scale-to-zero**

停止流量，等幾分鐘，replicas 會降到 0。

**💬 講解重點（45 秒）**
> ACA 用 KEDA（Kubernetes Event-driven Autoscaling）驅動自動擴縮：
> - **HTTP rule**：根據並發請求數自動增減 replicas
> - **Scale-to-zero**：沒流量時 replicas 降到 0，**不收費**
> - 其他 trigger：CPU、Memory、Azure Queue、Kafka 等

---

### C6. 功能展示 6：Secrets

**Step 1：建立 Secret**
```
Container Apps → fubon-quote-api → Secrets → Add
→ Name: pricing-factor
→ Value: 1.07
```

**Step 2：修改 Environment Variable 引用 Secret**
```
Container Apps → fubon-quote-api → Revisions → Create new revision
→ Environment variables:
   PRICING_FACTOR → Source: Reference a secret → pricing-factor
```

**Step 3：驗證**

回到 UI 按「產生報價」，檢查輸出的 `factors.pricing_factor` 是否變成 `1.07`。

**💬 講解重點（30 秒）**
> Secrets 讓你安全管理敏感設定：
> - Secret 值在 Portal 不會顯示（只顯示 ***）
> - Environment variable 可以引用 secret，不用把敏感資料寫死在設定
> - 改 secret 值不會觸發新 revision（但需要 restart replicas）

---

### C7. 功能展示 7：Volume（Azure Files Persistent）

**Step 1：建立 Storage Account + File Share**
```
Azure Portal → Storage accounts → Create
→ Name: stfubon<MMddHHmmss>
→ Resource group: rg-az2003-aca-demo

Storage account → File shares → + File share
→ Name: fubonshare
→ Quota: 5 GiB
```

**Step 2：取得 Storage Account Key**
```
Storage account → Access keys → 複製 key1
```

**Step 3：在 Environment 註冊 Storage**
```
Container Apps environments → aca-az2003-demo-env → Storage → Add
→ Storage type: Azure Files
→ Storage name: fubonfiles（⚠️不要用特殊字元）
→ Storage account: 選你的 storage account
→ File share: fubonshare
→ Access key: 貼上 key
```

**Step 4：在 fubon-web 掛載 Volume**
```
Container Apps → fubon-web → Revisions → Create new revision
→ Volumes → Add:
   Volume type: Azure file volume
   Name: files-volume
   File share: fubonfiles
→ Container → Volume mounts:
   Volume name: files-volume
   Mount path: /mnt/files
```

**Step 5：驗證持久化**
```
Container Apps → fubon-web → Console
→ 選一個 replica → Connect
```

在 Console 執行：
```bash
# 寫入檔案
date >> /mnt/files/demo.log
cat /mnt/files/demo.log

# 確認檔案存在
ls -la /mnt/files/
```

然後到 Storage account → File shares → fubonshare，確認看到 `demo.log`。

**Step 6：驗證跨 revision 持久化**

再建一個新 revision（例如改一下 APP_VERSION），然後回 Console 檢查：
```bash
cat /mnt/files/demo.log  # 檔案應該還在
```

**💬 講解重點（45 秒）**
> ACA 支援三種 storage 類型：
> 1. **Container filesystem**：容器重啟就消失
> 2. **Ephemeral volume**：同 replica 內共享，replica 消失就沒了
> 3. **Azure Files volume**：持久化，跨 replica / revision 都保留
>
> Azure Files 適合：logs、config files、shared data

---

### C8. 功能展示 8：Jobs（批次工作）

**Step 1：建立 Container Apps Job**
```
Azure Portal → Container Apps Jobs → Create
```

**設定**
| Tab | 欄位 | 值 |
|-----|------|-----|
| Basics | Name | `fubon-audit-job` |
| Basics | Container Apps Environment | `aca-az2003-demo-env` |
| Basics | Job type | Manual |
| Container | Image source | Azure Container Registry |
| Container | Image | `fubon-audit-job:1.0.0` |

**Environment Variables**
| Name | Value |
|------|-------|
| `QUOTE_URL` | `http://fubon-quote-api:8000/quote?age=45&coverage=2000000&term=20` |
| `RETRIES` | `3` |

**Step 2：手動觸發 Job**
```
Container Apps Jobs → fubon-audit-job → Execution history → Run now
```

**Step 3：查看 Logs**
```
Container Apps Jobs → fubon-audit-job → Execution history
→ 點進最新的 execution → Logs
```

你應該看到類似：
```
status 200
{"age":45,"coverage":2000000,...}
job completed
```

**💬 講解重點（45 秒）**
> Container Apps Jobs 讓你執行批次工作：
> - **Manual**：手動觸發（適合 ad-hoc 任務）
> - **Schedule**：用 cron expression 定時執行
> - **Event-driven**：由 Azure Queue、Kafka 等事件觸發
>
> Job 執行完就結束，不像 App 持續運行。適合：
> - 資料處理、ETL
> - 定時報表
> - 批次審核、清理

---

### C9. 功能展示 9：Console（即時 Debug）

```
Container Apps → fubon-web → Console
→ 選 replica → Connect → /bin/sh
```

**可以展示的命令**
```bash
# 看環境變數
env | grep -E "APP_VERSION|DEPLOYMENT_LABEL|DAPR"

# 看 process
ps aux

# 看網路
curl http://localhost:3000/api/version

# 如果有掛 volume
ls -la /mnt/files/
```

**💬 講解重點（20 秒）**
> Console 讓你直接進入容器執行命令，方便即時 debug。

---

### C10. 功能展示 10：Logs

**即時 Logs**
```
Container Apps → fubon-web → Log stream
```

**Log Analytics 查詢**
```
Container Apps → fubon-web → Logs
```

**範例查詢**
```kusto
ContainerAppConsoleLogs_CL
| where ContainerAppName_s == "fubon-web"
| order by TimeGenerated desc
| take 50
```

**💬 講解重點（20 秒）**
> ACA 整合 Log Analytics，所有 container logs 自動收集。你可以用 KQL 查詢做進階分析。

---

## 🧹 Part D：清理資源

```
Azure Portal → Resource groups → rg-az2003-aca-demo → Delete resource group
```

⚠️ **Demo 結束一定要做這步**，避免持續產生費用。

---

## 📝 Demo 流程建議

### 精簡版（45-60 分鐘）
1. ✅ 基礎建設（RG, ACR, Environment）
2. ✅ 部署兩個 Apps
3. ✅ Ingress（External vs Internal）
4. ✅ Traffic Split（Blue/Green）
5. ✅ Scale（HTTP + scale-to-zero）
6. ✅ Jobs
7. 清理

### 完整版（90-120 分鐘）
上面精簡版 + 
- ✅ Dapr 原理講解
- ✅ Secrets
- ✅ Volume（Azure Files）
- ✅ Console + Logs

---

## ⚠️ 常見問題排錯

### 1. `/api/quote` 回傳 500
**可能原因**：
- `fubon-quote-api` 的 Dapr app-port 設錯（應該是 8000）
- `fubon-web` 的 `QUOTE_API_APP_ID` 與 api 的 Dapr app-id 不一致

**解法**：檢查兩邊的 Dapr 設定。

### 2. Volume mount 失敗
**可能原因**：
- Storage name 有特殊字元
- 沒有先在 Environment 註冊 storage

**解法**：確認 Environment → Storage 已經新增，且名稱用純英數字。

### 3. Traffic Split 沒有效果
**可能原因**：
- 還在 Single revision mode

**解法**：先切換到 Multiple revision mode。

### 4. Job 執行失敗
**可能原因**：
- `QUOTE_URL` 用 Dapr URL 但 job 沒有啟用 Dapr

**解法**：Job 用 internal DNS URL：`http://fubon-quote-api:8000/...`

---

## 📚 參考資料

- [Azure Container Apps Overview](https://learn.microsoft.com/azure/container-apps/overview)
- [Dapr integration with Azure Container Apps](https://learn.microsoft.com/azure/container-apps/dapr-overview)
- [Revisions in Azure Container Apps](https://learn.microsoft.com/azure/container-apps/revisions)
- [Scale in Azure Container Apps](https://learn.microsoft.com/azure/container-apps/scale-app)
- [Azure Container Apps jobs](https://learn.microsoft.com/azure/container-apps/jobs)

---

> **Last Updated**: 2026-01-14
> **Version**: 1.0.0 (Portal Demo Master Runbook)
