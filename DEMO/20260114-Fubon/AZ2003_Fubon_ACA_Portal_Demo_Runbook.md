# AZ-2003｜Azure Container Apps Portal Demo Runbook（台灣富邦版｜手動 Portal 建資源）

> 你要「用 Azure Portal 手動建立資源」來展示 ACA 的建立過程（RG/ACR/Environment/App/Ingress/Revisions/Scale/Jobs）。本文件把 **Portal 點擊路徑**＋**你要講的重點**整理成逐步 Runbook。
>
> 依據課程內容：Ingress 支援 external/internal、traffic split、session affinity；Revisions 是不可變快照、可做 Blue/Green；Scale 由宣告式規則驅動（HTTP/TCP/自訂）。citeturn10search283turn10search282turn10search274turn10search286turn10search319

---

## A. Demo 物件（固定命名，現場好講）

- Resource Group：`rg-az2003-aca-demo`
- ACR：`acraz2003<random>`
- Container Apps Environment：`aca-az2003-demo-env`
- Container Apps：
  - `fubon-web`（External ingress）
  - `fubon-quote-api`（Internal ingress）
- Container Apps Job：`fubon-audit-job`

> 你可以用我們已經準備好的 Demo 專案（含三個 Dockerfile）來 build/push images。citeturn4file159

---

## B. Portal 建資源（逐步點擊）

### 1) 建 Resource Group

**Portal 路徑**
- Azure portal → **Resource groups** → **Create**

**填寫建議**
- Subscription：你的 lab/訂閱
- Resource group name：`rg-az2003-aca-demo`
- Region：建議同一區域（例如 East Asia）

**你要講的重點（10 秒）**
- RG = 本次 demo 的「資源邊界」，最後清理一鍵刪除。

---

### 2) 建 Log Analytics Workspace（供 ACA logs）

**Portal 路徑**
- Azure portal → 搜尋 **Log Analytics workspaces** → **Create**

**填寫建議**
- Workspace name：`la-az2003-demo`
- Region：同 RG

**你要講的重點（10 秒）**
- ACA 建 Environment 時可綁 Log Analytics，方便看 logs / job 執行輸出。

---

### 3) 建 Azure Container Registry（ACR）

**Portal 路徑**
- Azure portal → 搜尋 **Container registries** → **Create**

**填寫建議**
- Registry name：`acraz2003<random>`（需全域唯一）
- SKU：Basic（Demo 足夠）

**你要講的重點（10 秒）**
- ACR 用來 **存放與管理容器映像**，之後 ACA 會從這裡拉 image。citeturn1search1

> ✅ Demo 小技巧：ACR 建好後，到 ACR → **Repositories**，等一下 push 完你就能直接秀 `fubon-web / fubon-quote-api / fubon-audit-job` 三個 repo。

---

### 4) Build & Push 三個 images（建議用本機 Docker + ACR）

> 你說「Azure 資源用 Portal 建」，沒問題；**映像建置/推送**通常仍用本機 Docker 最順，畫面也好講（build→tag→push→ACR repos 看到成果）。

**Command（在你的電腦/VM terminal）**
```bash
# ACR 登入（可用 az 或 Docker login）
az acr login -n labacrksd
$ACR_LOGIN_SERVER=$(az acr show -n labacrksd --query loginServer -o tsv)

# build
docker build -t fubon-web:1.0.0 ./src/web
docker build -t fubon-quote-api:1.0.0 ./src/api
docker build -t fubon-audit-job:1.0.0 ./src/job

# build
docker build -t $ACR_LOGIN_SERVER/fubon-web:1.0.0 ./src/web
docker build -t $ACR_LOGIN_SERVER/fubon-quote-api:1.0.0 ./src/api
docker build -t $ACR_LOGIN_SERVER/fubon-audit-job:1.0.0 ./src/job

# push
docker push $ACR_LOGIN_SERVER/fubon-web:1.0.0
docker push $ACR_LOGIN_SERVER/fubon-quote-api:1.0.0
docker push $ACR_LOGIN_SERVER/fubon-audit-job:1.0.0
```

