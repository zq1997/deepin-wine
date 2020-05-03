#!/bin/sh
set -e

# 添加架构
ARCHITECTURE=$(dpkg --print-architecture && dpkg --print-foreign-architectures)
if ! echo "$ARCHITECTURE" | grep -qE 'amd64|i386'; then
    echo "必须amd64/i386机型才能移植deepin-wine"
    return 1
fi
echo "$ARCHITECTURE" | grep -qE 'i386' || sudo dpkg --add-architecture i386

LIST_FILE="/etc/apt/sources.list.d/deepin-wine.i-m.dev.list"
# 添加软件源
echo "deb [trusted=yes] https://deepin-wine.i-m.dev /" | sudo tee "$LIST_FILE" >/dev/null

# 设置优先级
echo "Package: *
Pin: release l=deepin-wine
Pin-Priority: 200" | sudo tee "/etc/apt/preferences.d/deepin-wine.i-m.dev.pref" >/dev/null

# 刷新软件源
sudo apt-get update --no-list-cleanup -o Dir::Etc::sourcelist="$LIST_FILE" -o Dir::Etc::sourceparts="-"

printf "\033[32;1m%s\033[0m\n" "
大功告成，现在可以试试安装deepin-wine软件了，
安装/更新TIM：sudo apt-get install deepin.com.qq.office
安装/更新QQ：sudo apt-get install deepin.com.qq.im
安装/更新微信：sudo apt-get install deepin.com.wechat"

printf "\033[36;1m%s\033[0m\n" "
如果觉得有用，请到 https://github.com/zq1997/deepin-wine 点个star吧"
