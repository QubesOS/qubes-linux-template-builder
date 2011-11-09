ifndef DIST
$(error "You must set DIST variable, e.g. DIST=fc14")
endif

TEMPLATE_NAME := $${DIST/fc/fedora-}-x64
VERSION := $(shell cat version)

help:
	@echo "make rpms                  -- generate template rpm"
	@echo "make update-repo-installer -- copy newly generated rpm to installer repo"
	@echo "make clean                 -- copy newly generated rpm to installer repo"


rpms:
	@export DIST NO_SIGN
	@echo "Building template: $(TEMPLATE_NAME)"
	@sudo -E ./fedorize_image fedorized_images/$(TEMPLATE_NAME).img clean_images/packages.list && \
	./create_symlinks_in_rpms_to_install_dir.sh && \
	sudo -E ./qubeize_image fedorized_images/$(TEMPLATE_NAME).img $(TEMPLATE_NAME) && \
	./build_template_rpm $(TEMPLATE_NAME) || exit 1; \

update-repo-installer:	
	ln -f rpm/noarch/qubes-template-$(TEMPLATE_NAME)-$(VERSION)-*.noarch.rpm ../installer/yum/qubes-dom0/rpm

clean:
	sudo rm -fr qubeized_images/root.img.*
	sudo rm -fr qubeized_images/$(TEMPLATE_NAME)*
	# We're not removing any images from fedorized_images/ intentionally
	# because the user might want to keep using the same image for a long time
	# and they are not dependent on any of the Qubes packahes

