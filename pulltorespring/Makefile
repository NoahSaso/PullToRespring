ARCHS = armv7 arm64
TARGET = iphone:clang:latest:latest

include theos/makefiles/common.mk

BUNDLE_NAME = PullToRespring
PullToRespring_FILES = PullToRespring.mm
PullToRespring_INSTALL_PATH = /Library/PreferenceBundles
PullToRespring_FRAMEWORKS = UIKit
PullToRespring_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/PullToRespring.plist$(ECHO_END)
