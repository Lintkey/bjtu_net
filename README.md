# bjtu_net



## 使用方法

下载或者复制仓库中的 `bjtu_login.sh` 到合适的地方，使用 `chmod +x bjtu_login.sh` 添加执行权限。

然后运行以下命令即可联网

```sh
./bjtu_login.sh '账号' '密码'
# or
sh ./bjtu_login.sh '账号' '密码'
```

可以在 `.bashrc` 里添加 `alias`，方便登录。关于如何定时、自动登录，请参阅下面的Tips。

## 说明

脚本执行了两次登录，是因为在改变地址时校园网系统有概率报假消息(显示已在线，原因未知)，第二次登录才能正常联网。

## Tips

### # 如何定时/开机自动执行脚本

google关键词搜 `systemd 定时/自动执行脚本`，网上已经有很多教程了...这里给个 `timer` 的例子

可以考虑创建个timer定期执行特定服务:

```ini
[Unit]
Description=Login to BJTU Net every 1h

[Timer]
OnStartupSec=1m             # timer启动后等1min再启动服务
OnUnitActiveSec=1h          # 此后每隔1h启动一次服务
Unit=bjtu_in.service

[Install]
WantedBy=multi-user.target  # 系统基础服务加载好后启动该timer
```

> 别忘了启用(`enable`)这个 `timer`

### # 如何在Clash开启TUN的情况下使用该脚本

在DNS覆写选项里给直连DNS加上system(使用系统DNS)，然后手动指定校园网DNS，默认为 `202.112.144.236` 和 `202.112.144.246`。

> 直连DNS别只写system...加上你觉得好用的DNS(比如114、谷歌、阿里)