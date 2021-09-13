# docker

仿照 [docker-wine-linux](https://github.com/RokasUrbelis/docker-wine-linux) 进行的容器化，以期摆脱系统版本要求

目前在 Ubuntu 21.04 + Wayland 的测试情况：
|体验|应用|包名|情况|
|---|:--:|:---:|---|
|🟩|QQ|com.qq.im.deepin|可以运行，但初次启动没有鼠标，第二次运行闪退，随后正常|
|🟥|TIM|com.qq.office.deepin|TIM 内部报错|
|🟥|微信|com.qq.weixin.deepin|微信内部报错|
|🟥|QQ 音乐|com.qq.music.deepin|可以运行，但会触发自动更新，随后闪退|
|🟨|印象笔记|com.evernote.deepin|可以运行，启动界面部分字体缺失，基本不影响使用|
|🟩|阿里旺旺|com.taobao.wangwang.deepin|可以运行，但初次启动闪退，第二次运行闪退，随后正常|

## 1 安装 Docker

[官方教程](https://docs.docker.com/engine/install/ubuntu/)

使用 [官方便捷脚本](https://docs.docker.com/engine/install/ubuntu/#install-using-the-convenience-script) 安装：
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

参考 [Post-installation steps for Linux](https://docs.docker.com/engine/install/linux-postinstall/) 设置用户组：
```bash
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker 
```

验证安装：
```bash
docker run hello-world
```

## 2 编译镜像

```bash
git clone https://github.com/zq1997/deepin-wine
cd deepin-wine/docker
./run.sh
```

需要注意的是，第一次运行 `run.sh` 并成功编译后，会自动注释掉编译镜像部分的命令。

## 3 启动程序

以启动 QQ 为例：
```bash
# <ID> 为你的容器编号，可以通过 docker ps -a 查看
source ./start.sh -i <ID> com.qq.im.deepin
```

## 4 安装程序

目前默认仅安装了 QQ，其它程序可以手动安装。

以安装 印象笔记 为例：
```bash
# 进入容器
docker exec -it <ID> bash
# 安装印象笔记
apt install com.evernote.deepin
```

## 5 清理和卸载

使用 `clear.sh` 进行清理，会删除 `APP_PATH` 和容器

使用 `uninstall.sh` 移除容器和镜像
