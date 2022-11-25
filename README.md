# deepin-wine

> deepin-wine环境与应用在Debian/Ubuntu上的移植仓库
>
> 使用deepin官方原版软件包
>
> 安装QQ/微信只需要两条命令



跳转查看

[快速开始](#快速开始)

[常见问题](#常见问题)

[卸载清理](#卸载清理)

[高级文档](#高级文档)

[版权与致谢](#版权与致谢)



## 快速开始

1. 添加仓库

   首次使用时，你需要运行如下一条命令将移植仓库添加到系统中。

   ```sh
   wget -O- https://deepin-wine.i-m.dev/setup.sh | sh
   ```

2. 应用安装

   自此以后，你可以像对待普通的软件包一样，使用`apt-get`系列命令进行各种应用安装、更新和卸载清理了。

   比如安装微信只需要运行下面的命令，

   ```sh
   sudo apt-get install com.qq.weixin.deepin
   ```

   将`com.qq.weixin.deepin`替换为下列包名，可以继续安装其他应用：

   |   应用   |            包名            |
   | :------: | :------------------------: |
   |   微信   |    com.qq.weixin.deepin    |
   |    QQ    |      com.qq.im.deepin      |
   |   TIM    |    com.qq.office.deepin    |
   |   钉钉   |    com.dingtalk.deepin     |
   | 阿里旺旺 | com.taobao.wangwang.deepin |
   |  QQ音乐  |    com.qq.music.deepin     |
   |  QQ视频  |    com.qq.video.deepin     |
   |  爱奇艺  |      com.iqiyi.deepin      |

   **完整列表参见[https://deepin-wine.i-m.dev](https://deepin-wine.i-m.dev)。**
   
3. 遇到问题？

   别急，也许[issue](https://github.com/zq1997/deepin-wine/issues/)里面也有很多人碰到了和你类似的问题，搜一搜也许就有解决方案。



## 常见问题

### 没有应用图标

注销-登入用户即可，可注销或重启。

### 字体相关问题

新版本的deepin-wine似乎已经能比较好地解决字体问题了，一般装上去就能用了。

[字体问题集中讨论区](https://github.com/zq1997/deepin-wine/issues/15)讨论的是以前的版本，谨慎参考。

### QQ/微信托盘小图标显示异常

这和桌面环境有关，Linux发行版桌众多，面布局千奇百怪，并不是每一个都具有与【Windows系统托盘】对应的控件。

- 如果是Linux Mint的Cinnamon桌面环境，那基本能直接正常使用。（不过多显示屏情况下有些问题，需要把左侧显示屏的设置为主屏幕）

- 如果是Ubuntu的Gnome桌面环境，任务栏就很别扭，成了个悬浮对话框，可以安装Gnome Shell插件

   [TopIcons Plus](https://extensions.gnome.org/extension/1031/topicons/)解决问题。

  至于插件安装的方法，出门左转搜索引擎。比较快的一种方法是`sudo apt-get install gnome-shell-extension-top-icons-plus gnome-tweaks`，注销重新登录后在tweak工具中启用对应插件。

- KDE之类，我没试过，请自行探索。

### QQ头像无法加载

可能是IPv6问题，见[讨论区](https://github.com/zq1997/deepin-wine/issues/286)。

### QQ截图无法使用

见[讨论区](https://github.com/zq1997/deepin-wine/issues/31)。

### 微信启动后屏幕上有个黑框

见[讨论区](https://github.com/zq1997/deepin-wine/issues/24)。

### 没办法进行QQ远程/视频通话

视频相关的功能对硬件和底层驱动的依赖很大，Wine毕竟不是Windows，100%完美模拟是不可能的。

### 安装依赖问题

`依赖: xxxx 但是它将不会被安装`

`Depends: xxxx but it is not going to be installed`

这说明系统试图安装`xxxx`但是无法装上去，这一般是你已有的软件源配置问题、或者安装过了一些有冲突的东西。

那么，你应该试着安装`xxxx`，执行`apt-get install -s xxxx`（不需sudo，只是模拟，放心测试），它一般又会接着告诉你`依赖: yyyy 但是它将不会被安装`，说明更底层的错误出在了`yyyy`，不断尝试，找到罪魁祸首，可以尝试先解决这个罪魁祸首。

### 更多问题

1. 多测试，先排除无关因素，很多问题可能是一个删除清理/重启/重装就能解决的事。

2. Linux不是Windows，Wine也不是Windows，不要期待100%丝滑享受。

3. 善用搜索引擎，学会查找已有资料，即使是百度和CSDN这些垃圾信息成堆的网站也是有不少有用的东西。

4. 仓库的issues中有些名为【xxxx集中讨论区】的帖子，大家都列出了各种原因探讨和解决方案了，值得一看。

5. 新的欢迎提issue，但是也请提供Linux发行版名称与版本号、桌面环境、APT源列表等信息。



## 卸载清理

卸载与清理按照层次从浅到深可以分为如下四个层级。

如果只是想清除APP账户配置啥的那么请按照`1`清理；如果你发现程序奔溃之类的，请按照`1-2`清理；如果需要卸载APP，按照`1-2-3`清理；如果你想把一切回到最初的起点，执行`1-2-3-4`清理。

1. 清理应用运行时目录

   例如QQ/TIM会把帐号配置、聊天文件等保存`~/Documents/Tencent Files`目录下，而微信是`~/Documents/WeChat Files`，删除这些文件夹以移除帐号配置等数据。

2. 清理wine容器

   deepin-wine应用第一次启动后会在`~/.deepinwine/`目录下生成一个文件夹（名字各不相同）用于存储wine容器（可以理解我一个“Windows虚拟机”），如果使用出了问题，可以试试删除这个目录下对应的子文件夹。

3. 卸载软件包

   执行`sudo apt-get purge --autoremove <包名>`命令把你安装过的包给移除。

4. 移除软件仓库

   ```sh
   sudo rm /etc/apt/preferences.d/deepin-wine.i-m.dev.pref \
           /etc/apt/sources.list.d/deepin-wine.i-m.dev.list \
           /etc/profile.d/deepin-wine.i-m.dev.sh
   sudo apt-get update
   ```



## 高级文档

*如果你是资深Linux用户，可以了解一下这部分。*

### 移植原理

Deepin把QQ/微信之类的deepin-wine应用打包放在了deepin仓库中，因此先提取出这些应用及依赖的软件包，再减去Debian/Ubuntu等发行版官方仓库中固有的软件包，就可以打包成一个移植于对应发行版的“差量仓库”，然后把这个差量仓库的索引发布出来即可，其中的`.deb`可以直接重定向到Deepin官方仓库地址去。

### 配置过程详解


环境配置其实就是添加我自行构建的软件仓库为源，具体包括以下几步。

1. 添加i386架构

   因为deepin-wine相关的软件包都是i386的，而现在的系统基本是64位的，所以需要先添加i386架构支持。

   通过`dpkg --print-architecture`和`dpkg --print-foreign-architectures`命令查看系统原生和额外添加的架构支持，如果输出结果不含`i386`，则需要手动添加支持。

   ```sh
   sudo dpkg --add-architecture i386
   ```

2. 添加软件源

   创建`/etc/apt/sources.list.d/deepin-wine.i-m.dev.list`文件，编辑其内容如下，

   ```
   deb [trusted=yes] https://deepin-wine.i-m.dev /
   ```

3. 设置源优先级

   这步是为了降低本仓库的优先级，尽可能使用发行版仓库中固有的软件包而不是Deepin仓库的软件包，最小化风险。

   创建`/etc/apt/preferences.d/deepin-wine.i-m.dev.pref`文件，编辑其内容如下，

   ```
   Package: *
   Pin: release l=deepin-wine
   Pin-Priority: 200
   ```

4. 添加XDG_DATA_DIRS配置

   这是为了让应用图标能正常显示，创建`/etc/profile.d/deepin-wine.i-m.dev.sh`文件，编辑其内容如下，

   ```sh
   XDG_DATA_DIRS=${XDG_DATA_DIRS:-/usr/local/share:/usr/share}
   for deepin_dir in /opt/apps/*/entries; do
      if [ -d "$deepin_dir/applications" ]; then
         XDG_DATA_DIRS="$XDG_DATA_DIRS:$deepin_dir"
      fi
   done
   export XDG_DATA_DIRS
   ```

5. 刷新软件源

   ```sh
   sudo apt-get update
   ```



## 版权与致谢

这个git仓库中的代码只包括了移植版软件仓库的构建工具，最后仓库中软件包的下载地址会被301重定向到deepin的官方仓库（或者镜像）中去，其版权由 [deepin](https://www.deepin.org/) 所有。

本项目受 [wszqkzqk/deepin-wine-ubuntu](https://github.com/wszqkzqk/deepin-wine-ubuntu) 项目启发，改进了一下安装方式，因此兼容原项目，已经按照deepin-wine-ubuntu项目安装好后，依然可以再按此项目进行配置，可以更方便地进行后续更新。
