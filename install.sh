#!/bin/sh

SCRIPT_DEST="$HOME/.local/bin"
SERVICE_DEST="$HOME/.config/systemd/user"

echo "开始安装 BJTU 校园网自动连接工具..."

mkdir -p "$SCRIPT_DEST"
mkdir -p "$SERVICE_DEST"

cp "bjtu-auth.sh" "$SCRIPT_DEST/"
chmod +x "$SCRIPT_DEST/bjtu-auth.sh"

UNIT_FILES=("bjtu-needs-auth.target" "bjtu-login.service" "bjtu-monitor.service")
for file in "${UNIT_FILES[@]}"; do
    cp "$file" "$SERVICE_DEST/"
done

systemctl --user daemon-reload

# 启用以创建WantBy关系
systemctl --user enable bjtu-login.service

# 启动监控服务
systemctl --user enable bjtu-monitor.service
systemctl --user restart bjtu-monitor.service

echo "安装完成"