#
#
#

MOCK_PROFILE=fedora-43-x86_64

mock-init:
	@mock -r $(MOCK_PROFILE) --init

mock-set-default:
	@sudo rm -f /etc/mock/default.cfg
	@sudo ln -s /etc/mock/$(MOCK_PROFILE).cfg /etc/mock/default.cfg

