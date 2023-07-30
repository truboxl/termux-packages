TERMUX_PKG_HOMEPAGE=https://hedgewars.org/
TERMUX_PKG_DESCRIPTION="Turn-based strategy game"
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=1.0.2
TERMUX_PKG_SRCURL=https://hedgewars.org/download/releases/hedgewars-src-${TERMUX_PKG_VERSION}.tar.bz2
TERMUX_PKG_SHA256=201fe5e45bd8ca5b3d81b18ec06bd6bbc9fa7c2c63bf019005e2f80be5bcf212
UTERMUX_PKG_DEPENDS=""
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-DANDROID=OFF
-DNOSERVER=ON
"

termux_step_pre_configure() {
	:
}

termux_step_post_massage() {
	:
}
