# AZ-2003｜Azure Container Apps 完整 Demo 指南
## 富邦保險微服務場景｜從零到完整的 ACA 功能展示

> **目標對象**：想透過 Azure Portal 手動建立資源，完整展示 Azure Container Apps 10 大功能的講師/技術人員
>
> **預計時間**：90-120 分鐘（完整版）｜45-60 分鐘（精簡版）
>
> **更新日期**：2026-01-14

---

## 📖 故事背景：富邦保險數位轉型

### 情境設定

富邦保險正在進行數位轉型，需要將現有的保險報價系統容器化並部署到雲端。這個系統包含：

1. **客戶入口網站** (`fubon-web`)：讓客戶查詢保費報價
2. **報價計算引擎** (`fubon-quote-api`)：根據年齡、保額、年期計算保費
3. **審核批次作業** (`fubon-audit-job`)：定期執行保單審核

### 業務需求

| 需求 | 說明 | 對應 ACA 功能 |
|------|------|--------------|
| 🔒 安全性 | API 不能對外暴露 | Internal Ingress |
| 🔄 無痛升級 | 新版本要能漸進式發布 | Traffic Split / Blue-Green |
| 📈 彈性擴展 | 尖峰時段自動擴展，離峰節省成本 | Scale / Scale-to-zero |
| 💾 資料持久化 | 操作記錄要保留 | Azure Files Volume |
| 🔐 機密管理 | 保費費率不寫死在程式碼 | Secrets |
| ⏰ 批次作業 | 每日審核批次 | Container Apps Jobs |

### 為什麼選擇 Azure Container Apps？

| 優點 | 說明 |
|------|------|
| ✅ **無需管理 K8s** | 不用學 kubectl、不用顧 control plane |
| ✅ **內建 Ingress** | 自動 HTTPS、TLS termination、不需額外 Load Balancer |
| ✅ **內建 Dapr** | 服務間通訊、mTLS、重試機制「打開就能用」 |
| ✅ **Scale-to-zero** | 沒流量不收費 |
| ✅ **Revision 管理** | 版本快照、一鍵回滾 |

| 缺點/限制 | 說明 |
|-----------|------|
| ⚠️ 進階控制有限 | 需要精細控制 Pod/Node 請選 AKS |
| ⚠️ GPU 支援有限 | AI/ML 重度運算建議其他服務 |
| ⚠️ Windows 容器不支援 | 僅支援 Linux 容器 |

---

