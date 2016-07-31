ARCHS = arm64 armv7
GO_EASY_ON_ME = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PullToRespring
PullToRespring_FILES = Tweak.xm
PullToRespring_FRAMEWORKS = UIKit
PullToRespring_PRIVATE_FRAMEWORKS = FrontBoardServices SpringBoardServices

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Preferences"
SUBPROJECTS += Preferences
include $(THEOS_MAKE_PATH)/aggregate.mk
