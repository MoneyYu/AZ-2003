# AZ-2003 富邦 ACA Demo｜使用指引

> **更新日期**：2026-01-14

## 🚀 開始 Demo

### ⭐ 主要文件（必讀）
**直接開** 👉 [`AZ2003_Fubon_ACA_COMPLETE_DEMO.md`](AZ2003_Fubon_ACA_COMPLETE_DEMO.md)

這是**完整整合版 Demo 指南**，涵蓋：
- ✅ 富邦保險微服務場景故事背景
- ✅ 16 個按順序的 Demo 步驟
- ✅ ACA 10 大功能完整展示（Ingress / Dapr / Revisions / Traffic Split / Scale / Secrets / Volume / Jobs / Console / Logs）
- ✅ 每個步驟的「為什麼」、Portal 路徑、設定值、講解重點
- ✅ 每個功能的優點與缺點分析
- ✅ 常見問題排錯
- ✅ 精簡版 Demo 流程（45-60 分鐘）

### 進階參考（排錯/深入）
| 文件 | 說明 |
|------|------|
| [`AZ2003_Fubon_ACA_Volume_Demo_Addon.md`](AZ2003_Fubon_ACA_Volume_Demo_Addon.md) | Volume（Azure Files）詳細說明與常見坑 |
| [`AZ2003_Fubon_Dapr_vs_DirectURL_Notes.md`](AZ2003_Fubon_Dapr_vs_DirectURL_Notes.md) | Dapr 原理與直接呼叫 URL 差異（排錯必讀） |

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
