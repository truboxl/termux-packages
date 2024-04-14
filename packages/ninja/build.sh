TERMUX_PKG_HOMEPAGE=https://ninja-build.org
TERMUX_PKG_DESCRIPTION="A small build system with a focus on speed"
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_MAINTAINER="@termux"
UTERMUX_PKG_VERSION="1.12.0"
TERMUX_PKG_VERSION="1.11.1"
TERMUX_PKG_SRCURL=https://github.com/ninja-build/ninja/archive/refs/tags/v${TERMUX_PKG_VERSION}.tar.gz
UTERMUX_PKG_SHA256=8b2c86cd483dc7fcb7975c5ec7329135d210099a89bc7db0590a07b0bbfe49a5
TERMUX_PKG_SHA256=31747ae633213f1eda3842686f83c2aa1412e0f5691d1c14dbbcc67fe7400cea
TERMUX_PKG_DEPENDS="libandroid-spawn, libc++"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_AUTO_UPDATE=true

termux_step_pre_configure() {
	CXXFLAGS+=" $CPPFLAGS -Dlinux=1"
	LDFLAGS+=" -landroid-spawn"
}

termux_step_configure() {
	$TERMUX_PKG_SRCDIR/configure.py
}

termux_step_make() {
	if $TERMUX_ON_DEVICE_BUILD; then
		$TERMUX_PKG_SRCDIR/configure.py --bootstrap
	else
		termux_setup_ninja
		ninja -j $TERMUX_MAKE_PROCESSES
	fi
}

termux_step_make_install() {
	cp ninja $TERMUX_PREFIX/bin
}
