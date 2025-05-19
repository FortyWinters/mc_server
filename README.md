# minecraft-server-kit

一个简洁高效的Minecraft服务器管理工具，支持多版本/整合包部署、单实例运行、自动备份与控制台管理。

---

## 📁 目录结构
```bash
git clone https://github.com/FortyWinters/minecraft-server-kit.git /opt/minecraft
```

```
/opt/minecraft/
├── install.sh         # 安裝指定版本mc server
├── manage.sh          # 管理当前mc server
├── uninstall.sh       # 移除指定版本mc server
├── scripts/           # 脚本模板
│   ├── start_template.sh
│   ├── stop_template.sh
│   ├── backup_template.sh
│   └── minecraft_template.service
├── server/
│   ├── 1.20.1/        # mc server整合包
│   │   ├── server.jar
│   │   ├── eula.txt
│   │   ├── server.properties
│   │   └── ...
│   └── ...
└── /storage/minecraft_backup/
    └── 1.20.1/        # 自动备份
```

---

## ⚠️ 安装准备

在安装前，必须完成以下步骤：

1. **手动导入mc server整合包**

   例如，如果你要安装`1.20.1`版本mc server，请先下载该版本的服务器文件，并创建对应文件夹

   ```
   /opt/minecraft/server/1.20.1/
   ```

2. **手动启动一次整合包**

   启动后一般会自动下载需要的文件，启动成功后手动关闭服务

   修改`/opt/minecraft/server/1,20,1/scriptrs/start.sh`

   将本整合包的启动指令添加到文件底

---

## 🛠️ 安装server

```bash
cd /opt/minecraft
./install.sh -o 1.20.1
```

将执行以下步骤：

- 检查并修改 `eula.txt` 与 `server.properties`
- 停止其他正在运行的mc server
- 注册systemd服务与开机自启动
- 注册自动备份任务

---

## 🚦 管理server

使用`manage.sh`可以对当前server进行以下管理操作

```bash
./manage.sh start     # 启动当前server
./manage.sh stop      # 停止当前server
./manage.sh backup    # 备份当前server
./manage.sh screen    # 进入server控制台
```

---

## 🧼 移除server

```bash
./uninstall.sh -o 1.20.1
```

将执行：

- 停止并禁用当前server
- 移除相关systemd服务
- 移除定时备份任务
- 删除server文件`/opt/minecraft/server/1.20.1`

⚠️ 备份档案**不會**被删除，仍保留在 `/storage/minecraft_backup/1.20.1/`

---

## 🗃️ 备份与还原

- 每日凌晨4：00自动备份，并重启server
- 备份文件路径 `/storage/minecraft_backup/<版本>/`
- 备份超过七日自动删除
- 每次 `stop` 时也会触发备份

---

## 📋 FAQ

**Q: 可以同时执行多个server吗？**  
A: 不可以，当前系统在启动新server时，会停止其他正在运行的版本。

**Q: 如何还原备份server？**  
A: 手动解压 `.tar.gz` 备份文件并导入`server`下，或新建版本文件夹后解压并执行 `install.sh -o <版本>`。