## 🎯 Demo 架構圖

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    Azure Container Apps Environment                      │
│                        aca-az2003-demo-env                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌────────────────────┐   Dapr    ┌─────────────────────┐              │
│  │    fubon-web       │ ────────▶ │  fubon-quote-api    │              │
│  │                    │           │                     │              │
│  │  External ☁️ :3000 │           │  Internal 🔒 :8000  │              │
│  │  Dapr: web         │           │  Dapr: api          │              │
│  └────────┬───────────┘           └─────────────────────┘              │
│           │                                                             │
│           │                       ┌─────────────────────┐              │
│           │                       │  fubon-audit-job    │              │
│           │                       │  Manual 📋          │              │
│           │                       └─────────────────────┘              │
│           │                                                             │
│  ┌────────┴────────────────────────────────────────────────────────┐   │
│  │                  Azure Files Volume (/mnt/files)                 │   │
│  │                  持久化儲存：操作記錄、設定檔                      │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────┐
│         Azure ACR           │
│    acraz2003<random>        │
│  Images: web / api / job    │
└─────────────────────────────┘
```

---

## 📋 Demo 步驟總覽

| 階段 | Demo 順序 | 功能 | 時間 | 目的 |
|------|-----------|------|------|------|
| **基礎建設** | 1 | Resource Group | 2 min | 資源邊界 |
| | 2 | Log Analytics | 2 min | 日誌收集 |
| | 3 | ACR | 3 min | 映像儲存 |
| | 4 | Build & Push | 5 min | 容器化 |
| | 5 | Environment | 3 min | ACA 執行環境 |
| **核心部署** | 6 | Ingress (API) | 5 min | Internal 服務 |
| | 7 | Ingress (Web) | 5 min | External 入口 |
| | 8 | Dapr | 10 min | 服務間通訊 |
| **進階功能** | 9 | Revisions | 5 min | 版本管理 |
| | 10 | Traffic Split | 10 min | Blue/Green 發布 |
| | 11 | Scale | 10 min | 自動擴縮 |
| | 12 | Secrets | 5 min | 機密管理 |
| | 13 | Volume | 10 min | 持久化儲存 |
| | 14 | Jobs | 10 min | 批次作業 |
| | 15 | Console & Logs | 5 min | 偵錯工具 |
| **清理** | 16 | Cleanup | 2 min | 刪除資源 |

---

# 🔧 Part A：基礎建設

> **故事線**：我們要為富邦保險的報價系統準備雲端基礎設施。

---

## Demo 1：建立 Resource Group

### 為什麼需要？
> Resource Group 是 Azure 的資源邊界。把所有 Demo 資源放在同一個 RG，結束後一鍵刪除，乾淨俐落。

### Portal 操作
```
Azure Portal → Resource groups → Create
```

### 設定值
| 欄位 | 值 | 說明 |
|------|-----|------|
| Subscription | 你的訂閱 | 計費帳戶 |
| Resource group | `rg-az2003-aca-demo` | 命名一致方便講解 |
| Region | East Asia | 離使用者最近 |

### 講解重點（10 秒）
> 「Resource Group 是這次 Demo 的資源邊界，所有資源集中管理，Demo 結束一鍵刪除就清理乾淨，不會有殘留費用。」

### 優點
- ✅ 集中管理，易於追蹤成本
- ✅ 一鍵刪除，不留殘留資源
- ✅ 可設定 RBAC 權限控制

### 缺點
- ⚠️ 無法跨區域（需選擇主要區域）
- ⚠️ 刪除 RG 會刪除所有內含資源（需謹慎）

---

## Demo 2：建立 Log Analytics Workspace

### 為什麼需要？
> ACA 的所有容器日誌都會送到 Log Analytics，方便集中查詢和分析。這是後面展示 Logs 功能的前提。

### Portal 操作
```
Azure Portal → Log Analytics workspaces → Create
```

### 設定值
| 欄位 | 值 |
|------|-----|
| Resource group | `rg-az2003-aca-demo` |
| Name | `la-az2003-demo` |
| Region | 同 RG |

### 講解重點（10 秒）
> 「Log Analytics 是 Azure 的日誌分析服務，ACA Environment 會自動把容器 stdout/stderr 送到這裡，等會我們可以用 KQL 查詢。」

### 優點
- ✅ 集中收集所有容器日誌
- ✅ 支援 KQL 進階查詢
- ✅ 可設定警報規則

### 缺點
- ⚠️ 有資料保留成本（預設 30 天）
- ⚠️ 大量日誌會產生費用

---

## Demo 3：建立 Azure Container Registry (ACR)

### 為什麼需要？
> ACR 是 Azure 原生的容器映像庫，與 ACA 深度整合。映像存在 ACR，ACA 直接拉取，不需要額外設定認證。

### Portal 操作
```
Azure Portal → Container registries → Create
```

### 設定值
| 欄位 | 值 | 說明 |
|------|-----|------|
| Resource group | `rg-az2003-aca-demo` | |
| Registry name | `acraz2003<你的名字縮寫>` | 需全域唯一 |
| Location | 同 RG | |
| SKU | Basic | Demo 足夠 |

### 講解重點（15 秒）
> 「ACR 是 Azure 原生的容器映像庫。等等我們把三個服務的 image push 上去，ACA 會直接從這裡拉取。Basic SKU Demo 足夠，正式環境建議 Standard 以上。」

### 優點
- ✅ 與 Azure 服務深度整合
- ✅ 支援 Geo-replication（Standard 以上）
- ✅ 支援漏洞掃描（Premium）

### 缺點
- ⚠️ Basic SKU 無 Geo-replication
- ⚠️ 需要儲存空間費用

---

## Demo 4：Build & Push 三個 Images

### 為什麼需要？
> 容器化是雲原生的基礎。我們把三個服務（web、api、job）打包成容器映像，推送到 ACR。

### 本機操作（PowerShell 7）

```powershell
# 切換到 demo 專案目錄
cd "c:\Users\tzyu\Source\Repos\AZ-2003\DEMO\20260114-Fubon\demo\az2003-aca-demo-fubon\src"

# 設定變數
$ACR_NAME = "acraz2003<你的名字縮寫>"

