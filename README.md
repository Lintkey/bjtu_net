# bjtu_net

## 使用方法

### # 直接运行

下载或者复制仓库中的 `bjtu-login.sh` 到合适的地方，然后运行：

```sh
bash bjtu-login.sh '账号' '密码'
```

可以在 `.bashrc` 里添加 `alias`，方便登录。

### # 配合 `systemd`，自动登录+断线重连

克隆该仓库，运行安装脚本，按提示输入账号和密码即可安装至当前用户的 `systemd` 服务中并自动启动：

```sh
bash install.sh
```

如需卸载直接删除对应文件即可，记得 `systemctl --user daemon-reload` 清理服务。

### # 注意事项

如果你开启了DNS覆写，在DNS覆写选项里给直连DNS加上 `system`(直连时使用系统DNS，没登录前无法访问其他DNS)。

> 或者干脆关了DNS覆写，现在订阅基本都自带指定DNS，默认直连就走 `system`。

也可以单独给 `login.bjtu.edu.cn` 指定DNS，海淀校区的DNS为 `202.112.144.236` 和 `202.112.144.246`。

### # 其他

如果不想出现意外(比如临时改接口了，或者协议有变)，也可以选择让AI帮连 `phone.wlan.bjtu`，但是 `phone.wlan.bjtu` 的延迟和波动会比较大，不推荐，仅适合办公。
