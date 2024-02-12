FROM ubuntu:latest
MAINTAINER Sciroccogti(Based on https://github.com/zq1997/deepin-wine)

ADD container /root/

ENV DEBIAN_FRONTEND=noninteractive
RUN apt update
RUN apt install wget locales ttf-wqy-zenhei sudo tzdata -y
RUN wget -O- https://deepin-wine.i-m.dev/setup.sh | sh
ENV LC_CTYPE=zh_CN.UTF-8 \
    XMODIFIERS="@im=fcitx"
RUN \
  locale-gen en_US.UTF-8 zh_CN.UTF-8 \
  zh_CN.GBK && \
  update-locale LANG=zh_CN.UTF-8

RUN apt install com.qq.im.deepin -y
RUN apt clean && apt autoclean

WORKDIR /root

CMD ["/bin/bash"]