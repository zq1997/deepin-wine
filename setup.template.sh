#!/bin/sh
set -e

# 添加架构
ARCHITECTURE=$(dpkg --print-architecture && dpkg --print-foreign-architectures)
if ! echo "$ARCHITECTURE" | grep -qE 'amd64|i386'; then
    echo "必须amd64/i386机型才能移植deepin-wine"
    return 1
fi
dpkg --add-architecture i386

# 添加GPG公钥
GPG_KEY_CONTENT="<GPG_KEY_CONTENT>"
echo "$GPG_KEY_CONTENT" | base64 -d | tee /etc/apt/trusted.gpg.d/i-m.dev.gpg >/dev/null

# 添加软件源
REPO="https://deepin-wine.i-m.dev"
LIST_FILE="/etc/apt/sources.list.d/deepin-wine.i-m.dev.list"
echo "deb ${REPO}/deepin/ ./" | tee $LIST_FILE >/dev/null
if ! apt-cache madison libjpeg62-turbo | grep -qv $REPO; then
    echo "deb ${REPO}/ubuntu-fix/ ./" | tee -a $LIST_FILE >/dev/null
fi

# 刷新软件源
apt-get update -qq

echo "一切顺利，你可以用apt系列命令来安装直接安装QQ、微信了。"
echo "如果觉得有用的话，去 https://github.com/zq1997/deepin-wine 点个star吧😛"
