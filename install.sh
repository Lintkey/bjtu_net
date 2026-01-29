#!/bin/bash

SCRIPT_DEST="$HOME/.local/bin"
SERVICE_DEST="$HOME/.config/systemd/user"

echo "开始安装 BJTU 校园网自动化工具..."

# 1. 创建目标目录
mkdir -p "$SCRIPT_DEST"
mkdir -p "$SERVICE_DEST"

cp "bjtu-auth.sh" "$SCRIPT_DEST/"
chmod +x "$SCRIPT_DEST/bjtu-auth.sh"

# 3. 移动 Systemd 单元文件
UNIT_FILES=("bjtu-needs-auth.target" "bjtu-login.service" "bjtu-monitor.service")
for file in "${UNIT_FILES[@]}"; do
    cp "$file" "$SERVICE_DEST/"
done

systemctl --user daemon-reload

# 建立 login service 与 target 的 WantedBy 关联
systemctl --user enable bjtu-login.service

# 启动监控服务
systemctl --user enable bjtu-monitor.service
systemctl --user restart bjtu-monitor.service