ARCHS = armv7

include $(THEOS)/makefiles/common.mk

TOOL_NAME = h2
h2_FILES = $(wildcard *.mm)
h2_INSTALL_PATH = /usr/lib/apt/methods
h2_LIBRARIES = apt-pkg MobileGestalt
h2_CFLAGS = -fobjc-arc
h2_CCFLAGS = -stdlib=libc++ -std=c++11

include $(THEOS_MAKE_PATH)/tool.mk