**你應該看到**
- push 完會顯示 digest

**Portal 驗證**
- ACR → **Repositories** → 看到三個 repo（最能回答學員「image 在哪裡」）

---

### 5) 建 Azure Container Apps Environment

**Portal 路徑**
- Azure portal → 搜尋 **Container Apps** → 左側 **Environments**（或 Create Container Apps 時會要求建立 Environment）

**填寫建議**
- Environment name：`aca-az2003-demo-env`
- Region：同 RG
- Logs：選擇剛剛的 Log Analytics Workspace

**你要講的重點（15 秒）**
- Environment 是 ACA 的「安全邊界」，背後有 VNet boundary。
- Ingress proxy 在環境層提供 TLS termination、load balancing、traffic splitting。

---

## C. Portal 建兩個 Container Apps（Ingress + Dapr + Version）

### 6) 建 `fubon-quote-api`（Internal ingress）

**Portal 路徑**
- Azure portal → **Container Apps** → **Create**

**在 Create 畫面要點**
- Resource group：`rg-az2003-aca-demo`
- Container app name：`fubon-quote-api`
- Environment：選 `aca-az2003-demo-env`

**Container**（Image）
- Image source：Azure Container Registry
- Registry：選你的 ACR
- Image：`fubon-quote-api:1.0.0`

**Ingress**
- Enable ingress：✅
- Ingress traffic：**Internal**（或 external=false）
- Target port：`8000`

**Dapr（可選，但很加分）**
- Enable Dapr：✅
- App ID：`fubon-quote-api`
- App port：`8000`

**Environment variables（用來展示 version）**
- `APP_VERSION=1.0.0`
- `DEPLOYMENT_LABEL=blue`
- `BASE_RATE=0.0026`
- `PRICING_FACTOR=1.00`

**你要講的重點**
- Internal ingress 代表只允許同一個 environment 內的服務存取。

---

### 7) 建 `fubon-web`（External ingress）

**Portal 路徑**
- Azure portal → **Container Apps** → **Create**

**Container**
- Name：`fubon-web`
- Image：`fubon-web:1.0.0`

**Ingress**
- Enable ingress：✅
- Ingress traffic：**External**
- Target port：`3000`

**Dapr（建議啟用）**
- Enable Dapr：✅
- App ID：`fubon-web`
- App port：`3000`

**Environment variables**
- `APP_VERSION=1.0.0`
- `DEPLOYMENT_LABEL=blue`
- `DAPR_ENABLED=true`
- `QUOTE_API_APP_ID=fubon-quote-api`

**你要講的重點**
- 開 ingress 不需要額外 LB/Public IP；ACA 直接提供 FQDN + TLS termination。

**驗證**
- Container App → Ingress → 取得 FQDN → 打開 UI
- 點「版本資訊」→ 會回 `version/revision/label`（用來鋪墊 revisions/traffic split）

---

## D. Portal 展示重點 1：Ingress（外/內）

### 8) 現場 30 秒講法

- `fubon-web`：External（對外入口）
- `fubon-quote-api`：Internal（僅內部）

Ingress 功能包含 external/internal、HTTP/TCP、traffic splitting、session affinity。citeturn10search283turn10search284

---

## E. Portal 展示重點 2：Revisions + Traffic Split（Blue/Green）

> 預設是 **Single revision**；要做 traffic split 必須切到 **Multiple revision mode**。

### 9) 在 Portal 啟用 Multiple revisions

**Portal 路徑**
- Container App `fubon-web` → **Revisions and replicas** → 將 revision mode 設為 **Multiple**

### 10) 部署 Green 版（新 revision）

你有兩種方式：

