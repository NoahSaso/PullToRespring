ARCHS = arm64 armv7
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PullToRespring
PullToRespring_FILES = Tweak.xm
PullToRespring_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Preferences"
SUBPROJECTS += Preferences
include $(THEOS_MAKE_PATH)/aggregate.mk
