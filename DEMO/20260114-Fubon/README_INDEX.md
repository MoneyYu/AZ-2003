# AZ-2003 富邦 ACA Demo｜All-in-One Bundle 使用指引

> **更新日期**：2026-01-14

## 🚀 你要從哪裡開始？

### ⭐ 推薦：Portal 手動建資源
**直接開** 👉 [`AZ2003_Fubon_ACA_Portal_DEMO_MASTER.md`](AZ2003_Fubon_ACA_Portal_DEMO_MASTER.md)

這是**全整合版 Portal Demo Runbook**，涵蓋：
- ✅ 用 Azure Portal 手動建立所有資源
- ✅ ACA 10 大功能完整展示（Ingress / Dapr / Revisions / Traffic Split / Scale / Secrets / Volume / Jobs / Console / Logs）
- ✅ 每個步驟的 Portal 路徑 + 設定值 + 講解重點
- ✅ 常見問題排錯

### 其他文件（進階參考）
| 文件 | 說明 |
|------|------|
| [`AZ2003_Fubon_ACA_Portal_Demo_Runbook.md`](AZ2003_Fubon_ACA_Portal_Demo_Runbook.md) | Portal Demo（舊版，部分內容） |
| [`AZ2003_Fubon_ACA_LiveDemo_PS7_with_Volume_Integrated.md`](AZ2003_Fubon_ACA_LiveDemo_PS7_with_Volume_Integrated.md) | PowerShell 7 + az CLI 版本 |
| [`AZ2003_Fubon_ACA_Volume_Demo_Addon.md`](AZ2003_Fubon_ACA_Volume_Demo_Addon.md) | Volume（Azure Files）詳細說明 |
| [`AZ2003_Fubon_Dapr_vs_DirectURL_Notes.md`](AZ2003_Fubon_Dapr_vs_DirectURL_Notes.md) | Dapr vs 直接呼叫 URL 差異說明 |
| [`docs/AZ2003_Fubon_ACA_LiveDemo_MASTER_AllIntegrated.md`](docs/AZ2003_Fubon_ACA_LiveDemo_MASTER_AllIntegrated.md) | 舊版整合文件 |

---

## 📦 Demo 專案（兩套）

| 專案 | 說明 | 建議使用場景 |
|------|------|-------------|
| [`demo/az2003-aca-demo-fubon`](demo/az2003-aca-demo-fubon) | Basic UI（簡潔） | 穩定首選、網路受限環境 |
| [`demo/az2003-aca-demo-fubon-tailwind`](demo/az2003-aca-demo-fubon-tailwind) | Tailwind 美化 UI（CDN） | 想要漂亮 UI |

> ⚠️ Tailwind UI 走 CDN；若客戶網路擋 CDN，請用 basic UI 版本。

---

## 🗂️ Demo 架構

```
┌─────────────────────────────────────────────────────────┐
│              Container Apps Environment                  │
│  ┌──────────────┐  ┌─────────────────┐  ┌────────────┐  │
│  │  fubon-web   │  │ fubon-quote-api │  │ audit-job  │  │
│  │ External ☁️  │─▶│  Internal 🔒    │  │  Manual 📋 │  │
│  │   :3000      │  │    :8000        │  │            │  │
│  └──────────────┘  └─────────────────┘  └────────────┘  │
│          │                                               │
│  ┌───────┴───────────────────────────────────────────┐  │
│  │           Azure Files Volume (/mnt/files)          │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## ✅ ACA 功能清單

| 功能 | 展示內容 |
|------|---------|
| 🌐 Ingress | External vs Internal、TLS termination |
| 🔗 Dapr | Service Invocation、Sidecar |
| 📸 Revisions | Immutable snapshot、rollback |
| 🔀 Traffic Split | Blue/Green、A/B testing |
| 📈 Scale | HTTP concurrency、scale-to-zero |
| 🔐 Secrets | secretRef |
| 💾 Volume | Azure Files persistent |
| ⏰ Jobs | Manual / Schedule / Event |
| 🖥️ Console | 即時 debug |
| 📋 Logs | Log Analytics |
