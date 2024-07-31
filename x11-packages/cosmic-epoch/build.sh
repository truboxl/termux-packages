TERMUX_PKG_HOMEPAGE=https://github.com/pop-os/cosmic-epoch
TERMUX_PKG_DESCRIPTION="Next generation Cosmic desktop environment"
TERMUX_PKG_LICENSE="GPLv3"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=0.0
TERMUX_PKG_SRCURL=git+https://github.com/pop-os/cosmic-epoch
TERMUX_PKG_GIT_BRANCH=master
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_pre_configure() {
	termux_setup_just
	termux_setup_rust

	sed \
		-e "s|/usr/local|${TERMUX_PREFIX}|g" \
		-e "s|/usr|${TERMUX_PREFIX}|g" \
		-i justfile
}

termux_step_make() {
	just build
}

termux_step_make_install() {
	just install
}
