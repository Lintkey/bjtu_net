#!/bin/sh

# 配置参数
DOMAIN="login.bjtu.edu.cn"
HTTP_PORT=801
HTTPS_PORT=802
# 还有个logout_path，有兴趣可以自己开F12抓包看看🐶
LOGIN_PATH="/eportal/portal/login?callback=drcom"
ONLINE_CHECK_PATH="/eportal/portal/online_list?callback=drcom"
CONNECTIONS_LIST=("web.wlan.bjtu")
ENABLE_NOTIFY=1

# 从命令行参数获取账户信息
ACCOUNT="$1"
PASSWORD="$2"

# 验证参数
if [ -z "$ACCOUNT" ] || [ -z "$PASSWORD" ]; then
    echo "使用方法: $0 <账号> <密码>"
    exit 1
fi

# 日志函数
log_message() {
    local message="$1"
    local level="$2"
    
    echo "$message"
    
    # 如果有第二个参数，发送通知
    if [ $ENABLE_NOTIFY -ne 0 ] && [ -n "$level" ]; then
        notify-send "BJTU自动登录" "$message" -u "$level"
    fi
}

# 检查依赖
check_dependencies() {
    # 检查桌面通知支持
    if [ ! command -v notify-send &> /dev/null ] || [ -z "$DISPLAY" ]; then
        ENABLE_NOTIFY=0
        log_message "Warn: 桌面通知不可用，已禁用桌面通知"
    fi
    
    # 检查必需命令
    for cmd in nmcli curl; do
        if ! command -v $cmd &> /dev/null; then
            log_message "Error: 缺少依赖 $cmd" "critical"
            exit 1
        fi
    done
}

# 检查在线状态
check_online_status() {
    local response result request_count

    response=$(curl -s --max-time 3 "https://${DOMAIN}:${HTTPS_PORT}${ONLINE_CHECK_PATH}" 2>/dev/null)
    while [ -z "$response" ]; do
        log_message "在线状态检查: 请求失败"
        sleep 1
        response=$(curl -s --max-time 3 "https://${DOMAIN}:${HTTPS_PORT}${ONLINE_CHECK_PATH}" 2>/dev/null)
    done
    
    # 提取result值，处理JSONP格式
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

# 检测校园网连接
check_drcom_network() {
    local max_attempts=10
    local attempt=1
    local connection
    
    log_message "正在检测校园网连接..."
    
    while [ $attempt -le $max_attempts ]; do
        connection=$(nmcli --fields=CONNECTION,DEVICE device 2>/dev/null)
        
        for conn in "${CONNECTIONS_LIST[*]}"; do
            if echo "$connection" | grep -q "$conn"; then
                log_message "检测到校园网连接" "normal"
                return 0
            fi
        done
        
        if [ $((attempt % 5)) -eq 0 ]; then
            log_message "第${attempt}次检测: 未连接到校园网"
        fi
        
        sleep 2
        attempt=$((attempt + 1))
    done
    
    log_message "未检测到校园网连接"
    return 1
}

# 登录校园网
login_to_drcom() {
    local max_retries=3
    local retry_count=0
    
    # 先检查是否已经在线
    if check_online_status; then
        log_message "当前已在线，无需登录" "normal"
        return 0
    fi
    
    while [ $retry_count -lt $max_retries ]; do
        log_message "正在登录校园网 (第$((retry_count + 1))次尝试)..."
        
        # 发送登录请求，不关心返回结果
        curl -s --max-time 3 \
            "https://${DOMAIN}:${HTTPS_PORT}${LOGIN_PATH}&login_method=1&user_account=${ACCOUNT}&user_password=${PASSWORD}" >/dev/null 2>&1
        
        # 等待登录生效
        sleep 2
        
        # 检查登录是否成功
        if check_online_status; then
            log_message "登录成功" "normal"
            return 0
        else
            log_message "登录失败，正在重试..."
            sleep 2
            retry_count=$((retry_count + 1))
        fi
    done
    
    log_message "Error: 登录失败，超过最大重试次数" "critical"
    return 1
}

# 主函数
main() {
    check_dependencies
    
    # 检测网络并登录
    if check_drcom_network; then
        login_to_drcom
    fi
}

main