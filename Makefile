TARGET=iphone:clang:latest:8.0

INSTALL_TARGET_PROCESSES = Argo

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NetflixSubtitleFix

NetflixSubtitleFix_FILES = Tweak.x
NetflixSubtitleFix_CFLAGS = -fobjc-arc

THEOS_PACKAGE_BASE_VERSION = 1.0.1
_THEOS_INTERNAL_PACKAGE_VERSION = 1.0.1

include $(THEOS_MAKE_PATH)/tweak.mk