**方式 A（推薦，快）：更新 image tag**
1) 先 push 新 tag（例如 `1.0.1`）
2) Portal → `fubon-web` → **Revision management / Container** → 更新 Image 到 `fubon-web:1.0.1`
3) 同時把 env 改成：
   - `APP_VERSION=1.0.1`
   - `DEPLOYMENT_LABEL=green`

**你要講的重點**
- 「Revision-scope changes」會產生新 revision；可保留最多 100 revisions。

### 11) Traffic split（80/20）

**Portal 路徑**
- `fubon-web` → **Revisions and replicas** → Traffic weights
  - Blue revision：80%
  - Green revision：20%

**你要講的重點**
- traffic splitting 是基於權重（百分比）把流量導向不同 revision（A/B、Blue/Green）。

**驗證（最直觀）**
- 一直按 UI「版本資訊」或重刷 `/api/version`
- 你會看到 `APP_VERSION` / `DEPLOYMENT_LABEL` 交替出現

---

## F. Portal 展示重點 3：Scale（Scale-to-zero）

> ACA 透過宣告式 scaling rules 自動水平縮放（KEDA 驅動），常見觸發：HTTP 併發、CPU/Memory、佇列訊息。

### 12) 設定 HTTP scale rule

**Portal 路徑**
- `fubon-web` → **Scale and replicas**

**建議設定**
- Min replicas：`0`
- Max replicas：`10`
- Scale rule：HTTP
- Concurrency：`20`（想更容易看到 scale 就設 `5`）

### 13) 產生流量（讓 replicas 拉起來）

**Command（示例）**
```bash
FQDN=<你的 fubon-web FQDN>
for i in {1..300}; do curl -s https://$FQDN/api/version > /dev/null; done
```

### 14) 在 Portal 觀察結果

**Portal 路徑**
- `fubon-web` → **Scale and replicas** → Replicas（或 Metrics）

**你要講的重點**
- HTTP scale rule 允許 scale-to-zero；流量停了 replica 會回到 0。citeturn10search286turn10search294

---

## G. Portal 加分：Secrets（不改 code 改保費）

> 環境變數可直接填值，也可引用 secrets；變數設定可在建立時或後續建立新 revision 時更新。citeturn10search296turn1search1

**Portal 路徑**
- `fubon-quote-api` → **Secrets** → Add secret `pricing-factor=1.07`
- `fubon-quote-api` → **Environment variables** → `PRICING_FACTOR` 改成 **secret reference**

**驗證**
- 回 UI 按「產生報價」→ 看 `factors.pricing_factor` 變成 1.07

---

## H. Portal 加分：Jobs（批次審核）

> Jobs 支援 Manual/Schedule/Event，且可設定 retries/timeouts/parallelism。citeturn10search297turn10search277

### 15) 建 `fubon-audit-job`

**Portal 路徑**
- Azure portal → 搜尋 **Container Apps Jobs**（或 Container Apps → Jobs）→ **Create**

**填寫建議**
- Name：`fubon-audit-job`
- Environment：`aca-az2003-demo-env`
- Trigger：Manual
- Image：`fubon-audit-job:1.0.0`
- Env var：
  - `QUOTE_URL=http://fubon-quote-api:8000/quote?age=45&coverage=2000000&term=20`

### 16) 觸發 job + 看 log

**Portal 路徑**
- Job → **Executions** → Start
- Job → Logs（或到 Log Analytics 查）

---

## I. 最後清理（Demo 結束一定要做）

**Portal 路徑**
- Resource groups → `rg-az2003-aca-demo` → Delete resource group

---

## J. 你可以直接拿來講的 20 秒收斂

- Ingress 讓 web 對外、api 對內，並支援 traffic split。citeturn10search283turn10search273
- Revisions 是不可變快照，multiple mode 可以 Blue/Green。citeturn10search274turn10search281turn10search319
- Scale 用宣告式規則自動擴縮，HTTP rule 可 scale-to-zero。citeturn10search286turn10search294
- Jobs 讓你把「批次審核/維護」這類工作拆成 on-demand/scheduled 的容器任務。citeturn10search297turn10search277
