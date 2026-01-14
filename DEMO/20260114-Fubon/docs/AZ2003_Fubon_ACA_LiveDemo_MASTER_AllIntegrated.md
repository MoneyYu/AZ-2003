# AZ-2003｜富邦 ACA Live Demo — **全整合 Master Runbook（PowerShell 7 + Portal + Dapr + Volume）**

> 這份文件把我們前面討論的所有東西「整合成一套」：
> - **你用 PowerShell 7 + az CLI 逐行 Demo**（主流程）
> - **必要時用 Portal 手動建立資源**（你要求的方式）
> - **Dapr 原理 + 為什麼只要設定 app-id/app-port 就能跑**
> - **Dapr vs 直接寫 ACA URL 的語意差異**
> - **Volume / Storage Mount（Azure Files persistent）加進 Live Demo**
> - 常見錯誤（像你遇到的 /api/quote 500）快速排錯清單

---

## 0) 你今天要 Demo 的最終畫面（Checklist）

- ✅ ACR：3 個 repo（`fubon-web`、`fubon-quote-api`、`fubon-audit-job`）
- ✅ ACA：Environment + 2 Apps + 1 Job
- ✅ Ingress：web external / api internal
- ✅ Dapr：web 透過 service invocation 呼叫 api
- ✅ Revisions：multiple mode + blue/green traffic split
- ✅ Scale：HTTP concurrency + scale-to-zero
- ✅ Secrets：secretRef 改變報價因子
- ✅ Jobs：manual trigger + executions
- ✅ Volume：Azure Files mount `/mnt/files`，跨 revision 檔案仍存在

---

## 1) 主流程：PowerShell 7 + az CLI（逐行指令）

### 1.1 PS7 指令（原版）

(找不到先前的 PS7 Live Demo 文件；已在本 bundle 內提供新版 Master Runbook。)


---

## 2) 🔥 Volume Demo（整合進 Live Demo）

> 建議插入點：你做完 **Scale** 或 **Traffic Split** 後。
> 
> 目標：用 **Azure Files persistent volume** 讓學員看到：
> - 寫入 `/mnt/files/demo.log`
> - 做一次 revision update（或 scale-to-zero 後回來）
> - 檔案仍存在（持久化）

### 2.1 建 Storage account + File share（PS7 逐行）

```powershell
$env:ST    = ('stfubon' + (Get-Date -Format 'MMddHHmmss'))
$env:SHARE = 'fubonshare'

az storage account create --name $env:ST --resource-group $env:RG --location $env:LOCATION --sku Standard_LRS -o table

$acctKey = az storage account keys list --account-name $env:ST --resource-group $env:RG --query "[0].value" -o tsv

az storage share-rm create --resource-group $env:RG --storage-account $env:ST --name $env:SHARE --quota 10
az storage share-rm show --resource-group $env:RG --storage-account $env:ST --name $env:SHARE -o json
```

### 2.2 Portal：把 Azure Files 掛到 ACA Environment（Environment Storage）

1) Azure portal → Container Apps → Environments → 選 `aca-az2003-demo-env`
2) Storage → Add
3) Storage type：Azure Files
4) Storage name：`fubonfiles`（⚠️不要特殊字元）
5) Storage account：選 `$env:ST`
6) File share：`fubonshare`
7) Authentication：貼上 `$acctKey`

### 2.3 Portal：在 `fubon-web` 掛載 Volume（Mount path）

1) Container Apps → `fubon-web`
2) Revisions（或 Revisions and replicas）→ Create new revision / Edit and deploy
3) Containers → Volumes / Volume mounts
4) 選 `fubonfiles` → Mount path：`/mnt/files`
5) Deploy（會產生新 revision）

### 2.4 驗證：Console 寫檔 → Portal File share 看檔

在 `fubon-web` → Console：
```bash
date >> /mnt/files/demo.log
ls -la /mnt/files
cat /mnt/files/demo.log | tail
```

然後到 Storage account → File shares → `fubonshare`，確認 `demo.log` 存在。

### 2.5 再做一次 revision update，驗證檔案仍在

例如改 `DEPLOYMENT_LABEL` 或 `APP_VERSION` 觸發新 revision，再回 Console：
```bash
cat /mnt/files/demo.log | tail
```

> ✅ 檔案仍存在 → Azure Files 是 persistent volume。

### 2.6（完整版本）Volume Add-on

(找不到 Volume Add-on；已在 Master Runbook 內含完整步驟。)


---

## 3) Dapr 原理（為何只要設定就能運作）＋ Dapr vs 直接 URL

(找不到 Dapr Notes；已在 Master Runbook 內含 Dapr 原理與對照。)


---

## 4) 你遇到的 500（/api/quote）— 30 秒排錯清單

> 你前面遇到的狀況非常典型：前端打 `/api/quote`，web 端會去呼叫 Dapr sidecar（localhost:3500）或 direct URL。

### 4.1 先看 `fubon-web` 的回傳 JSON（我們已強化錯誤輸出）
- 你會看到：`error`、`code`、`responseStatus/responseData`、以及 `hint`

### 4.2 90% 根因（照順序檢查）
1) **web 沒有 enable dapr** → localhost:3500 連不到（ECONNREFUSED）
2) **api 沒有 enable dapr** → web 找不到目標 sidecar
3) `QUOTE_API_APP_ID` ≠ api 的 `dapr.appId` → 找不到服務
4) api `dapr.appPort` 設錯（不是 8000）→ sidecar 轉發失敗
5) web/app protocol 設錯（http/grpc 不一致）

### 4.3 最快驗證（Portal Console）
在 `fubon-web` → Console：
```bash
curl -s http://localhost:3500/v1.0/healthz
curl -s http://localhost:3500/v1.0/invoke/fubon-quote-api/method/health
```
- 第一個不過：web 沒 Dapr
- 第二個不過：目標 app-id 或 api Dapr 設定有問題

---

## 5) Portal 手動建資源（你要的做法）

(找不到 Portal Runbook；已在 Master Runbook 內含 Portal 要點。)