# 登入 ACR
az acr login -n $ACR_NAME

# 取得 ACR login server
$ACR_SERVER = az acr show -n $ACR_NAME --query loginServer -o tsv
Write-Host "ACR Server: $ACR_SERVER"

# Build images（加上 ACR 前綴）
docker build -t "$ACR_SERVER/fubon-web:1.0.0" ./web
docker build -t "$ACR_SERVER/fubon-quote-api:1.0.0" ./api
docker build -t "$ACR_SERVER/fubon-audit-job:1.0.0" ./job

# Push images
docker push "$ACR_SERVER/fubon-web:1.0.0"
docker push "$ACR_SERVER/fubon-quote-api:1.0.0"
docker push "$ACR_SERVER/fubon-audit-job:1.0.0"
```

### Portal 驗證
```
ACR → Repositories → 應該看到三個 repo
```

### 講解重點（30 秒）
> 「我們用 Dockerfile 把三個服務容器化：
> - `fubon-web`：Node.js 前端 UI，讓客戶輸入資料
> - `fubon-quote-api`：Python FastAPI，計算保費
> - `fubon-audit-job`：批次腳本，執行審核
>
> Push 完後可以在 ACR Repositories 看到這三個 image。」

### 優點
- ✅ 容器化讓環境一致（開發 = 測試 = 生產）
- ✅ Image 可重複使用、版本化管理
- ✅ 不同語言/框架都能容器化

### 缺點
- ⚠️ 需要學習 Dockerfile 撰寫
- ⚠️ Image 越大，推送/拉取越慢

---

## Demo 5：建立 Container Apps Environment

### 為什麼需要？
> Environment 是 ACA 的「安全邊界」。同一個 Environment 內的服務共享 VNet、可以互相呼叫 Internal 服務、共用 Dapr 服務發現。

### Portal 操作
```
Azure Portal → Container Apps environments → Create
```

### 設定值
| Tab | 欄位 | 值 |
|-----|------|-----|
| Basics | Environment name | `aca-az2003-demo-env` |
| Basics | Region | 同 RG |
| Monitoring | Log Analytics workspace | 選 `la-az2003-demo` |

### 講解重點（20 秒）
> 「Container Apps Environment 是 ACA 的安全邊界：
> - 同一個 Environment 內的 Apps 共享 VNet boundary
> - Internal ingress 的服務只能被同 Environment 的服務存取
> - Dapr 的 service discovery 也在 Environment 範圍內運作」

### 優點
- ✅ 內建 VNet 隔離，不需自己建 VNet
- ✅ 自動整合 Log Analytics
- ✅ 多個 App 共享環境資源

### 缺點
- ⚠️ 一個 Environment 的 App 上限（目前約 100）
- ⚠️ 跨 Environment 通訊需要 External Ingress

---

# 🌐 Part B：核心部署

> **故事線**：基礎設施就緒，現在開始部署我們的微服務。

---

## Demo 6：部署 `fubon-quote-api`（Internal Ingress + Dapr）

### 為什麼這樣設計？
> 報價 API 是後端服務，不應該對外暴露。使用 Internal Ingress 讓它只能被同 Environment 的服務呼叫，符合「最小權限原則」。

### Portal 操作
```
Azure Portal → Container Apps → Create
```

### 設定值

**Basics Tab**
| 欄位 | 值 |
|------|-----|
| Container app name | `fubon-quote-api` |
| Container Apps Environment | `aca-az2003-demo-env` |

**Container Tab**
| 欄位 | 值 |
|------|-----|
| Image source | Azure Container Registry |
| Registry | 選你的 ACR |
| Image | `fubon-quote-api` |
| Image tag | `1.0.0` |

**Environment Variables**
| Name | Value | 說明 |
|------|-------|------|
| `APP_VERSION` | `1.0.0` | 版本標識 |
| `DEPLOYMENT_LABEL` | `blue` | 部署標籤（用於 Blue/Green） |
| `BASE_RATE` | `0.0026` | 基礎費率 |
| `PRICING_FACTOR` | `1.00` | 定價因子 |

**Ingress Tab**
| 欄位 | 值 | 說明 |
|------|-----|------|
| Enable ingress | ✅ | |
| Ingress traffic | **Limited to Container Apps Environment** | 🔒 Internal |
| Target port | `8000` | FastAPI 預設端口 |

**Dapr Tab**
| 欄位 | 值 | 說明 |
|------|-----|------|
| Enable Dapr | ✅ | |
| App ID | `fubon-quote-api` | Dapr 服務識別 |
| App port | `8000` | 應用程式端口 |
| Protocol | HTTP | |

### 講解重點（30 秒）
> 「這是報價計算的後端 API：
> - **Internal Ingress**：只允許同一個 Environment 內的服務存取，外部無法直接呼叫，符合安全最佳實踐
> - **Dapr 啟用**：設定 app-id 後，其他服務可以用 Dapr sidecar 呼叫，不需要知道 IP 或 FQDN」

### 優點
- ✅ Internal Ingress 天然隔離，不暴露攻擊面
- ✅ Dapr 自動 mTLS，服務間通訊加密
- ✅ 服務擴縮、IP 變化，呼叫端不用改

### 缺點
- ⚠️ Internal 服務無法從外部直接測試
- ⚠️ Dapr 有額外資源開銷（sidecar）

---

## Demo 7：部署 `fubon-web`（External Ingress + Dapr）

### 為什麼這樣設計？
> Web 是客戶入口，需要對外開放。使用 External Ingress 讓 ACA 自動提供 HTTPS FQDN，不需要額外設定 Load Balancer 或 Public IP。

### Portal 操作
```
Azure Portal → Container Apps → Create
```

### 設定值

**Basics Tab**
| 欄位 | 值 |
|------|-----|
| Container app name | `fubon-web` |
| Container Apps Environment | `aca-az2003-demo-env` |

**Container Tab**
| 欄位 | 值 |
|------|-----|
| Image source | Azure Container Registry |
| Registry | 選你的 ACR |
| Image | `fubon-web` |
| Image tag | `1.0.0` |

**Environment Variables**
| Name | Value | 說明 |
|------|-------|------|
| `APP_VERSION` | `1.0.0` | 版本標識 |
| `DEPLOYMENT_LABEL` | `blue` | 部署標籤 |
| `DAPR_ENABLED` | `true` | 啟用 Dapr 呼叫 |
| `QUOTE_API_APP_ID` | `fubon-quote-api` | 目標服務 app-id |

**Ingress Tab**
| 欄位 | 值 | 說明 |
|------|-----|------|
| Enable ingress | ✅ | |
| Ingress traffic | **Accepting traffic from anywhere** | ☁️ External |
| Target port | `3000` | Node.js 預設端口 |

**Dapr Tab**
| 欄位 | 值 |
|------|-----|
| Enable Dapr | ✅ |
| App ID | `fubon-web` |
| App port | `3000` |
| Protocol | HTTP |

### 講解重點（30 秒）
> 「這是使用者看到的前端 UI：
> - **External Ingress**：開啟後 ACA 自動提供 HTTPS FQDN，不需要額外設定 Load Balancer 或 Public IP，TLS 憑證也自動處理
> - **Dapr 呼叫**：web 透過 Dapr sidecar 呼叫 `fubon-quote-api`，不需要知道對方的 IP 或 FQDN」

### 驗證部署
```
Container Apps → fubon-web → Overview → Application Url
```

1. 開啟瀏覽器，貼上 FQDN
2. 按「版本資訊」→ 應該看到 version/revision/label
3. 按「產生報價」→ 應該看到報價結果

### 優點
- ✅ 自動 HTTPS，不需管理憑證
- ✅ 自動負載均衡
- ✅ 自動 DDoS 防護

### 缺點
- ⚠️ 無法使用自訂域名（需額外設定）
- ⚠️ External 服務有更大的攻擊面

---

## Demo 8：Dapr 服務間通訊

### 為什麼使用 Dapr？

**傳統做法（直接呼叫 URL）**
```javascript
// 程式碼需要知道具體位址
const apiUrl = "http://fubon-quote-api.internal.xxx.eastasia.azurecontainerapps.io:8000";
```

**Dapr 做法**
```javascript
// 只需要知道服務名稱（app-id）
const daprUrl = "http://localhost:3500/v1.0/invoke/fubon-quote-api/method/quote";
```

### Dapr 運作原理

```
┌──────────────────────────────────────────────────────────────────┐
│                          fubon-web Pod                           │
│  ┌─────────────────┐        ┌─────────────────────────────────┐ │
│  │   fubon-web     │───────▶│       Dapr Sidecar              │ │
│  │   Container     │ :3500  │  (自動注入、平台管理)            │ │
│  └─────────────────┘        └───────────────┬─────────────────┘ │
└──────────────────────────────────────────────┼──────────────────┘
                                               │ mTLS + Service Discovery
                                               ▼
