#!/bin/sh
set -e

# 添加架构
ARCHITECTURE=$(dpkg --print-architecture && dpkg --print-foreign-architectures)
if ! echo "$ARCHITECTURE" | grep -qE 'amd64|i386'; then
    echo "必须amd64/i386机型才能移植deepin-wine"
    return 1
fi
echo "$ARCHITECTURE" | grep -qE 'i386' || sudo dpkg --add-architecture i386
sudo apt-get update

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

printf "\033[35;1m%s\033[0m\n" "不过，deepin-wine系列应用并不能完美地使用系统中已有的字体和字体配置，可能会有文字显示异常。
解决方法很多，你可以尝试把Windows里系统字体复制到Linux中来，或者安装后修改注册表之类的。
但如果你是个萌新，啥也不懂，还是推荐安装【文泉驿微米黑】字体，也可以解决问题。"

# 提示安装文泉驿微米黑字体
if [ -n "$(apt-cache madison fonts-wqy-microhei 2>/dev/null)" ] && \
        [ -z "$(dpkg --get-selections fonts-wqy-microhei 2>/dev/null | grep '\binstall$')" ] && \
        [ -r </dev/tty ]; then
    while true; do
        read -p "安装【文泉驿微米黑】字体？[Y/N] " CHOICE </dev/tty
        if [ "$CHOICE" = 'Y' ] || [ "$CHOICE" = 'y' ]; then
            sudo apt-get install fonts-wqy-microhei
            break
        elif [ "$CHOICE" = 'N' ] || [ "$CHOICE" = 'n' ]; then
            printf "取消了安装\n"
            break
        fi
    done
fi

printf "\033[36;1m%s\033[0m\n" "
如果觉得有用，请到 https://github.com/zq1997/deepin-wine 点个star吧"
