SRCDIR=$(CURDIR)
MOCK_PROFILE=fedora-43-x86_64
KERNEL_VERSION=6.19.6
KERNEL_VERSION_TAG=fc43
STAGING_DIR=$(SRCDIR)/staging
BUILD_HOST_KERNEL_RELEASE := $(shell uname -r)

build-src-tarball: $(STAGING_DIR)
	@cp /boot/config-$(BUILD_HOST_KERNEL_RELEASE) ~/workspaces/linux-$(KERNEL_VERSION)/.config
	@tar -C ~/workspaces -cJf $(STAGING_DIR)/linux-$(KERNEL_VERSION).tar.xz linux-$(KERNEL_VERSION)

build-src-rpm:
	@mock -r $(MOCK_PROFILE) \
		--buildsrpm \
		--spec $(SRCDIR)/SPECS/kernel.spec \
		--sources $(STAGING_DIR)	
	@cp /var/lib/mock/$(MOCK_PROFILE)/result/kernel-$(KERNEL_VERSION)-*.$(KERNEL_VERSION_TAG).src.rpm $(STAGING_DIR)/

build-rpm:
	@mock -r $(MOCK_PROFILE) \
		--rebuild $(STAGING_DIR)/kernel-$(KERNEL_VERSION)-*.$(KERNEL_VERSION_TAG).src.rpm

mock-init:
	@mock -r $(MOCK_PROFILE) --init

mock-set-default:
	@sudo rm -f /etc/mock/default.cfg
	@sudo ln -s /etc/mock/$(MOCK_PROFILE).cfg /etc/mock/default.cfg

$(STAGING_DIR):
	@mkdir -p $@
