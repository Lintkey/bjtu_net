#!/bin/sh

# 配置参数
DOMAIN="login.bjtu.edu.cn"
HTTPS_PORT=802
LOGIN_PATH="/eportal/portal/login?callback=drcom"
ONLINE_CHECK_PATH="/eportal/portal/online_list?callback=drcom"
ENABLE_NOTIFY=${ENABLE_NOTIFY:-0}

# 日志函数
log_message() {
    local message="$1"
    local level="$2"
    echo "$message"
    
    if [ $ENABLE_NOTIFY -ne 0 ] && [ -n "$level" ]; then
        notify-send "BJTU自动登录" "$message" -u "$level" 2>/dev/null || true
    fi
}

dependencies=('curl')
# 检查依赖
check_dependencies() {
    if [ ! command -v notify-send > /dev/null 2>&1 ] || [ -z "$DISPLAY" ]; then
        ENABLE_NOTIFY=0
        log_message "Warn: 桌面通知不可用，已禁用桌面通知"
    fi
    
    for cmd in "${dependencies[*]}"; do
        if ! command -v $cmd > /dev/null 2>&1; then
            log_message "Error: 缺少依赖 $cmd" "critical"
            exit 1
        fi
    done
}

# 检查在线状态
check_online_status() {
    local response result
    response=$(curl -s --max-time 3 "https://${DOMAIN}:${HTTPS_PORT}${ONLINE_CHECK_PATH}" 2>/dev/null)
    while [ -z "$response" ]; do
        log_message "在线状态检查: 请求失败"
        sleep 1
        response=$(curl -s --max-time 3 "https://${DOMAIN}:${HTTPS_PORT}${ONLINE_CHECK_PATH}" 2>/dev/null)
    done    
    
    result=$(echo "$response" | grep -o '"result":[0-9]*' | cut -d: -f2)
    if [ -n "$result" ]; then
        if [ "$result" -ne 0 ]; then
            log_message "在线状态检查: 已登录 (result=${result})"
            return 0
        else
            log_message "在线状态检查: 未登录 (result=${result})"
            return 1
        fi
    else
        log_message "在线状态检查: 无法解析响应"
        return 1
    fi
}

# 检测校园网连接 (10次循环重试)
check_drcom_network() {
    local max_attempts=10
    local attempt=1
    local connection result
    log_message "正在检测校园网连接..."
    
    while [ $attempt -le $max_attempts ]; do
        response=$(curl -s --max-time 4 "https://${DOMAIN}:${HTTPS_PORT}${ONLINE_CHECK_PATH}" 2>/dev/null)
        result=$(echo "$response" | grep -o '"result":[0-9]*' | cut -d: -f2)
        if [ -n "$result" ]; then
            if [ "$result" -ne 0 ]; then
                log_message "检测到校园网连接"
                return 0
            fi
        fi
        [ $((attempt % 5)) -eq 0 ] && log_message "第${attempt}次检测: 未连接到校园网"
        sleep 2
        attempt=$((attempt + 1))
    done

    log_message "未检测到校园网连接"
    return 1
}

# 登录逻辑
login_to_drcom() {
    local max_retries=5
    local retry_count=0
    
    if check_online_status; then
        log_message "当前已在线，无需登录" "normal"
        return 0
    fi
    
    while [ $retry_count -lt $max_retries ]; do
        log_message "正在登录校园网 (第$((retry_count + 1))次尝试)..."
        
        curl -s --max-time 3 "https://${DOMAIN}:${HTTPS_PORT}${LOGIN_PATH}&login_method=1&user_account=${ACCOUNT}&user_password=${PASSWORD}" >/dev/null 2>&1
        sleep 2
        
        if check_online_status; then
            log_message "登录成功" "normal"
            return 0
        else
            log_message "登录失败，正在重试..."
            retry_count=$((retry_count + 1))
        fi
    done

    log_message "Error: 登录失败，超过最大重试次数" "critical"
    return 1
}

# 监控逻辑 (与 systemd target 交互)
monitor_mode() {
    log_message "监控服务启动..."
    while true; do
        if ! check_drcom_network; then
            log_message "确认未连接校园网，退出监控"
            systemctl --user stop bjtu-needs-auth.target
            exit 0
        fi
        if ! check_online_status; then
            if ! systemctl --user is-active --quiet bjtu-needs-auth.target; then
                log_message "检测到断开，启动 Target"
                systemctl --user start bjtu-needs-auth.target
            fi
        else
            if systemctl --user is-active --quiet bjtu-needs-auth.target; then
                systemctl --user stop bjtu-needs-auth.target
            fi
        fi
        sleep 10
    done
}

check_dependencies
case "$1" in
    login)   login_to_drcom ;;
    monitor) monitor_mode ;;
    *)       exit 1 ;;
esac