┌──────────────────────────────────────────────────────────────────┐
│                       fubon-quote-api Pod                        │
│  ┌─────────────────────────────────┐        ┌─────────────────┐ │
│  │       Dapr Sidecar              │───────▶│ fubon-quote-api │ │
│  │                                 │ :8000  │    Container    │ │
│  └─────────────────────────────────┘        └─────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
```

### 驗證 Dapr 運作

在 UI 按「產生報價」，觀察 JSON 輸出：
```json
{
  "via": "dapr",
  "web": { "version": "1.0.0", "revision": "...", "label": "blue" },
  "quote": { ... }
}
```

### 講解重點（60 秒）
> 「Dapr 是 ACA 內建的分散式應用程式執行階段：
>
> **運作原理**：
> 1. 啟用 Dapr 後，ACA 在每個 App replica 旁邊注入一個 Sidecar
> 2. 你的程式呼叫 `http://localhost:3500/v1.0/invoke/<app-id>/method/<path>`
> 3. Sidecar 自動做 service discovery、負載均衡、mTLS、retry
>
> **為什麼用 Dapr？**
> - 程式碼只寫「我要呼叫哪個服務」，不寫具體 IP/FQDN
> - 服務擴縮、重新部署、換實例，呼叫端程式碼不用改
> - 自動 mTLS 加密服務間通訊」

