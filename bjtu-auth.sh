#!/bin/sh

# 配置参数
DOMAIN="login.bjtu.edu.cn"
PORT=802
LOGIN_PATH="/eportal/portal/login?callback=drcom&login_method=1"
ONLINE_CHECK_PATH="/eportal/portal/online_list?callback=drcom"
MAX_RETRIES=5
ENABLE_NOTIFY=${ENABLE_NOTIFY:-0}

# 日志函数
log_message() {
    local message="$1"
    local level="$2"
    echo "$message"

    if [ "$ENABLE_NOTIFY" -ne 0 ] && [ -n "$level" ]; then
        notify-send "BJTU自动登录" "$message" -u "$level" 2>/dev/null || true
    fi
}

# 检查依赖
check_dependencies() {
    if ! command -v notify-send >/dev/null 2>&1 || [ -z "$DISPLAY" ]; then
        ENABLE_NOTIFY=0
        log_message "Warn: 桌面通知不可用，已禁用桌面通知"
    fi

    if ! command -v curl >/dev/null 2>&1; then
        log_message "Error: 缺少依赖 curl" "critical"
        exit 1
    fi
}

# 从 JSONP 响应里取 result
json_result() {
    printf '%s' "$1" | grep -o '"result":[0-9]*' | head -n1 | cut -d: -f2
}

# 检查在线状态
#   0 = 在线   1 = 离线   2 = 状态未知（无响应/无法解析）
check_online_status() {
    local response result
    response=$(curl -s --max-time 4 "https://${DOMAIN}:${PORT}${ONLINE_CHECK_PATH}" 2>/dev/null)

    if [ -z "$response" ]; then
        log_message "Warn: online_list 无响应"
        return 2
    fi

    result=$(json_result "$response")
    case "$result" in
        1) return 0 ;;
        0) return 1 ;;
        *)
            log_message "Warn: 无法解析 online_list 响应: $(printf '%s' "$response" | cut -c1-160)"
            return 2
            ;;
    esac
}

# 检测校园网连接（能拿到 result 字段即视为在校园网）
check_drcom_network() {
    local attempt=1
    local response
    log_message "Info: 正在检测校园网连接..."

    while [ "$attempt" -le 10 ]; do
        response=$(curl -s --max-time 4 "https://${DOMAIN}:${PORT}${ONLINE_CHECK_PATH}" 2>/dev/null)
        if printf '%s' "$response" | grep -q '"result"'; then
            log_message "Info: 检测到校园网连接"
            return 0
        fi
        [ $((attempt % 5)) -eq 0 ] && log_message "Info: 第${attempt}次检测: 未连接到校园网"
        sleep 2
        attempt=$((attempt + 1))
    done

    log_message "Info: 未检测到校园网连接"
    return 1
}

# 登录逻辑：按登录接口返回的 result 判定
login_to_drcom() {
    local attempt=1
    local response result msg delay

    if [ -z "$ACCOUNT" ] || [ -z "$PASSWORD" ]; then
        log_message "Error: 未设置 ACCOUNT / PASSWORD" "critical"
        return 1
    fi

    check_online_status
    if [ $? -eq 0 ]; then
        log_message "Info: 当前已在线，无需登录" "normal"
        return 0
    fi

    while [ "$attempt" -le "$MAX_RETRIES" ]; do
        log_message "Info: 正在登录校园网 (第${attempt}次尝试)..."

        response=$(curl -s --max-time 10 -G "https://${DOMAIN}:${PORT}${LOGIN_PATH}" \
            --data-urlencode "user_account=${ACCOUNT}" \
            --data-urlencode "user_password=${PASSWORD}" 2>/dev/null)

        result=$(json_result "$response")
        if [ "$result" = "1" ]; then
            log_message "Info: 登录成功" "normal"
            return 0
        fi

        msg=$(printf '%s' "$response" | grep -o '"msg":"[^"]*"' | head -n1 | cut -d'"' -f4)
        [ -z "$msg" ] && msg=$(printf '%s' "$response" | grep -o '"msg":[^,}]*' | head -n1 | cut -d: -f2- | tr -d '"')
        log_message "Warn: 登录未成功 (result=${result:-无响应}, msg=${msg:-无})"

        attempt=$((attempt + 1))
        if [ "$attempt" -le "$MAX_RETRIES" ]; then
            delay=$((attempt * 3))
            sleep "$delay"
        fi
    done

    log_message "Error: 登录失败，超过最大重试次数" "critical"
    return 1
}

# 监控
monitor_mode() {
    log_message "Info: 监控服务启动..."
    while true; do
        if ! check_drcom_network; then
            log_message "Info: 确认未连接校园网，退出监控"
            systemctl --user stop bjtu-needs-auth.target
            exit 0
        fi

        check_online_status
        case $? in
            0)
                if systemctl --user is-active --quiet bjtu-needs-auth.target; then
                    systemctl --user stop bjtu-needs-auth.target
                fi
                ;;
            1)
                if ! systemctl --user is-active --quiet bjtu-needs-auth.target; then
                    log_message "Info: 检测到未登录校园网，唤醒登录服务"
                    systemctl --user start bjtu-needs-auth.target
                fi
                ;;
            *)
                # 状态未知时不触发登录，避免门户抖动导致登录风暴
                log_message "Warn: 在线状态未知，跳过本轮"
                ;;
        esac
        sleep 16
    done
}

check_dependencies
case "$1" in
    login)   login_to_drcom ;;
    monitor) monitor_mode ;;
    *)       echo "用法: $0 {login|monitor}" ;;
esac
