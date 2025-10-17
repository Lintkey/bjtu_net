#!/bin/sh
# 关闭代理
unset no_proxy
unset all_proxy
unset http_proxy
unset https_proxy

# 扩展参数
DOMAIN="login.bjtu.edu.cn"
HTTP_PORT=801
HTTPS_PORT=802
# 还有个logout_path，有兴趣可以自己开F12抓包看看🐶
LOGIN_PATH="/eportal/portal/login?callback=drcom"

# 从命令行参数获取账户信息
ACCOUNT="$1"
PASSWORD="$2"

sleep 1s
curl -s "https://${DOMAIN}:${HTTPS_PORT}${LOGIN_PATH}&login_method=1&user_account=${ACCOUNT}&user_password=${PASSWORD}"
echo

sleep 1s
curl -s "https://${DOMAIN}:${HTTPS_PORT}${LOGIN_PATH}&login_method=1&user_account=${ACCOUNT}&user_password=${PASSWORD}"
echo

sleep 1s
curl -s "https://${DOMAIN}:${HTTPS_PORT}/eportal/portal/online_list?callback=drcom"
echo
