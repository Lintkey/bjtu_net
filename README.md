# bjtu_net

## 使用方法

### # 直接运行

下载或者复制仓库中的 `bjtu_login.sh` 到合适的地方，使用 `chmod +x bjtu_login.sh` 添加执行权限。

然后运行以下命令即可联网

```sh
./bjtu_in.sh '账号' '密码'
# or
sh ./bjtu_login.sh '账号' '密码'
```

可以在 `.bashrc` 里添加 `alias`，方便登录。

### # 配合 `systemd`，自动登录+断线重连

克隆该仓库，修改 `bjtu-login.service` 中的账号密码参数，运行 `install.sh` 脚本，会安装至当前用户的服务中。

卸载直接删除对应文件即可，记得 `systemctl --user daemon-reload`。

### # 如何开启TUN的情况下使用该脚本

在DNS覆写选项里给直连DNS加上system(使用系统DNS)，然后手动指定校园网DNS，默认为 `202.112.144.236` 和 `202.112.144.246`。

> 直连DNS别只写system...加上你觉得好用的DNS(比如114、谷歌、阿里)

或者单独给 `login.bjtu.edu.cn` 指定DNS。