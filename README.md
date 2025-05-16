# Minecraft 多版本伺服器管理系統

本系統允許你管理多個版本的 Minecraft 伺服器，但同一時間只能啟動一個版本，並支援以下功能：

- 一鍵安裝伺服器服務（`install.sh`）
- 管理目前運行的伺服器（`manage.sh`）
- 停止伺服器時自動備份
- 每日自動備份與過期清理
- systemd 服務整合
- screen 多工處理並可手動介入

---

## 📁 目錄結構說明

```
/opt/minecraft/
├── install.sh         # 安裝 Minecraft 指定版本伺服器
├── manage.sh          # 管理當前正在運行的伺服器
├── uninstall.sh       # 移除指定版本伺服器
├── scripts/           # 模板腳本位置
│   ├── start_template.sh
│   ├── stop_template.sh
│   ├── backup_template.sh
│   └── minecraft_template.service
├── server/
│   ├── 1.20.4/        # ← 放置原始伺服器文件夾 (需手動下載)
│   │   ├── server.jar
│   │   ├── eula.txt
│   │   ├── server.properties
│   │   └── ...
│   └── ...
└── /storage/minecraft_backup/
    └── 1.20.4/        # ← 自動備份輸出路徑
```

---

## ⚠️ 安裝前準備（必讀）

在執行 `install.sh` 之前，你**必須**先完成以下步驟：

1. **手動建立伺服器版本資料夾**

   例如，如果你要安裝 `1.20.4` 版本，請先下載該版本的伺服器檔案並將其放入：

   ```
   /opt/minecraft/server/1.20.4/
   ```

2. **至少需包含以下檔案：**

   - `server.jar`（伺服器核心檔）
   - `eula.txt`（內容為 `eula=true`，或讓系統自動修改）
   - `server.properties`（將自動修改為 `online-mode=false`）

---

## 🛠️ 安裝伺服器

```bash
cd /opt/minecraft
./install.sh -o 1.20.4
```

這將執行以下步驟：

- 檢查並修改 `eula.txt` 與 `server.properties`
- 停止其他正在運行的 Minecraft systemd 服務
- 將模板腳本複製到該伺服器資料夾的 `scripts/` 子資料夾
- 設定並啟用 systemd 服務（但不啟動）
- 建立每日 04:00 自動備份的 cron 任務
- 給 `manage.sh` 賦予執行權限

---

## 🚦 管理目前運行的伺服器

使用 `manage.sh` 可對目前唯一正在運行的伺服器進行以下操作：

```bash
./manage.sh start     # 啟動目前 systemd 管理的伺服器
./manage.sh stop      # 停止並自動備份
./manage.sh backup    # 停止 → 備份 → 重啟
./manage.sh screen    # 進入 screen 交互模式 (建議用於管理玩家、op 設定等)
```

---

## 🧼 移除指定伺服器

```bash
./uninstall.sh -o 1.20.4
```

這將執行：

- 停止並禁用 `minecraft-1.20.4.service`
- 移除相關 systemd 服務檔案
- 移除 cron 任務
- 刪除伺服器資料夾 `/opt/minecraft/server/1.20.4`

⚠️ 備份檔案將**不會**被刪除，仍保留於 `/storage/minecraft_backup/1.20.4/`

---

## 🗃️ 備份與還原策略

- 每天凌晨 04:00 自動備份目前正在運行的伺服器
- 備份資料儲存在 `/storage/minecraft_backup/<版本>/`
- 舊備份超過 7 天會自動刪除
- 每次 `stop` 時也會自動備份，並避免備份迴圈（透過 `SKIP_BACKUP=true`）

---

## 📋 FAQ

**Q: 可以同時運行多個伺服器版本嗎？**  
A: 不行，系統設計是每次只能有一個版本運行。執行安裝時會自動停止其他正在運行的 Minecraft systemd 服務。

**Q: 如何還原伺服器？**  
A: 手動解壓 `.tar.gz` 備份檔至對應伺服器資料夾，或新建版本資料夾後解壓再執行 `install.sh -o <版本>`。

---

如需更多幫助或要擴充功能，歡迎詢問！
