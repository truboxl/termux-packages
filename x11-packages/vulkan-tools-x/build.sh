TERMUX_PKG_HOMEPAGE=https://github.com/KhronosGroup/Vulkan-Tools
TERMUX_PKG_DESCRIPTION="Vulkan Tools and Utilities with X11"
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_MAINTAINER="@termux"
# All Khronos vulkan packages should be updated at same time. Otherwise, they do not compile successfully.
TERMUX_PKG_VERSION="1.3.225"
TERMUX_PKG_SRCURL=https://github.com/KhronosGroup/Vulkan-Tools/archive/v${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=f30dfedb2a5630b981ee93627f4ec6be9cef95d6b8527340437207276bd0d18e
TERMUX_PKG_BUILD_DEPENDS="vulkan-headers (=${TERMUX_PKG_VERSION}), vulkan-loader-x (=${TERMUX_PKG_VERSION}), xorgproto"
TERMUX_PKG_DEPENDS="libc++, libx11, libxcb"
TERMUX_PKG_CONFLICTS="vulkan-tools"
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_UPDATE_TAG_TYPE="newest-tag"

# https://github.com/KhronosGroup/Vulkan-Tools/blob/master/CMakeLists.txt
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-DBUILD_ICD=OFF
-DBUILD_WSI_WAYLAND_SUPPORT=OFF
"
