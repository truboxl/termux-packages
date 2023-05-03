TERMUX_PKG_HOMEPAGE=https://gitlab.freedesktop.org/wayland/weston
TERMUX_PKG_DESCRIPTION="Reference Wayland compositor library"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=11.0.1
TERMUX_PKG_SRCURL=https://gitlab.freedesktop.org/wayland/weston/-/archive/${TERMUX_PKG_VERSION}/weston-${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=59898996bc213c004288bb44f1ce40c5a0de7a1e143817323cf4c628822e4605
TERMUX_PKG_DEPENDS="fontconfig, glib, libcairo, libdrm, libevdev, libglvnd, liblcms2, libpixman, libpng, libseat, libudev-zero, libwayland, libwebp, libxcb, libxkbcommon, mesa, pango"
TERMUX_PKG_BUILD_DEPENDS="libwayland-protocols"
TERMUX_PKG_NO_STATIC_SPLIT=true
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-Dbackend-drm-screencast-vaapi=false
-Dlauncher-logind=false
"

termux_step_pre_configure() {
	termux_setup_cmake
}
