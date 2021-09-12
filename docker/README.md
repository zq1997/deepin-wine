# docker

仿照 [docker-wine-linux](https://github.com/RokasUrbelis/docker-wine-linux) 进行的容器化

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

目前测试仅有QQ音乐能短暂运行，一旦自动更新就闪退。。所以本方案目前没用

```bash
docker exec -i -t deepin-wine-25714 /bin/bash
```

```bash
apt install com.qq.im.deepin
```

```bash
"/opt/apps/com.qq.im.deepin/files/run.sh" -u %u
```