### Dapr vs 直接 URL 對照表

| 面向 | 直接 URL | Dapr |
|------|----------|------|
| **耦合度** | 高（綁定 host/port） | 低（只需 app-id） |
| **服務發現** | 需自建/DNS | Sidecar 自動處理 |
| **負載均衡** | 需額外設定 | Sidecar 內建 |
| **mTLS** | 需自行設定 | 自動啟用 |
| **重試機制** | 需自行實作 | 內建 |
| **可移植性** | 依賴平台 | 跨平台一致 |
| **資源開銷** | 較小 | 多一個 Sidecar |

---

# 🚀 Part C：進階功能展示

> **故事線**：系統上線後，我們需要處理版本升級、流量控制、自動擴縮等企業級需求。

---

## Demo 9：Revisions（版本管理）

### 為什麼需要？
> 每次部署新版本，ACA 會建立一個「不可變的快照」叫做 Revision。這讓你可以隨時回滾到之前的版本，不用重新部署。

### Portal 操作
```
Container Apps → fubon-web → Revisions and replicas
```

### 展示內容
- 目前有一個 active revision
- 點進去看 revision 的 Container / Env vars 設定
- 說明 revision 名稱格式：`fubon-web--<suffix>`

### 講解重點（30 秒）
> 「Revision 是 Container App 的『不可變快照』：
> - 每次你改 container image、env vars、secrets reference、volume mounts，就會產生新 revision
> - 舊 revision 不會被修改，可以隨時回滾
> - ACA 最多保留 100 個 revisions
> - 這是實現 Blue/Green、Canary 發布的基礎」

### 會觸發新 Revision 的變更

| 變更類型 | 是否觸發 |
|----------|----------|
| Container image | ✅ |
| Environment variables | ✅ |
| Secrets reference | ✅ |
| Volume mounts | ✅ |
| CPU/Memory | ✅ |
| Scale rules | ❌ |
| Ingress 設定 | ❌ |

### 優點
- ✅ 不可變快照，安全可追溯
- ✅ 一鍵回滾，秒級恢復
- ✅ 支援多版本同時運行

### 缺點
- ⚠️ 100 個 revision 上限
- ⚠️ 每個 revision 都佔用 quota

---

## Demo 10：Traffic Split（Blue/Green 發布）

### 為什麼需要？
> 直接切換 100% 流量風險太大。Traffic Split 讓你漸進式發布：先導 10% 流量到新版本，確認沒問題再逐步增加。

### 操作步驟

#### Step 1：啟用 Multiple revision mode
```
Container Apps → fubon-web → Revisions and replicas
→ Revision mode → 選 "Multiple: Several revisions active simultaneously"
```

