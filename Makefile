# extract build information from control file and changelog
POPEN  :=(
PCLOSE :=)
PACKAGE:=$(shell perl -ne 'print $$1 if /^Package:\s+(.+)/;' < debian/control)
VERSION:=$(shell perl -ne '/^.+\s+[$(POPEN)](.+)[$(PCLOSE)]/ and print $$1 and exit' < debian/changelog)
DEPENDS:=$(shell perl -ne 'print $$1 if /^Depends:\s+(.+)/;' < debian/control)
DEPLIST:=$(shell echo "$(DEPENDS)" | perl -pe 's/(\s|,|[$(POPEN)].+?[$(PCLOSE)])+/ /g')
ARCH   :=$(shell dpkg --print-architecture)
RELEASE:=${PACKAGE}_${VERSION}_${ARCH}.deb

info:
	@echo "Release: $(RELEASE)"
	@echo "Depends: $(DEPENDS)"

# install local Perl modules
local:
	cpanm -l local --skip-satisfied PICA::Data RDF::aREF Plack::Util::Load 

# build documentation
PANDOC = $(shell which pandoc)
ifeq ($(PANDOC),)
  PANDOC = $(error pandoc is required but not installed)
endif

manpage: debian/control debian/$(PACKAGE).1
debian/$(PACKAGE).1: README.md
	grep -v '^\[!' $< | $(PANDOC) -s -t man -o $@ \
		-M title="$(shell echo $(PACKAGE) | tr a-z A-Z)(1) Manual" -o $@

# build Debian package
release-file: local manpage
	dpkg-buildpackage -b -us -uc -rfakeroot
	mv ../$(RELEASE) .

# do cleanup
debian-clean:
	fakeroot debian/rules clean

# install required Debian packages
dependencies:
	apt-get install fakeroot dpkg-dev $(DEPLIST)
