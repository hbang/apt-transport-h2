ARCHS = armv7

include $(THEOS)/makefiles/common.mk

TOOL_NAME = h2
h2_FILES = $(wildcard *.mm)
h2_INSTALL_PATH = /usr/lib/apt/methods
h2_LIBRARIES = apt-pkg MobileGestalt
h2_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tool.mk

after-h2-stage::
	@mkdir -p $(THEOS_STAGING_DIR)/usr/lib/apt/methods
	@ln -s h2 $(THEOS_STAGING_DIR)/usr/lib/apt/methods/h2s