#### Step 2：建立 Green 版本
```
Container Apps → fubon-web → Revisions → Create new revision
→ 修改 Environment variables：
   APP_VERSION = 1.0.1
   DEPLOYMENT_LABEL = green
```

#### Step 3：設定 Traffic Split
```
Container Apps → fubon-web → Revisions and replicas
→ Traffic 欄位：
   Blue revision: 80%
   Green revision: 20%
→ Save
```

#### Step 4：驗證
重複按 UI 的「版本資訊」，觀察：
- 約 80% 的請求返回 `"label": "blue"`
- 約 20% 的請求返回 `"label": "green"`

### 講解重點（45 秒）
> 「Traffic Split 讓你做 Blue/Green 或 Canary 發布：
> - 設定權重（百分比）把流量導向不同 revision
> - 可以先導 10% 流量到新版本，觀察錯誤率、效能
> - 確認沒問題再逐步增加：10% → 30% → 50% → 100%
> - 如果新版本有問題，把權重調回 100% 給舊版本就能即時回滾」

### Blue/Green vs Canary

| 策略 | 說明 | 適用場景 |
|------|------|----------|
| **Blue/Green** | 50/50 切換，快速驗證 | 功能完整測試後 |
| **Canary** | 漸進式（5% → 10% → 25%...） | 需要觀察生產環境反應 |

### 優點
- ✅ 降低發布風險
- ✅ 即時回滾能力
- ✅ A/B 測試能力

### 缺點
- ⚠️ 多 revision 會增加資源使用
- ⚠️ 需要監控兩個版本的指標

---

## Demo 11：Scale（自動擴縮）

### 為什麼需要？
> 保險報價系統會有尖峰（早上上班時間）和離峰（凌晨）。自動擴縮讓系統在尖峰時處理更多請求，離峰時節省成本。

### 操作步驟

#### Step 1：設定 Scale rule
```
Container Apps → fubon-web → Scale
→ Min replicas: 0
→ Max replicas: 10
→ Add scale rule:
   Type: HTTP scaling
   Concurrent requests: 5（設低一點容易看到效果）
```

#### Step 2：產生流量

**PowerShell**
```powershell
$FQDN = "<your-fubon-web-fqdn>"

# 產生 300 個請求
1..300 | ForEach-Object { 
    Invoke-WebRequest -Uri "https://$FQDN/api/version" -UseBasicParsing | Out-Null
    Write-Host "." -NoNewline 
}
```

#### Step 3：觀察 replicas
```
Container Apps → fubon-web → Metrics → Metric: Replica Count
```

#### Step 4：等待 scale-to-zero
停止流量，等幾分鐘，replicas 會降到 0。

### 講解重點（45 秒）
> 「ACA 用 KEDA（Kubernetes Event-driven Autoscaling）驅動自動擴縮：
> - **HTTP rule**：根據並發請求數自動增減 replicas
> - **Scale-to-zero**：沒流量時 replicas 降到 0，**不收費**
> - 其他 trigger：CPU、Memory、Azure Queue、Kafka 等
>
> 這對成本優化非常重要：凌晨沒人用，replicas = 0，不產生費用。」

### 支援的 Scale Trigger

| Trigger | 說明 | 適用場景 |
|---------|------|----------|
| HTTP | 依 HTTP 並發數 | Web 應用 |
| CPU | 依 CPU 使用率 | 運算密集型 |
| Memory | 依記憶體使用率 | 資料處理 |
| Azure Queue | 依佇列訊息數 | 非同步處理 |
| Kafka | 依 Kafka lag | 串流處理 |

### 優點
- ✅ Scale-to-zero 節省成本
- ✅ 自動處理流量尖峰
- ✅ 支援多種 trigger

### 缺點
- ⚠️ Cold start 延遲（從 0 啟動需要時間）
- ⚠️ 過於激進的擴縮可能造成不穩定

---

## Demo 12：Secrets（機密管理）

### 為什麼需要？
> 保費費率（`PRICING_FACTOR`）是敏感資料，不應該寫死在程式碼或明文環境變數。使用 Secrets 讓敏感資料安全儲存，且在 Portal 不可見。

### 操作步驟

#### Step 1：建立 Secret
```
Container Apps → fubon-quote-api → Secrets → Add
→ Name: pricing-factor
→ Value: 1.07
```

