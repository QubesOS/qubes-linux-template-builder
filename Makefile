ifndef DIST
$(error "You must set DIST variable, e.g. DIST=fc14")
endif

#TODO: build template name somehow smarter
TEMPLATE_NAME := $${DIST/fc/fedora-}-x64
VERSION := $(shell cat version)
TIMESTAMP := $(shell date -u +%Y%m%d%H%M)

PKGLISTFILE := $(shell [ -r clean_images/packages_$(DIST).list ] && echo clean_images/packages_$(DIST).list || echo clean_images/packages.list)

help:
	@echo "make rpms                  -- generate template rpm"
	@echo "make update-repo-installer -- copy newly generated rpm to installer repo"
	@echo "make clean                 -- copy newly generated rpm to installer repo"


rpms:
	@echo $(TIMESTAMP) > build_timestamp_$(DIST)
	@echo "Building template: $(TEMPLATE_NAME)"
	sudo -E ./prepare_image prepared_images/$(TEMPLATE_NAME).img && \
	sudo -E ./qubeize_image prepared_images/$(TEMPLATE_NAME).img $(TEMPLATE_NAME) && \
	./build_template_rpm $(TEMPLATE_NAME) || exit 1; \

update-repo-installer:	
	[ -z "$$UPDATE_REPO" ] && UPDATE_REPO=../installer/yum/qubes-dom0;\
	ln -f rpm/noarch/qubes-template-$(TEMPLATE_NAME)-$(VERSION)-$(shell cat build_timestamp_$(DIST))*.noarch.rpm $$UPDATE_REPO/rpm

prepare-repo-template:
	rm -rf yum_repo_qubes/$(DIST)
	mkdir -p yum_repo_qubes/$(DIST)/rpm yum_repo_qubes/$(DIST)/repodata

clean:
	sudo rm -fr qubeized_images/root.img.*
	sudo rm -fr qubeized_images/$(TEMPLATE_NAME)*
	sudo rm -fr rpmbuild/BUILDROOT/*
	sudo rm -fr rpmbuild/tmp/*
	# We're not removing any images from prepared_images/ intentionally
	# because the user might want to keep using the same image for a long time
	# and they are not dependent on any of the Qubes packages

