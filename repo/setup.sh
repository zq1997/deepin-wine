#!/bin/sh
set -e

GPG_KEY_FILE="/etc/apt/trusted.gpg.d/i-m.dev.gpg"
LIST_FILE="/etc/apt/sources.list.d/deepin-wine.i-m.dev.list"
SITE="https://deepin-wine.i-m.dev"
NEED_UPDATE=0

if ! { dpkg --print-architecture && dpkg --print-foreign-architectures; } | grep -q i386; then
  echo "正在添加i386架构"
  dpkg --add-architecture i386
  NEED_UPDATE=1
fi

if [ ! -f $GPG_KEY_FILE ]; then
  echo "正在添加公钥"
  wget -q -O $GPG_KEY_FILE "${SITE}/i-m.dev.gpg"
  NEED_UPDATE=1
fi

if [ ! -f "$LIST_FILE" ]; then
  echo "正在添加软件源"
  echo "deb ${SITE}/deepin/ ./" | tee $LIST_FILE
  if ! apt-cache policy libjpeg62-turbo:i386 | grep -qP ' +500 (?!https://deepin-wine\.i-m\.dev/)'; then
    echo "deb ${SITE}/ubuntu-fix/ ./" | tee -a $LIST_FILE
  fi
  NEED_UPDATE=1
fi

if [ $NEED_UPDATE -eq 1 ]; then
  echo "正在刷新软件源"
  apt-get update
fi
