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
LOGOUT_PATH="/eportal/portal/logout?callback=drcom"

while true
do
  res=`curl -s "https://${DOMAIN}:${HTTPS_PORT}${LOGOUT_PATH}&login_method=1"`
  echo $res
  json="${res#*\(}"
  json="${json%\)*}"
  STATUS=`echo $json | jq ".result"`
  RET_CODE=`echo $json | jq ".ret_code"`
  # result==1 注销成功
  if [ -z "$STATUS" ]
  then
    sleep 0.5s
  elif [ $STATUS -eq 1 ]
  then
    break
  fi
done
