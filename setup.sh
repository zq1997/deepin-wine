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
TIM：sudo apt-get install com.qq.office.deepin
钉钉：sudo apt-get install com.dingtalk.deepin
完整列表见 https://deepin-wine.i-m.dev/
\033[31;1m
\033[5m🌟\033[25m 安装后需要注销重登录才能显示应用图标。
\033[5m🌟\033[25m 无法安装？无法启动？无法正常使用？切记先去github主页看【常见问题】章节，再找找相关issue，也许早已经有了解决方案了。

\033[36;1m如果觉得有用，不妨来给项目加个star：\033[25mhttps://github.com/zq1997/deepin-wine
\033[0m"
