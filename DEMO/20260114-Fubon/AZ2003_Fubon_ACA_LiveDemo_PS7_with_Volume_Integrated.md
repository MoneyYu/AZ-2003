
# AZ-2003｜Azure Container Apps Live Demo（PowerShell 7 + az CLI）— **含 Volume(Storage Mount) 整合版**

> 你已經有一套 Live Demo（ACR → ACA Env → Apps → Ingress → Version/Revision → Traffic Split → Scale → Secrets → Jobs）。
> 這份文件把 **Volume / Storage Mount（Azure Files persistent + Ephemeral 概念）** 插入到最順的段落，讓你可以一氣呵成地 Demo。
>
> Storage 類型回顧（來自課程投影片）：
> - **容器檔案系統**：容器重啟/關閉就消失
> - **短暫卷**（replica-scoped）：同 replica 共享、replica 消失才消失
> - **Azure Files 卷**：可跨 replica / revision 持久化
> citeturn1search1

---

## ✅ 整合後 Demo 節奏（建議插入點）

### 主線（你原本的 Live Demo）
1. RG / Log Analytics / ACR
2. Build & Push 3 images
3. ACA Environment
4. 部署 `fubon-quote-api`（Internal ingress + Dapr）
5. 部署 `fubon-web`（External ingress + Dapr）
6. Version / Revision（/api/version）
7. Revisions + Traffic Split（Blue/Green）
8. Scale（HTTP concurrency + scale-to-zero）

### 🔥 插入點：**就在你做完 Scale（或做完 Traffic Split）之後**
9. **Volume Demo（Azure Files persistent）** ✅（最推薦）
10. （可選）Ephemeral Volume（概念/加分）

然後再回來：
11. Secrets
12. Jobs
13. Cleanup

---

## 1) Live Demo（PS7 + az CLI）主線

> 這段沿用你已經在用的 PS7 Live Demo。
> 若你手邊已經在用舊版文件，照舊跑到「Scale」那段即可。


---

## 1.1 既有 PS7 Live Demo 指令（原樣保留）

(missing previous PS7 doc in workspace)

---

## 2) 🔥 Volume Demo（整合進 Live Demo）

> 目標：用 **Azure Files** 做「持久化」示範：
> - 寫入 `/mnt/files/demo.log`
> - 做一次 `revision update` 或 `scale-to-zero` 再回來
> - 檔案仍存在（跨 revision / replica 仍保留）

### 2.1 準備：建立 Storage Account + File Share（PowerShell 7 逐行）

> 你可以一行一行 Show，且最後在 Portal 直接看到檔案最直觀。

```powershell
# Storage account / share 名稱
$env:ST    = ('stfubon' + (Get-Date -Format 'MMddHHmmss'))
$env:SHARE = 'fubonshare'

# 建 storage account
az storage account create --name $env:ST --resource-group $env:RG --location $env:LOCATION --sku Standard_LRS -o table

# 取 key
$acctKey = az storage account keys list --account-name $env:ST --resource-group $env:RG --query "[0].value" -o tsv

# 建 file share
az storage share-rm create --resource-group $env:RG --storage-account $env:ST --name $env:SHARE --quota 10

# 驗證 share
az storage share-rm show --resource-group $env:RG --storage-account $env:ST --name $env:SHARE -o json
```

### 2.2 在 Portal 把 Azure Files 掛到 ACA Environment（Environment Storage）

> 這一步建議用 Portal：畫面最好講、且不容易因 CLI 版本差異翻車。

**Portal 路徑**
1) Azure portal → Container Apps → Environments → 選 `aca-az2003-demo-env`
2) **Storage** → **Add**
3) Storage type：Azure Files
4) Storage name：`fubonfiles`（⚠️不要特殊字元）
5) Storage account：選 `$env:ST`
6) File share：`fubonshare`
7) Authentication：使用 storage account key（貼上 `$acctKey`）

> 這段細節與注意事項已整理在 Volume Add-on 文件。citeturn19file527

### 2.3 在 `fubon-web` 掛載 Volume（Mount path）

**Portal 路徑**
1) Container Apps → `fubon-web`
2) Revisions（或 Revisions and replicas）→ **Create new revision / Edit and deploy**
3) Containers → **Volume mounts**（或 Volumes）
4) 選擇剛剛 environment storage 的 `fubonfiles`
5) Mount path：`/mnt/files`
6) Deploy（會建立新 revision）

### 2.4 驗證（Console 寫檔 → Portal File share 看檔）

**Portal 路徑**
- `fubon-web` → Console

**Command（在 Console）**
```bash
date >> /mnt/files/demo.log
ls -la /mnt/files
cat /mnt/files/demo.log | tail
```

**你應該看到**
- `/mnt/files/demo.log` 存在，且有時間戳。

**再到 Portal 驗證**
- Storage account → File shares → `fubonshare` → 看到 `demo.log`

### 2.5 做一次「會觸發 revision」的變更，再次驗證檔案仍在

你可以選一個最不痛的：
- `fubon-web` → Create new revision → 把 `DEPLOYMENT_LABEL=green` 或 `APP_VERSION=...` 改掉

然後回 Console：
```bash
cat /mnt/files/demo.log | tail
```

**你要講的重點（15 秒）**
- 這個檔案跨 revision 仍保留 → 因為它在 Azure Files（persistent volume）。

---

## 3) （可選加分）Ephemeral Volume（短暫卷）

> 這段只要講概念就很夠：
> - container-scoped：容器重啟就沒
> - replica-scoped：同 replica 共用，但 replica 不在就沒
> - 所以 ephemeral 適合 cache / scratch，不適合持久化
> citeturn1search1

若你想真的做一次小 demo：
1) 在 `fubon-web` 新增 ephemeral volume mount 到 `/mnt/tmp`
2) Console 寫入 `temp.log`
3) 讓它 scale-to-zero（min=0、停止流量）
4) 回來可能會看不到（視 replica 是否重建）

---

## 4) 常見坑（避免現場翻車）

- Volume / storage name 避免特殊字元（常見部署失敗原因）citeturn19file527
- 記得先在 **Environment** 註冊 storage，App 才能引用citeturn19file527
- Mount 失敗：Portal 的 Diagnose/Storage mount failures 很快能定位 key/share/network 問題citeturn19file527

---

## 5) 附錄：原本的 Volume Add-on（完整版本）


(missing volume addon doc in workspace)
