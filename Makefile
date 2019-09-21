REPO ?= repo

.PHONY: all setup deepin ubuntu-fix clean FORCE
.PRECIOUS: %/Release %/Packages.gz

all: setup ubuntu-fix deepin
setup: $(REPO)/ $(REPO)/i-m.dev.gpg $(REPO)/setup.sh
deepin ubuntu-fix: % : $(REPO)/%/ $(REPO)/%/InRelease $(REPO)/%/Release.gpg
clean:
	rm -rf $(REPO)

%/:
	mkdir -p $*

$(REPO)/i-m.dev.gpg:
	gpg --export -o $@

$(REPO)/setup.sh: $(REPO)/i-m.dev.gpg setup.template.sh
	sed "s~<GPG_KEY_CONTENT>~$$(base64 -w0 $<)~" $(word 2, $^) > $@

%/InRelease: %/Release
	gpg --yes --clear-sign -o $@ $<

%/Release.gpg: %/Release
	gpg --yes --detach-sign -a -o $@ $<

%/Release: %/Packages %/Packages.gz
	apt-ftparchive release $* > $@

%/Packages.gz: %/Packages
	gzip -c9 $< > $@

ifdef REFETCH
$(REPO)/deepin/Packages: FORCE cache/
	rm -f cache/*
else
$(REPO)/deepin/Packages: cache/
endif
	python3 extract_deepin_repo.py $@

UBUNTU_FIX_PACKAGES := $(notdir $(wildcard ubuntu-fix-packages/*))
$(REPO)/ubuntu-fix/Packages: $(addprefix $(REPO)/ubuntu-fix/, $(addsuffix .deb, $(UBUNTU_FIX_PACKAGES)))
	rm -f $(filter-out $^, $(wildcard $(@D)/*.deb))
	cd $(@D) && dpkg-scanpackages . > $(@F)

$(REPO)/ubuntu-fix/%.deb: ubuntu-fix-packages/%/DEBIAN/control
	dpkg-deb -b ubuntu-fix-packages/$* $(@D)

