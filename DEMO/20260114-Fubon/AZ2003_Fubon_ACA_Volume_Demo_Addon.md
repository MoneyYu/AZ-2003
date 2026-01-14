# AZ-2003｜ACA Volume（Storage Mount）Demo Add-on（PowerShell 7 + Portal）

> 目的：在你現有的富邦 Demo（`fubon-web`/`fubon-quote-api`/`fubon-audit-job`）上，加一段 **Volume / Storage mount** 展示。
>
> 依據 <File>AZ-2003-TW-PowerPoint_01.pptx</File>：ACA 的 storage mount 主要分三類：
> - **容器檔案系統（container-scoped ephemeral）**：容器關閉/重啟即消失
> - **短暫卷（replica-scoped ephemeral）**：同一 replica 內共享，replica 消失才消失
> - **Azure 檔案卷（Azure Files persistent）**：可跨 replica / revision 持久化
> citeturn19search509
>
> Microsoft Learn 也補充：
> - ACA 可同時使用多種 storage
> - Azure Files 為永久儲存（SMB/NFS）
> - **Volume 名稱避免特殊字元**，否則可能部署失敗
> citeturn19search471turn19search473turn19search489

---

## Part A（推薦）：Azure Files 共享（持久化 Volume）— 最好講、最能展示「跨 revision 仍存在」

### A1) 你要講的 15 秒故事

- 「我們把 `fubon-web` 的 access log / demo 檔案寫進 Azure Files。」
- 「即使我做 revision update、或 scale-to-zero 再拉回來，檔案仍存在。」
- 「這證明 ACA 不只跑 stateless，也能透過 Azure Files 做持久化存儲。」

---

## A2) 用 Portal 建 Storage Account + File Share

### Step 1：建立 Storage account

**Portal 路徑**
- Azure portal → **Storage accounts** → **Create**

**建議設定**
- Resource group：`rg-az2003-aca-demo`
- Name：`stfubon<random>`（需全域唯一）
- Region：同 ACA（例如 East Asia）

### Step 2：建立 File share

**Portal 路徑**
- Storage account → **File shares** → **+ File share**

**建議設定**
- Share name：`fubonshare`
- Quota：5~10 GiB（Demo 足夠）

---

## A3) 把 File share「掛到」Container Apps Environment（Environment storage）

> 這一步會把 Azure Files share 註冊到 ACA Environment，讓環境中的 app 可以引用。citeturn19search473

**Portal 路徑**
- Container Apps → **Environments** → 選 `aca-az2003-demo-env` → **Storage** → **Add**

**填寫重點**
- Storage type：Azure Files
- Storage name：`fubonfiles`（⚠️避免特殊字元）citeturn19search471
- Storage account：選剛建立的 storage account
- File share：`fubonshare`
- Authentication：使用 access key（Portal 會引導你貼 key）

> 補充：Azure Files mount 目前一般是使用 storage account key；文件也有討論 MI 是否可用。citeturn19search477

---

## A4) 在 `fubon-web` Container App 設定 Volume Mount

**Portal 路徑**
- Container Apps → 選 `fubon-web` → **Revisions**（或 **Revisions and replicas**）
- 選擇 **Create new revision** / **Edit and deploy**（名稱可能因 portal 版本略不同）
- 到 **Container**（或 Containers）設定

**設定重點**
- Volumes：新增一個 volume，來源選剛剛 environment storage 的 `fubonfiles`
- Mount path：`/mnt/files`（Linux 路徑）

> 只要你修改了 template（例如 volumeMounts），ACA 會建立新 revision（這也剛好可以順便 demo revision）。

---

## A5) 驗證持久化（不改程式碼，直接在 Console 寫檔）

### Step 1：進入 Console

**Portal 路徑**
- `fubon-web` → **Console**

### Step 2：寫入檔案

**Command（在 Console）**
```bash
date >> /mnt/files/demo.log
ls -la /mnt/files
cat /mnt/files/demo.log | tail
```

**你應該看到**
- `demo.log` 存在，且內容含時間戳

### Step 3：到 Storage account 看檔案

**Portal 路徑**
- Storage account → File shares → `fubonshare` → 你會看到 `demo.log`

### Step 4：做一次 revision update（例如改 env var 或 image tag）

**Portal（示例）**
- `fubon-web` → Create new revision（改 `DEPLOYMENT_LABEL=green` 或 `APP_VERSION=1.0.1`）

再回 Console 重新執行：
```bash
cat /mnt/files/demo.log | tail
```

**你要講的重點**
- 檔案仍在 → 跨 revision 仍持久化（Azure Files）。

---

## Part B（可選加分）：Ephemeral Volume（短暫卷）— 用來講「Cache/Temp」

> Learn 將 ephemeral 分成：
> - **container-scoped**：只在容器存活期間
> - **replica-scoped**：同 replica 內多容器共享，replica 消失才消失
> 並且可用容量跟 vCPU 有關。citeturn19search471

### B1) Demo 建議（簡短版）

1) 在 `fubon-web` 建一個 **Ephemeral (replica-scoped)** volume，mount 到 `/mnt/tmp`
2) Console 寫：
```bash
echo "temp $(date)" >> /mnt/tmp/temp.log
cat /mnt/tmp/temp.log
```
3) 然後 **scale-to-zero**（min replicas=0，停止流量一段時間）
4) replica 回來後，再看 `/mnt/tmp/temp.log` 通常會消失或重建（視 replica 是否重建）

**你要講的重點**
- ephemeral 適合 cache / scratch，不是用來做真正持久化。

---

## Part C：PowerShell 7（az CLI）建立 Storage account + File share（你要逐行指令也能秀）

> 下面是你想「一行一行打」時的指令版（資源仍可用 Portal 驗證）。

```powershell
# 變數
$env:ST = ('stfubon' + (Get-Date -Format 'MMddHHmmss'))
$env:SHARE = 'fubonshare'

# 建 storage account
az storage account create --name $env:ST --resource-group $env:RG --location $env:LOCATION --sku Standard_LRS -o table

# 建 file share
$acctKey = az storage account keys list --account-name $env:ST --resource-group $env:RG --query "[0].value" -o tsv
az storage share-rm create --resource-group $env:RG --storage-account $env:ST --name $env:SHARE --quota 10

# 驗證 share
az storage share-rm show --resource-group $env:RG --storage-account $env:ST --name $env:SHARE -o json
```

> 接著回到 Portal 做 A3（Environment storage）與 A4（Mount path）會比較直觀。

---

## 常見坑（幫你避免現場翻車）

1) **Volume name 不要用特殊字元**（像 `(`、`)`、`/` 等），不然可能部署失敗。citeturn19search471
2) Azure Container Apps storage mount 以 Azure Files 為主；不要拿 Blob/NetApp 期待直接 mount（不支援）。citeturn19search471
3) 記得在 **Environment 先註冊 storage**，App 才能引用。
4) 若 mount 失敗：Portal → Diagnose and solve problems → Storage mount failures（很快定位 credential/share/network）。citeturn19search517
