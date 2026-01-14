# Dapr × Azure Container Apps：原理、設定為何「一打開就能用」、以及與直接呼叫 ACA URL 的差異

> 本文件整理我們在 AZ-2003（富邦情境 Demo）排錯與講解時的重點：
> 1) Dapr 在 Azure Container Apps（ACA）中的運作原理（Sidecar + Service Invocation）
> 2) 為什麼只要設定 app-id / app-port / protocol 就能運作（背後平台做了什麼）
> 3) Dapr vs 直接寫 ACA URL：語意、耦合度、可靠性、資安、觀測、可移植性、成本

---

## 1. 先用一句話講清楚 Dapr 在 ACA 裡是什麼

Azure Container Apps 提供「**原生整合 Dapr**」：啟用後，平台會在每個 app replica 旁邊注入並托管 Dapr sidecar，讓你的程式可以透過本機 Dapr API（HTTP/gRPC）使用微服務能力，例如 service-to-service invocation、觀測性、pub/sub、state 等。 

---

## 2. Dapr 在 ACA 的核心原理：Sidecar 架構（你為什麼只要打 localhost）

### 2.1 Sidecar 是什麼？
- **Sidecar**：與你的應用容器「並排」的一個額外進程/容器，不在你的程式碼內，但透過本機 port 提供 API。
- 在 ACA 裡，Dapr sidecar 由平台管理（啟用 Dapr 後自動注入），你的應用容器用 `http://localhost:<dapr-http-port>` 呼叫 sidecar。

### 2.2 Service Invocation 的資料流（以我們的 Demo 為例）
以 `fubon-web` 呼叫 `fubon-quote-api` 為例：

1) `fubon-web` 呼叫本機 sidecar：
   - `http://localhost:3500/v1.0/invoke/<app-id>/method/<path>`
2) `fubon-web` 的 sidecar 依 `<app-id>` 做服務發現與路由，找到目標 `fubon-quote-api` 的 sidecar/replica。
3) Sidecar 之間透過平台/環境網路進行 service-to-service 通訊，並提供：
   - **auto mTLS**（服務間自動加密/驗證）
   - **built-in retries**（可靠性）
   - **observability**（追蹤/指標/日志）
4) 目標 sidecar 把請求轉發到目標應用容器的 `app-port`（例如 8000）。

重點：你的程式碼只要知道「我要呼叫哪個 app-id」，不必知道對方的 FQDN、IP、或實例數量。

---

## 3. 為什麼只要這樣設定就能運作？（app-id / app-port / protocol 三件套）

在 ACA 裡你看到的幾個設定，其實就是讓平台能把「sidecar ↔ app」與「sidecar ↔ sidecar」兩段連線接起來。

### 3.1 `dapr.enabled`（Enable Dapr）
- 一打開：平台會為該 Container App 的每個 replica 注入 Dapr sidecar，並把 Dapr API 暴露給同一個 replica 內的應用容器使用。

### 3.2 `dapr.appId`（app-id）
- **這是 Dapr 的服務識別**：
  - service discovery 用它找服務
  - pub/sub consumer ID 也用它
  - component scopes 也對應 app-id
- 所以呼叫端寫 `<app-id>`，Dapr 就知道要路由到哪個服務。

### 3.3 `dapr.appPort` + `dapr.appProtocol`（app-port / protocol）
- 這告訴目標 sidecar：「你拿到 invocation 後，要用什麼協議、打到應用容器的哪個 port」。
- 如果 app 實際 listen 8000，但你設定 80，就會發生典型錯誤：sidecar 轉發連不上（connection refused / timeout），最後 caller 看到 500。

### 3.4 「為什麼改 Dapr 設定不一定產生新 revision？」
- 在 ACA 的多修訂（multiple revision mode）中，Dapr 設定屬於 **application-scope changes**：
  - 變更時不一定建立新 revision
  - 可能會讓現有 revisions 重啟以套用最新設定

> 這也是為什麼你只要把 app-id/app-port 改對，環境就立刻「修好」：平台把 sidecar 配置同步到所有 replicas。

---

## 4. Dapr vs 直接設 ACA URL：語意上到底差在哪？

下面用「**你寫程式時你在表達什麼**」來區分：