#### Step 2：修改 Environment Variable 引用 Secret
```
Container Apps → fubon-quote-api → Revisions → Create new revision
→ Environment variables:
   PRICING_FACTOR → Source: Reference a secret → pricing-factor
```

#### Step 3：驗證
回到 UI 按「產生報價」，檢查輸出的 `factors.pricing_factor` 是否變成 `1.07`。

### 講解重點（30 秒）
> 「Secrets 讓你安全管理敏感設定：
> - Secret 值在 Portal 不會顯示（只顯示 ***）
> - Environment variable 可以引用 secret，不用把敏感資料寫死在設定
> - 改 secret 值後需要 restart replicas 才會生效」

### 優點
- ✅ 敏感資料不明文顯示
- ✅ 與環境變數解耦
- ✅ 可與 Azure Key Vault 整合

### 缺點
- ⚠️ 更新 secret 需要 restart
- ⚠️ 不支援自動 rotation

---

## Demo 13：Volume（持久化儲存）

### 為什麼需要？
> 容器是無狀態的，重啟後資料會消失。如果需要保存操作記錄、設定檔，需要 Azure Files 提供持久化儲存。

### 操作步驟

#### Step 1：建立 Storage Account + File Share
```
Azure Portal → Storage accounts → Create
→ Name: stfubon<MMddHHmmss>
→ Resource group: rg-az2003-aca-demo

Storage account → File shares → + File share
→ Name: fubonshare
→ Quota: 5 GiB
```

#### Step 2：取得 Storage Account Key
```
Storage account → Access keys → 複製 key1
```

#### Step 3：在 Environment 註冊 Storage
```
Container Apps environments → aca-az2003-demo-env → Storage → Add
→ Storage type: Azure Files
→ Storage name: fubonfiles（⚠️不要用特殊字元）
→ Storage account: 選你的 storage account
→ File share: fubonshare
→ Access key: 貼上 key
```

#### Step 4：在 fubon-web 掛載 Volume
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

#### Step 5：驗證持久化
```
Container Apps → fubon-web → Console → Connect
```

在 Console 執行：
```bash
# 寫入檔案
date >> /mnt/files/demo.log
cat /mnt/files/demo.log

# 確認檔案存在
ls -la /mnt/files/
```

到 Storage account → File shares → fubonshare，確認看到 `demo.log`。

#### Step 6：驗證跨 revision 持久化
再建一個新 revision（例如改一下 APP_VERSION），然後回 Console 檢查：
```bash
cat /mnt/files/demo.log  # 檔案應該還在
```

### 講解重點（45 秒）
> 「ACA 支援三種 storage 類型：
> 1. **Container filesystem**：容器重啟就消失
> 2. **Ephemeral volume**：同 replica 內共享，replica 消失就沒了
> 3. **Azure Files volume**：持久化，跨 replica / revision 都保留
>
> Azure Files 適合：logs、config files、shared data」

### 三種 Storage 類型比較

| 類型 | 生命週期 | 適用場景 |
|------|----------|----------|
| Container filesystem | 容器重啟消失 | 暫存快取 |
| Ephemeral | Replica 消失消失 | 跨容器共享 |
| Azure Files | 永久 | 日誌、設定、共享資料 |

### 優點
- ✅ 跨 replica/revision 持久化
- ✅ 可多 App 共享同一 File Share
- ✅ 支援 SMB/NFS

### 缺點
- ⚠️ 效能不如本地 SSD
- ⚠️ 有額外儲存成本
- ⚠️ 需要管理 Storage Account Key

---

## Demo 14：Jobs（批次作業）

### 為什麼需要？
> 保單審核不需要持續運行，只需要定時或手動觸發執行一次。Container Apps Jobs 專為這種「執行完就結束」的場景設計。

### 操作步驟

#### Step 1：建立 Container Apps Job
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

> ⚠️ 注意：Job 不啟用 Dapr，所以用 internal DNS URL 呼叫 API

#### Step 2：手動觸發 Job
```
Container Apps Jobs → fubon-audit-job → Execution history → Run now
```

#### Step 3：查看 Logs
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

### 講解重點（45 秒）
> 「Container Apps Jobs 讓你執行批次工作：
> - **Manual**：手動觸發（適合 ad-hoc 任務）
> - **Schedule**：用 cron expression 定時執行
> - **Event-driven**：由 Azure Queue、Kafka 等事件觸發
>
> Job 執行完就結束，不像 App 持續運行。適合：
> - 資料處理、ETL
> - 定時報表
> - 批次審核、清理」

