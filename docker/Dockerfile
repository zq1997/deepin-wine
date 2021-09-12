FROM ubuntu:latest
MAINTAINER Sciroccogti(Based on https://github.com/zq1997/deepin-wine)

ENV DEBIAN_FRONTEND=noninteractive
RUN apt update
RUN apt install wget locales ttf-wqy-zenhei sudo tzdata -y
RUN wget -O- https://deepin-wine.i-m.dev/setup.sh | sh
RUN apt-get clean && apt-get autoclean
ENV LC_CTYPE=zh_CN.UTF-8 \
    XMODIFIERS="@im=fcitx"
WORKDIR /root

CMD ["/bin/bash"]