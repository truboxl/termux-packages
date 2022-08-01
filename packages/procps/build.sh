TERMUX_PKG_HOMEPAGE=https://gitlab.com/procps-ng/procps
TERMUX_PKG_DESCRIPTION="Utilities that give information about processes using the /proc filesystem"
TERMUX_PKG_LICENSE="LGPL-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=3.3.16
TERMUX_PKG_REVISION=2
TERMUX_PKG_SRCURL=https://gitlab.com/procps-ng/procps/-/archive/v${TERMUX_PKG_VERSION}/procps-v${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=7f09945e73beac5b12e163a7ee4cae98bcdd9a505163b6a060756f462907ebbc
TERMUX_PKG_DEPENDS="ncurses"
TERMUX_PKG_BREAKS="procps-dev"
TERMUX_PKG_REPLACES="procps-dev"
TERMUX_PKG_ESSENTIAL=true
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
ac_cv_search_dlopen=
--enable-sigwinch
--disable-modern-top
--enable-watch8bit
"

termux_step_pre_configure() {
	autoreconf -fi
}

# About kill: https://bugs.launchpad.net/ubuntu/+source/coreutils/+bug/141168:
# "For compatibility between distributions, can we have /bin/kill made available from coreutils?"
# About top: The system top works better.
TERMUX_PKG_RM_AFTER_INSTALL="
bin/top share/man/man1/top.1
bin/kill share/man/man1/kill.1
bin/slabtop share/man/man1/slabtop.1
bin/w share/man/man1/w.1
"
