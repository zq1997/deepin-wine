REPO ?= repo
BUILD ?= build

.PHONY: all packages netlify

all: packages $(REPO)/setup.sh

netlify:
	apt-get download apt-utils
	dpkg-deb -xv apt-utils_*.deb packages
	env PATH=$${PATH}:packages/usr/bin $(MAKE) -j all
	echo '/https/* https://:splat 301!' > $(REPO)/_redirects
	echo '/ https://github.com/zq1997/deepin-wine 301' >> $(REPO)/_redirects

packages: | $(REPO)/ $(BUILD)/
	python3 make.py

%/:
	mkdir -p $@


$(REPO)/setup.sh: setup.sh | $(REPO)/
	cp $< $@

$(REPO)/Packages.gz: $(REPO)/Packages
	gzip -nc9 $< >$@

$(REPO)/Packages.xz: $(REPO)/Packages
	xz -c9 $< >$@

$(REPO)/Release: $(REPO)/Packages.gz $(REPO)/Packages.xz
	apt-ftparchive release -o APT::FTPArchive::Release::Label=deepin-wine $(REPO) >$@
