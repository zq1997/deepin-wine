#!/bin/sh
set -e

GPG_KEY_FILE="/etc/apt/trusted.gpg.d/i-m.dev.gpg"
LIST_FILE="/etc/apt/sources.list.d/deepin-wine.i-m.dev.list"
REPO="https://deepin-wine.i-m.dev"

NEED_UPDATE=0

ARCHITECTURE=$(dpkg --print-architecture && dpkg --print-foreign-architectures)
if ! echo "$ARCHITECTURE" | grep -q i386; then
    if ! echo "$ARCHITECTURE" | grep -q amd64; then
        echo "必须amd64/i386机型才能移植deepin-wine"
        return 1
    fi
    echo "正在添加i386架构"
    dpkg --add-architecture i386
    NEED_UPDATE=1
fi

if [ ! -f $GPG_KEY_FILE ]; then
    echo "正在添加公钥"
    wget -qO $GPG_KEY_FILE "${REPO}/i-m.dev.gpg"
    NEED_UPDATE=1
fi

if [ ! -f $LIST_FILE ]; then
    echo "正在添加软件源"
    echo "deb ${REPO}/deepin/ ./" | tee $LIST_FILE
    # 这里不能检查i386包，因为可能刚添加架构还没刷新出来
    PKG_CACHE="$(apt-cache policy libjpeg62-turbo)"
    if [ "$(echo "$PKG_CACHE" | grep $REPO)" = "$(echo "$PKG_CACHE" | grep -P "^ +500")" ]; then
        echo "针对ubuntu添加额外的修复包软件源"
        echo "deb ${REPO}/ubuntu-fix/ ./" | tee -a $LIST_FILE
        NEED_UPDATE=1
    fi
fi

if [ $NEED_UPDATE -eq 1 ]; then
    echo "正在刷新软件源"
    apt-get update -qq
fi

echo "准备工作完成，现在可以使用apt系列命令安装deepin版的QQ、微信了。"
echo "如果觉得有用的话，请到 https://github.com/zq1997/deepin-wine 点个star🥺"