### Job Trigger 類型

| 類型 | 說明 | 適用場景 |
|------|------|----------|
| Manual | 手動觸發 | Ad-hoc 任務 |
| Schedule | Cron 定時 | 每日報表 |
| Event | 事件觸發 | 佇列處理 |

### 優點
- ✅ 執行完就結束，不佔資源
- ✅ 支援重試、timeout 設定
- ✅ 可並行執行多個 execution

### 缺點
- ⚠️ 無法即時互動
- ⚠️ 單次執行時間有限制

---

## Demo 15：Console & Logs（偵錯工具）

### 為什麼需要？
> 生產環境出問題時，需要快速進入容器檢查狀態。Console 讓你即時執行命令，Logs 讓你查詢歷史記錄。

### Console 操作
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

# 測試內部連線
curl http://localhost:3000/api/version

# 如果有掛 volume
ls -la /mnt/files/

# 測試 Dapr
curl http://localhost:3500/v1.0/healthz
```

### Logs 操作

**即時 Logs**
```
Container Apps → fubon-web → Log stream
```

**Log Analytics 查詢**
```
Container Apps → fubon-web → Logs
```

**範例 KQL 查詢**
```kusto
ContainerAppConsoleLogs_CL
| where ContainerAppName_s == "fubon-web"
| order by TimeGenerated desc
| take 50
```

### 講解重點（20 秒）
> 「Console 讓你直接進入容器執行命令，方便即時 debug。Log Analytics 整合 KQL 查詢，可以做進階分析。」

### 優點
- ✅ 即時偵錯能力
- ✅ 不需 kubectl
- ✅ 支援 KQL 進階查詢

### 缺點
- ⚠️ Console 連線可能不穩定
- ⚠️ Log 有延遲（約數分鐘）

---

# 🧹 Part D：清理資源

## Demo 16：刪除 Resource Group

```
Azure Portal → Resource groups → rg-az2003-aca-demo → Delete resource group
```

⚠️ **Demo 結束一定要做這步**，避免持續產生費用。

---

# 📝 附錄

## A. 常見問題排錯

### 1. `/api/quote` 回傳 500
**可能原因**：
- `fubon-quote-api` 的 Dapr app-port 設錯（應該是 8000）
- `fubon-web` 的 `QUOTE_API_APP_ID` 與 api 的 Dapr app-id 不一致

**排錯方法**（在 fubon-web Console）：
```bash
# 測試 Dapr sidecar
curl -s http://localhost:3500/v1.0/healthz

# 測試目標服務
curl -s http://localhost:3500/v1.0/invoke/fubon-quote-api/method/health
```

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

## B. Demo 專案說明

| 專案 | 說明 | 適用場景 |
|------|------|----------|
| `demo/az2003-aca-demo-fubon` | Basic UI（簡潔） | 穩定首選、網路受限環境 |
| `demo/az2003-aca-demo-fubon-tailwind` | Tailwind 美化 UI | 想要漂亮 UI |

> ⚠️ Tailwind UI 走 CDN；若客戶網路擋 CDN，請用 basic UI 版本。

---

## C. 精簡版 Demo 流程（45-60 分鐘）

如果時間有限，可以只做以下項目：

1. ✅ 基礎建設（RG, ACR, Environment）
2. ✅ 部署兩個 Apps（Ingress External/Internal）
3. ✅ Traffic Split（Blue/Green）
4. ✅ Scale（HTTP + scale-to-zero）
5. ✅ Jobs
6. ✅ 清理

---

## D. 參考資料

- [Azure Container Apps Overview](https://learn.microsoft.com/azure/container-apps/overview)
- [Dapr integration with Azure Container Apps](https://learn.microsoft.com/azure/container-apps/dapr-overview)
- [Revisions in Azure Container Apps](https://learn.microsoft.com/azure/container-apps/revisions)
- [Scale in Azure Container Apps](https://learn.microsoft.com/azure/container-apps/scale-app)
- [Azure Container Apps jobs](https://learn.microsoft.com/azure/container-apps/jobs)

---

> **Last Updated**: 2026-01-14
> **Version**: 2.0.0 (Complete Integrated Demo Guide)
