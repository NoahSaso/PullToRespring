ARCHS = arm64 armv7
GO_EASY_ON_ME = 1

include theos/makefiles/common.mk

TWEAK_NAME = PullToRespring
PullToRespring_FILES = Tweak.xm
PullToRespring_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Preferences"
SUBPROJECTS += pulltorespring
include $(THEOS_MAKE_PATH)/aggregate.mk
