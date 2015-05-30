ARCHS=armv7 armv7s arm64
include theos/makefiles/common.mk

TWEAK_NAME = SpeedView
SpeedView_FILES = Tweak.xm
SpeedView_FRAMEWORKS = UIKit QuartzCore
SpeedView_LIBRARIES = objcipc activator

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
