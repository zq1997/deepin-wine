
REPO ?= repo
BUILD ?= build

.PHONY: all dev clean clean-download netlify

all: $(REPO)/Release $(REPO)/setup.sh
dev: all

clean:
	rm -rf $(BUILD) $(REPO)

clean-download:
	rm -rf $(BUILD)/https

netlify:
	apt-get download apt-utils
	dpkg-deb -xv apt-utils_*.deb packages
	env PATH=$${PATH}:packages/usr/bin $(MAKE) -j all
	echo '/https/* https://:splat 301!' > $(REPO)/_redirects
	echo '/ https://github.com/zq1997/deepin-wine 301' >> $(REPO)/_redirects

.PRECIOUS: $(BUILD)/%/Packages.gz $(BUILD)/%/Packages.xz $(BUILD)/%/Packages \
		$(BUILD)/%/Packages.unxz $(BUILD)/%/Packages.ungz

%/:
	mkdir -p $@

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
		$(BUILD)/ubuntu-groovy.trans\
		| $(REPO)/
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
		$(call DEEPIN_MIRROR,non-free,i386,.ungz) \
		$(call DEEPIN_MIRROR,non-free,amd64,.ungz) \
		$(call DEEPIN_MIRROR,contrib,i386,.ungz) \
		$(call DEEPIN_MIRROR,contrib,amd64,.ungz) \
		$(BUILD)/https/community-store-packages.deepin.com/appstore/dists/eagle/appstore/binary-i386/Packages.ungz \
		$(BUILD)/https/community-store-packages.deepin.com/appstore/dists/eagle/appstore/binary-amd64/Packages.ungz
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
PACKAGES/ubuntu-groovy := \
		$(call TUNA_MIRROR,ubuntu,groovy,main,i386,.unxz) \
		$(call TUNA_MIRROR,ubuntu,groovy,universe,i386,.unxz)

APPS := \
        com.dingtalk.deepin \
        com.foxmail.deepin \
        com.freepiano.deepin \
        com.iqiyi.deepin \
        com.meituxiuxiu.deepin \
        com.qq.im.deepin \
        com.qq.music.deepin \
        com.qq.video.deepin \
        com.qq.weixin.deepin \
        com.qq.weixin.work.deepin \
        com.taobao.aliclient.qianniu.deepin \
        com.taobao.wangwang.deepin \
        com.utau.deepin \

.SECONDEXPANSION:
$(BUILD)/%.trans: $(PACKAGES/deepin) $$(PACKAGES/$$*)
	@echo 'making $@...'
	@python3 transplant.py -o $@ transplant -s $(PACKAGES/deepin) -t $(PACKAGES/$*) -- $(APPS)
