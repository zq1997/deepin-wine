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
sudo tee "$LIST_FILE" >/dev/null << "EOF"
deb [trusted=yes] https://deepin-wine.i-m.dev /
EOF

# 设置优先级
sudo tee "/etc/apt/preferences.d/deepin-wine.i-m.dev.pref" >/dev/null << "EOF"
Package: *
Pin: release l=deepin-wine
Pin-Priority: 200
EOF

# 添加XDG_DATA_DIRS配置，使得应用图标能正常显示
sudo tee "/etc/profile.d/deepin-wine.i-m.dev.sh" >/dev/null << "EOF"
XDG_DATA_DIRS=${XDG_DATA_DIRS:-/usr/local/share:/usr/share}
for deepin_dir in /opt/apps/*/entries; do
    if [ -d "$deepin_dir/applications" ]; then
        XDG_DATA_DIRS="$XDG_DATA_DIRS:$deepin_dir"
    fi
done
export XDG_DATA_DIRS
EOF

# 刷新软件源
sudo apt-get update --no-list-cleanup -o Dir::Etc::sourcelist="$LIST_FILE" -o Dir::Etc::sourceparts="-"

printf "
\033[32m大功告成，现在可以试试安装更新deepin-wine软件了，如：
微信：sudo apt-get install com.qq.weixin.deepin
QQ：sudo apt-get install com.qq.im.deepin
钉钉：sudo apt-get install com.dingtalk.deepin
\033[33;1m由于新版变化，安装完成后需要注销重登录才能正常显示应用图标。
\033[36m如果觉得有用，请到 https://github.com/zq1997/deepin-wine 点个star吧。
\033[0m"
