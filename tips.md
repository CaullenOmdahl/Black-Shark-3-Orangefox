Building tips
A. If you get any errors relating to anything with a ".py" extension or anything containing "py2",etc, then it means you need to install Python 2.x. Run "python --version" to see which version is being used as default - and, if it is not Python 2.7.x (eg, if it is Python 3.x) then you will have issues, and you will need to install v2.x
B. Indeed, you should always make sure that your default python for building is python 2.x
C. If you get build errors relating to "ui.xml for TW_THEME: portrait_hdpi", "Set TARGET_SCREEN_WIDTH and TARGET_SCREEN_HEIGHT to automatically select an appropriate theme", or "set TW_THEME to one of the following", etc, then it is possible that the bootable/recovery/gui/theme/ directory has not been properly synced. In that case, you might need to run a command like: git clone https://gitlab.com/OrangeFox/misc/theme.git bootable/recovery/gui/theme from the manifest root directory.
D. If the device that you are building for is not a Xiaomi MIUI device, and/or you don't care about block-based incremental OTA updates, then you should consider adding this to your build process:
export OF_DISABLE_MIUI_SPECIFIC_FEATURES=1
or
export FOX_VANILLA_BUILD=1
E. If the device for which you are building OrangeFox is an A-only Xiaomi MIUI device, then you probably want to add this to your build process, to prevent the MIUI recovery from overwriting OrangeFox when you boot into the MIUI ROM:
export OF_PATCH_AVB20=1
F. If you are building for an A/B device (you must be sure of this!), then you should add this to your build process:
export FOX_AB_DEVICE=1
G. If you are building with the fox_11.0 (or higher) branch and your device is a recent Virtual A/B ("VAB") device, then you should add this to your build process if you are getting problems with flashing the OrangeFox zip installer itself, or with things like changing the splash :
export FOX_VIRTUAL_AB_DEVICE=1
H. If you want your subsequent builds to be faster, then use ccache - eg
export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache
ccache -M 50G # this sets aside 50GB disk space for the cache
I. If you are using a prebuilt kernel, and you start getting a "NO KERNEL CONFIG" error, try adding export OF_FORCE_PREBUILT_KERNEL=1 to your build process (eg, in vendorsetup.sh)
J. If your OrangeFox build variables are not being processed, ensure that your Linux shell for building is bash, and that you have run export FOX_BUILD_DEVICE=<device> before building.
K. If your build is getting stuck on the logo (indicating a decryption problem), you should consider providing a default version number for the keymaster services, using the OF_DEFAULT_KEYMASTER_VERSION variable (in fact, it is strongly recommended to always do this anyway). This needs to specify the version number of the keymaster services that you have provided in your device tree (ensure that this is correct) - eg, for keymaster version 4.1:
export OF_DEFAULT_KEYMASTER_VERSION=4.1
L. If you enable TW_NO_SCREEN_BLANK in your device tree, then make sure that you give a correct value for TW_MAX_BRIGHTNESS - othewise, a default value (1023) will be used - and this may not be what you really want.
M. Make sure that you have sufficient RAM on your PC/Server (read the requirements section at the top of this page).