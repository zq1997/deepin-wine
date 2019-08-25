# deepin-wine

> deepin-wine环境与应用在Mint/Ubuntu/Debian上的移植仓库
>
> 使用deepin官方原版软件包
>
> 提供移植版软件仓库，安装QQ只需要`apt install`这么简单

## 安装教程

### 环境配置

初次使用需要先进行环境配置，可以选择自动配置或者手动配置。

#### 自动配置

运行如下一行命令即可

```sh
wget -qO- https://deepin-wine.i-m.dev/setup.sh | sudo sh
```

#### 手动配置

1. 添加i386架构

   因为deepin-wine相关的软件包都是i386的，而现在的系统基本是64位的，所以需要先添加i386架构支持。

   通过`dpkg --print-architecture`和`dpkg --print-foreign-architectures`命令查看系统原生和额外添加的架构支持，如果输出结果不含`i386`，则需要手动添加支持。

   ```sh
   sudo dpkg --add-architecture i386
   ```

2. 添加GPG公钥

   使用第三方软件仓库需要添加其公钥。

   下载[i-m.dev.gpg](https://deepin-wine.i-m.dev/i-m.dev.gpg)复制到`/etc/apt/trusted.gpg.d/`目录即可，或者直接运行

   ```sh
   wget -q -O /etc/apt/trusted.gpg.d/i-m.dev.gpg "https://deepin-wine.i-m.dev/i-m.dev.gpg"
   ```

3. 添加软件源

   创建`/etc/apt/sources.list.d/deepin-wine.i-m.dev.list`文件，并先添加如下内容，

   ```
   deb https://deepin-wine.i-m.dev/deepin/ ./
   ```

   （Debian跳过此条，）如果是Ubuntu/Mint等，还需要继续添加如下内容，

   ```
   deb https://deepin-wine.i-m.dev/ubuntu-fix/ ./
   ```

   第一条源的仓库中提供了deepin-wine环境与应用相关的软件包。

   第二条源是一个针对Ubuntu等系统的修复，因为这些系统上的`libjpeg62-turbo`已经被`libjpeg-turbo8`取代了，这一行对应的软件仓库中提供了一个虚拟`libjpeg62-turbo`包修复解决了这个问题。所以实际上，要不要添加第二行，可以观察`apt-cache policy libjpeg62-turbo:i386`命令的输出，看看原生的软件仓库中是否提供了`libjpeg62-turbo`包再行决定。

4. 刷新软件源

   ```sh
   sudo apt-get update
   ```

### 安装应用

就像普通的软件包一样，现在你可以使用`apt-get`系列命令进行各个deepin-wine应用安装、更新、卸载和依赖清理了。

如安装TIM，

```sh
sudo apt-get install deepin.com.qq.office
```

移植仓库会定期从官方仓库拉取更新，如果有更新，更新方法与一般软件无异

```sh
sudo apt-get update && sudo apt-get dist-upgrade
```

卸载，

```sh
sudo apt-get purge deepin.com.qq.office
```

残留依赖清理，

```sh
sudo apt-get autoremove
```

各个应用的软件包名如下：

|    应用    |          包名           |
| :--------: | :---------------------: |
|    TIM     |  deepin.com.qq.office   |
|     QQ     |    deepin.com.qq.im     |
|  QQ轻聊版  | deepin.com.qq.im.light  |
|    微信    |    deepin.com.wechat    |
|  百度网盘  |  deepin.com.baidu.pan   |
| 迅雷极速版 | deepin.com.thunderspeed |
|  Foxmail   |   deepin.com.foxmail    |
|   WinRAR   |  deepin.cn.com.winrar   |
|  360压缩   |   deepin.cn.360.yasuo   |

## 版权相关

这个git仓库中的代码只包括了移植版软件仓库的构建工具，最后仓库中软件包的下载地址会被301重定向到deepin的官方仓库（及镜像）中去，其版权由[deepin](https://www.deepin.com/)所有。

我只是个搬运工。

## 感谢

本工作是借鉴了[wszqkzqk](https://github.com/wszqkzqk)的[deepin-wine-ubuntu](https://github.com/wszqkzqk/deepin-wine-ubuntu)项目经验，原理基本相同，只是进行了一些包装可以让使用变得方便一点。（如果使用中遇到问题，也可以先去这个项目搜搜有没有相关issue。）