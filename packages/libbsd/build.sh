TERMUX_PKG_HOMEPAGE=https://libbsd.freedesktop.org/wiki/
TERMUX_PKG_DESCRIPTION="Utility functions from BSD systems"
TERMUX_PKG_LICENSE="BSD 3-Clause"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="0.12.2"
TERMUX_PKG_SRCURL=https://libbsd.freedesktop.org/releases/libbsd-${TERMUX_PKG_VERSION}.tar.xz
TERMUX_PKG_SHA256=b88cc9163d0c652aaf39a99991d974ddba1c3a9711db8f1b5838af2a14731014
TERMUX_PKG_DEPENDS="libmd"
TERMUX_PKG_BREAKS="libbsd-dev"
TERMUX_PKG_REPLACES="libbsd-dev"
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_pre_configure() {
	# Fix linker script error
	LDFLAGS+=" -Wl,--undefined-version"

	autoreconf -vfi
}
