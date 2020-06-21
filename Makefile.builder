# pretend that normal package is built from this repo, to reuse update-repo-* 
ifeq ($(PACKAGE_SET),vm)
OUTPUT_DIR = rpm
RPM_SPEC_FILES = templates.spec
endif

NO_ARCHIVE := 1
