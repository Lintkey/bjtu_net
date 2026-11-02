#!/bin/sh

SCRIPT_DEST="$HOME/.local/bin"
SERVICE_DEST="$HOME/.config/systemd/user"
ENV_FILE="$HOME/.config/bjtu-net.env"

if [ -z "$1" ]; then
    echo "用法: $0 <账号> [密码]"
    exit 1
fi

ACCOUNT="$1"
PASSWORD="$2"

if [ -z "$PASSWORD" ]; then
    printf '密码: ' >&2
    if [ -t 0 ]; then
        stty -echo
        read -r PASSWORD
        stty echo
        echo >&2
    else
        read -r PASSWORD
    fi
fi

if [ -z "$ACCOUNT" ] || [ -z "$PASSWORD" ]; then
    echo "账号或密码为空" >&2
    exit 1
fi

echo "开始安装 BJTU 校园网自动连接工具..."

mkdir -p "$SCRIPT_DEST" "$SERVICE_DEST"

printf 'ACCOUNT=%s\nPASSWORD=%s\n' "$ACCOUNT" "$PASSWORD" > "$ENV_FILE"
chmod 600 "$ENV_FILE"

cp "bjtu-auth.sh" "$SCRIPT_DEST/"
chmod +x "$SCRIPT_DEST/bjtu-auth.sh"

for file in "bjtu-needs-auth.target" "bjtu-login.service" "bjtu-monitor.service"; do
    cp "$file" "$SERVICE_DEST/"
done

systemctl --user daemon-reload

systemctl --user enable bjtu-login.service
systemctl --user enable bjtu-monitor.service
systemctl --user restart bjtu-monitor.service

echo "安装完成"
