TERMUX_PKG_HOMEPAGE=https://mate-desktop.org/
TERMUX_PKG_DESCRIPTION="Common scripts and macros to develop with MATE"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=1.27.1
TERMUX_PKG_SRCURL=https://github.com/mate-desktop/mate-common/releases/download/v${TERMUX_PKG_VERSION}/mate-common-${TERMUX_PKG_VERSION}.tar.xz
TERMUX_PKG_SHA256=4f1f91d0d60e3629999e2ff930574882f511a15831e20b52d93ff0bc8922effa
TERMUX_PKG_PLATFORM_INDEPENDENT=true
TERMUX_PKG_AUT0_UPDATE=true

termux_step_pre_configure() {
	autoreconf -vfi
}
