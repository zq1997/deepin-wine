REPO ?= repo
BUILD ?= build

.PHONY: all netlify always_redo

all: $(REPO)/Release $(REPO)/setup.sh $(REPO)/index.html

netlify:
	wget http://archive.ubuntu.com/ubuntu/pool/main/a/apt/apt-utils_2.0.2_amd64.deb
	dpkg-deb -x apt-utils_*.deb packages
	env PATH=$${PATH}:packages/usr/bin $(MAKE) -j all
	echo '/https/* https://:splat 301!' > $(REPO)/_redirects

%/:
	mkdir -p $@

$(REPO)/Packages: always_redo | $(REPO)/ $(BUILD)/
	python3 make.py

%.gz: %
	gzip -kn9f $<

%.xz: %
	xz -k9f $<

$(REPO)/Release: $(REPO)/Packages.gz $(REPO)/Packages.xz
	apt-ftparchive release -o APT::FTPArchive::Release::Label=deepin-wine $(REPO) >$@

$(REPO)/setup.sh: setup.sh | $(REPO)/
	cp $< $@

$(REPO)/index.html: $(REPO)/Packages
	python3 make_html.py