### 4.1 直接呼叫 ACA URL（FQDN / internal DNS）
你寫的是：
> 「我要打這個 **具體位址**（URL/host/port）」

含意：
- 程式碼要知道對方位址（FQDN、內部 DNS 名稱、端口、協議）。
- 可靠性（重試/超時/熔斷）、資安（mTLS）、追蹤（distributed tracing）要靠你自己或 service mesh/SDK 一套一套補。
- 平台切換（例如搬到別的 runtime/環境）時，命名、網路與中介層常要改。

### 4.2 用 Dapr Service Invocation
你寫的是：
> 「我要呼叫 **這個服務**（app-id） 的某個 method」

含意：
- 位址、服務發現、負載均衡、加密、重試、追蹤…交給 sidecar/平台。
- 程式碼耦合度更低（對方擴縮、重佈署、換實例，呼叫端不動）。
- 一旦你用 Dapr 的 building blocks（pub/sub、state、bindings），更容易把「分散式系統的共通需求」平台化。

---

## 5. 用 8 個維度快速對照（你可以直接放在課堂講義）

1) **耦合度**
- 直呼 URL：耦合到 host/port/路由
- Dapr：耦合到 app-id（服務語意）

2) **服務發現與負載均衡**
- 直呼 URL：要靠 DNS/自建 discovery
- Dapr：sidecar 以 app-id 做 discovery + LB

3) **資安（服務間通訊）**
- 直呼 URL：通常是 TLS 到 ingress；服務間 mTLS 要另建
- Dapr：service invocation 可提供 auto mTLS（服務間）

4) **可靠性（重試/超時/抖動）**
- 直呼 URL：自行在程式/SDK 加
- Dapr：service invocation 有 built-in retries 等能力

5) **觀測性（Tracing/metrics/logs）**
- 直呼 URL：自己埋 OpenTelemetry/headers
- Dapr：sidecar 可攔截流量並輸出 tracing/metrics/logging

6) **可移植性**
- 直呼 URL：依賴平台命名/網路
- Dapr：API 一致（本機、K8s、ACA 類似），更容易搬

7) **功能擴展**
- 直呼 URL：只解決同步呼叫
- Dapr：可加 pub/sub、state、bindings、secrets 等 building blocks

8) **代價/限制**
- 直呼 URL：少一跳、開銷小
- Dapr：多一個 sidecar hop + sidecar 資源成本；也需要理解 Dapr 的設定/元件

---

## 6. 我們這次 500 的典型根因（當作 QA 清單）

> 你已經修好，這段可用於「為什麼剛剛會壞」的教學。

- 呼叫端 `QUOTE_API_APP_ID` 與被呼叫端 `dapr.appId` 不一致 → 找不到服務
- `dapr.appPort` 設錯（app 真的 listen 8000，但 Dapr 設 80）→ 轉發失敗
- 只在 web 開 Dapr，api 沒開 Dapr → caller sidecar 找不到目標 sidecar
- appProtocol 不一致（http/grpc）→ 轉發/序列化不合

---

## 7. 建議你在富邦 Demo 的最佳呈現方式（30 秒講法）

- 「我們讓 `fubon-web` 對外（external ingress），`fubon-quote-api` 對內（internal ingress），這是微服務安全分層。」
- 「web 不直接 hardcode API URL，而是呼叫本機 Dapr sidecar，指定目標 app-id。」
- 「Dapr 幫我們做服務發現、mTLS、重試與觀測；因此只要設定 app-id/app-port 就能跑。」
- 「當我們做 revision/traffic split/scale，服務的位址與實例一直在變，但 app-id 不變，所以呼叫端不用改。」

---

## 8. 參考資料（便於你課後補充）

> 以下是本文件整理時用到的參考來源（多為 Learn / internal decks）。

- ACA Overview deck（KEDA/Dapr/Envoy、同環境共享 VNet + Log Analytics、Dapr integration）
- Dapr 設定：`--enable-dapr` / `--dapr-app-id` / `--dapr-app-port` / `--dapr-app-protocol` 等
- Service Invocation tutorial（auto-mTLS + retries）
- Microservices APIs powered by Dapr（Dapr 作為 abstraction layer）
- Dapr components & scopes（以 app-id 控制哪些 app 載入元件）
