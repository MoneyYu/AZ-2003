# AZ-2003｜Azure Container Apps Demo（富邦情境）

此 Demo 用「台灣富邦 ePolicy 報價/審核」情境串起 AZ-2003 核心：

- ACR：Build/Push images
- ACA：Environment + Apps
- Ingress：`fubon-web` external、`fubon-quote-api` internal
- Dapr：Service Invocation（web → api）
- Revisions：multiple revisions + traffic split（Blue/Green）
- Scale：HTTP concurrency + scale-to-zero
- Secrets：`secretRef` → env var
- Jobs：`fubon-audit-job`（manual trigger）
- Volume（Add-on）：Azure Files persistent + ephemeral 概念

資料夾：
- `src/web`：Node/Express（前端 UI + BFF）
- `src/api`：FastAPI（報價 API）
- `src/job`：Python job（批次審核）

> UI 有兩個版本：
> - basic（簡單版）
> - tailwind（美化版，含 Light/Dark）
