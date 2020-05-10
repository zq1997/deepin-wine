REPO ?= repo
BUILD ?= build

.PHONY: all dev clean force

all: $(REPO)/Release $(REPO)/setup.sh
dev: all

clean:
	rm -rf $(BUILD) $(REPO)

.PRECIOUS: $(BUILD)/%/Packages.gz $(BUILD)/%/Packages.xz $(BUILD)/%/Packages
$(BUILD)/%/Packages.gz $(BUILD)/%/Packages.xz $(BUILD)/%/Packages: $(if $(filter dev,$(MAKECMDGOALS)), , force)
	wget -nv -N -P $(BUILD) -x --protocol-directories $(shell echo $@ | sed -E 's~^$(BUILD)/([^/]+)/~\1://~')

$(BUILD)/%/Packages.unxz: $(BUILD)/%/Packages.xz
	xz -cd $< >$@

$(BUILD)/%/Packages.ungz: $(BUILD)/%/Packages.gz
	gzip -cd $< >$@

TUNA_MIRROR := $(BUILD)/https/mirrors.tuna.tsinghua.edu.cn

$(BUILD)/deepin.pkg: \
		$(TUNA_MIRROR)/deepin/dists/stable/main/binary-i386/Packages.ungz \
		$(TUNA_MIRROR)/deepin/dists/stable/main/binary-amd64/Packages.ungz \
		$(TUNA_MIRROR)/deepin/dists/stable/non-free/binary-i386/Packages.ungz

$(BUILD)/debian-stable.pkg: \
		$(TUNA_MIRROR)/debian/dists/stable/main/binary-i386/Packages.unxz \
		$(TUNA_MIRROR)/debian/dists/stable/main/binary-amd64/Packages.unxz

$(BUILD)/debian-testing.pkg: \
		$(TUNA_MIRROR)/debian/dists/testing/main/binary-i386/Packages.unxz \
		$(TUNA_MIRROR)/debian/dists/testing/main/binary-amd64/Packages.unxz

$(BUILD)/ubuntu-bionic.pkg: \
		$(TUNA_MIRROR)/ubuntu/dists/bionic/main/binary-i386/Packages.unxz \
		$(TUNA_MIRROR)/ubuntu/dists/bionic/main/binary-amd64/Packages.unxz \
		$(TUNA_MIRROR)/ubuntu/dists/bionic/universe/binary-i386/Packages.unxz \
		$(TUNA_MIRROR)/ubuntu/dists/bionic/universe/binary-amd64/Packages.unxz

$(BUILD)/ubuntu-focal.pkg: \
		$(TUNA_MIRROR)/ubuntu/dists/focal/main/binary-i386/Packages.unxz \
		$(TUNA_MIRROR)/ubuntu/dists/focal/main/binary-amd64/Packages.unxz \
		$(TUNA_MIRROR)/ubuntu/dists/focal/universe/binary-i386/Packages.unxz \
		$(TUNA_MIRROR)/ubuntu/dists/focal/universe/binary-amd64/Packages.unxz

$(BUILD)/%.pkg:
	echo $+ | sed 's/ /\n/g' >$@

$(BUILD)/%.trans: $(BUILD)/deepin.pkg $(BUILD)/%.pkg
	@echo $+ '->' $@
	@python3 transplant.py -o $@ transplant -s $< -t $(lastword $+) \
		deepin.cn.360.yasuo \
		deepin.cn.com.winrar \
		deepin.com.95579.cjsc \
		deepin.com.aaa-logo \
		deepin.com.baidu.pan \
		deepin.com.cmbchina \
		deepin.com.foxmail \
		deepin.com.gtja.fuyi \
		deepin.com.qq.b.crm \
		deepin.com.qq.b.eim \
		deepin.com.qq.im \
		deepin.com.qq.im.light \
		deepin.com.qq.office \
		deepin.com.qq.rtx2015 \
		deepin.com.taobao.aliclient.qianniu \
		deepin.com.taobao.wangwang \
		deepin.com.thunderspeed \
		deepin.com.wechat \
		deepin.com.weixin.work \
		deepin.net.263.em \
		deepin.org.7-zip \
		deepin.org.foobar2000

$(REPO)/Packages: \
		$(BUILD)/debian-stable.trans\
		$(BUILD)/debian-testing.trans\
		$(BUILD)/ubuntu-bionic.trans\
		$(BUILD)/ubuntu-focal.trans
	mkdir -p $(REPO) $(REPO)/deepin_mirror
	python3 transplant.py -o $@ merge $+
	grep -iP '^(Package|Version|Architecture)\s*:|^$$' $@ > $(BUILD)/summary

$(REPO)/Packages.gz: $(REPO)/Packages
	gzip -nc9 $< >$@

$(REPO)/Release: $(REPO)/Packages $(REPO)/Packages.gz
	apt-ftparchive release -o APT::FTPArchive::Release::Label=deepin-wine $(REPO) >$@

$(REPO)/setup.sh: setup.sh
	mkdir -p $(REPO)
	cp $< $@
