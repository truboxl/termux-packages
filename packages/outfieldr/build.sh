TERMUX_PKG_HOMEPAGE=https://gitlab.com/ve-nt/outfieldr
TERMUX_PKG_DESCRIPTION="A TLDR client in Zig"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.0.3"
TERMUX_PKG_REVISION=1
TERMUX_PKG_SRCURL=https://gitlab.com/ve-nt/outfieldr/-/archive/${TERMUX_PKG_VERSION}/outfieldr-${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=f6c9fbfaaf40c5a24df5f9856f29b279ee7f23487b4aa46776e5d21132033d3a
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_ZIG_VERSION="0.9.1"

termux_step_make() {
	termux_setup_zig
	zig build -Dtarget=$ZIG_TARGET_NAME
}

termux_step_make_install() {
	install -Dm700 -t $TERMUX_PREFIX/bin bin/tldr
}
