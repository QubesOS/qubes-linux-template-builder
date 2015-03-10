ifndef DIST
$(error "You must set DIST variable, e.g. DIST=fc14")
endif
export DIST

TEMPLATE_BUILDER = 1
-include $(addsuffix /Makefile.builder,$(BUILDER_PLUGINS_DIRS))

TEMPLATE_NAME := $(DIST)
ifdef TEMPLATE_FLAVOR
TEMPLATE_NAME := $(TEMPLATE_NAME)-$(TEMPLATE_FLAVOR)
endif

# Make sure names are < 32 characters, process aliases
fix_up := $(shell TEMPLATE_NAME=$(TEMPLATE_NAME) ./builder_fix_filenames)
TEMPLATE_NAME := $(word 1,$(fix_up))

export TEMPLATE_NAME
export TEMPLATE_SCRIPTS
export DISTRIBUTION

VERSION := $(shell cat version)
TIMESTAMP := $(shell date -u +%Y%m%d%H%M)

help:
	@echo "make rpms                  -- generate template rpm"
	@echo "make update-repo-installer -- copy newly generated rpm to installer repo"
	@echo "make clean                 -- copy newly generated rpm to installer repo"


prepare:
	@echo $(TIMESTAMP) > build_timestamp_$(TEMPLATE_NAME)

rpms: prepare rootimg-build
	@echo "Building template: $(TEMPLATE_NAME)"
	./build_template_rpm $(TEMPLATE_NAME)
	./create_template_list.sh || :

rootimg-build:
ifeq (,$(TEMPLATE_SCRIPTS))
	$(error Building template $(DIST) not supported by any of configured plugins)
endif
	sudo -E ./prepare_image prepared_images/$(TEMPLATE_NAME).img
	sudo -E ./qubeize_image prepared_images/$(TEMPLATE_NAME).img $(TEMPLATE_NAME)

update-repo-installer:	
	[ -z "$$UPDATE_REPO" ] && UPDATE_REPO=../installer/yum/qubes-dom0;\
	ln -f rpm/noarch/qubes-template-$(TEMPLATE_NAME)-$(VERSION)-$(shell cat build_timestamp_$(DIST))*.noarch.rpm $$UPDATE_REPO/rpm

prepare-repo-template:
	rm -rf pkgs-for-template/$(DIST)
	mkdir -p pkgs-for-template/$(DIST)

clean:
	sudo rm -fr qubeized_images/root.img.*
	sudo rm -fr qubeized_images/$(TEMPLATE_NAME)*
	sudo rm -fr rpmbuild/BUILDROOT/*
	sudo rm -fr rpmbuild/tmp/*
	# We're not removing any images from prepared_images/ intentionally
	# because the user might want to keep using the same image for a long time
	# and they are not dependent on any of the Qubes packages

