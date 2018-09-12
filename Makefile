ifndef DIST
$(error "You must set DIST variable, e.g. DIST=fc14")
endif
export DIST

TEMPLATE_ENV_WHITELIST ?=
TEMPLATE_BUILDER = 1
-include $(addsuffix /Makefile.builder,$(BUILDER_PLUGINS_DIRS))

TEMPLATE_NAME := $(DIST)
ifdef TEMPLATE_FLAVOR
TEMPLATE_NAME := $(TEMPLATE_NAME)-$(TEMPLATE_FLAVOR)
endif

# expose those variables to template-building scripts
TEMPLATE_ENV_WHITELIST += \
	DIST DISTRIBUTION TEMPLATE_SCRIPTS TEMPLATE_NAME TEMPLATE_FLAVOR \
	TEMPLATE_FLAVOR_DIR TEMPLATE_OPTIONS APPMENUS_DIR \
	VERBOSE DEBUG PATH BUILDER_DIR SRC_DIR DISCARD_PREPARED_IMAGE \
	TEMPLATE_ROOT_WITH_PARTITIONS TEMPLATE_ROOT_SIZE \
	USE_QUBES_REPO_VERSION USE_QUBES_REPO_TESTING \
	BUILDER_TURBO_MODE REPO_PROXY FEDORA_MIRROR \
	CENTOS_MIRROR EPEL_MIRROR QUBES_MIRROR

# Make sure names are < 32 characters, process aliases
fix_up := $(shell TEMPLATE_NAME=$(TEMPLATE_NAME) \
		TEMPLATE_LABEL="$(TEMPLATE_LABEL)" \
		./builder_fix_filenames)
TEMPLATE_NAME := $(word 1,$(fix_up))
SCRIPTSDIR ?= $(TEMPLATE_SCRIPTS)

export TEMPLATE_NAME
export TEMPLATE_SCRIPTS
export SCRIPTSDIR
export DISTRIBUTION

VERSION := $(shell cat version)
TEMPLATE_TIMESTAMP ?= $(shell date -u +%Y%m%d%H%M)

.PHONY: help template-name prepare package rpms rootimg-build
.PHONY: update-repo-templates-itl update-repo-templates-community

help:
	@echo "make rpms                  -- generate template rpm"
	@echo "make update-repo-installer -- copy newly generated rpm to installer repo"
	@echo "make clean                 -- remove all files and directories built or added"

template-name:
	@echo $(TEMPLATE_NAME)

prepare:
	@echo "Building template: $(TEMPLATE_NAME)"
	@echo $(TEMPLATE_TIMESTAMP) > build_timestamp_$(TEMPLATE_NAME)

package:
	./build_template_rpm $(TEMPLATE_NAME)

rpms: prepare rootimg-build package
	./create_template_list.sh || :

rootimg-build:
ifeq (,$(TEMPLATE_SCRIPTS))
	$(error Building template $(DIST) not supported by any of configured plugins)
endif
	sudo env -i $(foreach var,$(TEMPLATE_ENV_WHITELIST),$(var)="$($(var))") \
		./prepare_image prepared_images/$(TEMPLATE_NAME).img
	sudo env -i $(foreach var,$(TEMPLATE_ENV_WHITELIST),$(var)="$($(var))") \
		./qubeize_image prepared_images/$(TEMPLATE_NAME).img $(TEMPLATE_NAME)

update-repo-templates-itl: update-repo-templates.itl
update-repo-templates-community: update-repo-templates.community

update-repo-templates.%: repo = $(subst .,,$(suffix $@))
update-repo-templates.%:
	[ -z "$$UPDATE_REPO" ] && UPDATE_REPO=../linux-yum/current-release/templates-$(repo);\
	ln -f rpm/noarch/qubes-template-$(TEMPLATE_NAME)-$(VERSION)-$(shell cat build_timestamp_$(TEMPLATE_NAME))*.noarch.rpm $$UPDATE_REPO/rpm

update-repo-installer:	
	[ -z "$$UPDATE_REPO" ] && UPDATE_REPO=../installer/yum/qubes-dom0;\
	ln -f rpm/noarch/qubes-template-$(TEMPLATE_NAME)-$(VERSION)-$(shell cat build_timestamp_$(TEMPLATE_NAME))*.noarch.rpm $$UPDATE_REPO/rpm

sign:
	setsid -w rpmsign $$RPMSIGN_OPTS --addsign rpm/noarch/qubes-template-$(TEMPLATE_NAME)-$(VERSION)-$(shell cat build_timestamp_$(TEMPLATE_NAME))*.noarch.rpm

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

