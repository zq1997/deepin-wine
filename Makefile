REPO ?= repo

.PHONY: all setup deepin ubuntu-fix clean FORCE
.PRECIOUS: %/Release %/Packages.gz

all: setup ubuntu-fix deepin
setup: $(REPO)/ $(REPO)/i-m.dev.gpg $(REPO)/setup.sh
deepin ubuntu-fix: % : $(REPO)/%/ $(REPO)/%/InRelease $(REPO)/%/Release.gpg

clean:
	rm -rf $(REPO)

%/:
	mkdir -p $@

$(REPO)/i-m.dev.gpg:
	gpg --export -o $@

$(REPO)/setup.sh: $(REPO)/i-m.dev.gpg setup.template.sh
	sed "s~<GPG_KEY_CONTENT>~$$(base64 -w0 $<)~" $(word 2, $^) > $@
	chmod a+x $@

%/InRelease: %/Release
	gpg --yes --clear-sign -o $@ $<

%/Release.gpg: %/Release
	gpg --yes --detach-sign -a -o $@ $<

%/Release: %/Packages %/Packages.gz
	apt-ftparchive release $* > $@

%/Packages.gz: %/Packages
	gzip -c9 $< > $@

ifdef REFETCH
$(REPO)/deepin/Packages: FORCE
	rm -rf cache
else
$(REPO)/deepin/Packages:
endif
	python3 extract_deepin_repo.py extraction_config.json $@ files/ cache
	mkdir -p $(REPO)/deepin/files

$(REPO)/ubuntu-fix/Packages: $(foreach pkg, $(notdir $(wildcard ubuntu-fix/*)), $(REPO)/ubuntu-fix/$(pkg).deb)
	rm -f $(filter-out $^, $(wildcard $(@D)/*.deb))
	cd $(@D) && dpkg-scanpackages . > $(@F)

$(REPO)/ubuntu-fix/%.deb: ubuntu-fix/%/DEBIAN/control
	dpkg-deb -b ubuntu-fix/$* $(@D)

