TERMUX_PKG_HOMEPAGE=https://mate-menus.mate-desktop.dev/
TERMUX_PKG_DESCRIPTION="mate-menus contains the libmate-menu library, the layout configuration"
TERMUX_PKG_LICENSE="GPL-2.0, LGPL-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=1.27.0
TERMUX_PKG_SRCURL=https://github.com/mate-desktop/mate-menus/releases/download/v${TERMUX_PKG_VERSION}/mate-menus-${TERMUX_PKG_VERSION}.tar.xz
TERMUX_PKG_SHA256=04135790e856c019affbb61ce3d3ed463a0e4ef18b01e51c9de1c516048e8b56
TERMUX_PKG_DEPENDS="glib"
TERMUX_PKG_BUILD_DEPENDS="g-ir-scanner"
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_DISABLE_GIR=true
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
--enable-introspection=yes
"

termux_step_pre_configure() {
	termux_setup_gir
}
