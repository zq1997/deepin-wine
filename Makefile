REPO ?= repo
BUILD ?= build

.PHONY: all dev clean clean-download

all: $(REPO)/Release $(REPO)/setup.sh
dev: all

clean:
	rm -rf $(BUILD) $(REPO)

clean-download:
	rm -rf $(BUILD)/https

.PRECIOUS: $(BUILD)/%/Packages.gz $(BUILD)/%/Packages.xz $(BUILD)/%/Packages \
		$(BUILD)/%/Packages.unxz $(BUILD)/%/Packages.ungz

%/:
	mkdir $@

$(BUILD)/%/Packages.gz $(BUILD)/%/Packages.xz $(BUILD)/%/Packages:
	@wget -nv -N -P $(BUILD) -x --protocol-directories $(shell echo $@ | sed -E 's~^$(BUILD)/([^/]+)/~\1://~')

$(BUILD)/%/Packages.unxz: $(BUILD)/%/Packages.xz
	xz -cd $< >$@

$(BUILD)/%/Packages.ungz: $(BUILD)/%/Packages.gz
	gzip -cd $< >$@

$(REPO)/setup.sh: setup.sh | $(REPO)/
	cp $< $@

$(REPO)/Packages: \
		$(BUILD)/debian-stable.trans\
		$(BUILD)/debian-testing.trans\
		$(BUILD)/ubuntu-bionic.trans\
		$(BUILD)/ubuntu-focal.trans\
		| $(REPO)/ $(REPO)/deepin_mirror/
	python3 transplant.py -o $@ merge $+

$(REPO)/Packages.gz: $(REPO)/Packages
	gzip -nc9 $< >$@

$(REPO)/Release: $(REPO)/Packages $(REPO)/Packages.gz
	apt-ftparchive release -o APT::FTPArchive::Release::Label=deepin-wine $(REPO) >$@

DEEPIN_MIRROR = $(BUILD)/https/community-packages.deepin.com/deepin/dists/apricot/$(1)/binary-$(2)/Packages$(3)
TUNA_MIRROR = $(BUILD)/https/mirrors.tuna.tsinghua.edu.cn/$(1)/dists/$(2)/$(3)/binary-$(4)/Packages$(5)
PACKAGES/deepin := \
		$(call DEEPIN_MIRROR,main,i386,.ungz) \
		$(call DEEPIN_MIRROR,main,amd64,.ungz) \
		$(call DEEPIN_MIRROR,non-free,i386,.ungz)
PACKAGES/debian-stable := \
		$(call TUNA_MIRROR,debian,stable,main,i386,.unxz)
PACKAGES/debian-testing := \
		$(call TUNA_MIRROR,debian,testing,main,i386,.unxz)
PACKAGES/ubuntu-bionic := \
		$(call TUNA_MIRROR,ubuntu,bionic,main,i386,.unxz) \
		$(call TUNA_MIRROR,ubuntu,bionic,universe,i386,.unxz)
PACKAGES/ubuntu-focal := \
		$(call TUNA_MIRROR,ubuntu,focal,main,i386,.unxz) \
		$(call TUNA_MIRROR,ubuntu,focal,universe,i386,.unxz)

APPS := \
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

.SECONDEXPANSION:
$(BUILD)/%.trans: $(PACKAGES/deepin) $$(PACKAGES/$$*)
	@echo 'making $@...'
	@python3 transplant.py -o $@ transplant -s $(PACKAGES/deepin) -t $(PACKAGES/$*) -- $(APPS)
