TERMUX_PKG_HOMEPAGE=https://github.com/pop-os/cosmic-epoch
TERMUX_PKG_DESCRIPTION="Next generation Cosmic desktop environment"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=0.0
TERMUX_PKG_SRCURL=git+https://github.com/pop-os/cosmic-epoch
TERMUX_PKG_GIT_BRANCH=master
TERMUX_PKG_DEPENDS="libxkbcommon"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_RUST_VERSION="1.75.0"

termux_step_pre_configure() {
	termux_setup_just
	termux_setup_rust

	local justfiles=$(find . -type f -name "justfile" | sort)
	echo "${justfiles}" | tee | xargs -P${TERMUX_PKG_MAKE_PROCESSES} -i -r sed \
		-e "s|/usr/local|${TERMUX_PREFIX}|g" \
		-e "s|/usr|${TERMUX_PREFIX}|g" \
		-e "s|cargo build|cargo build --target ${CARGO_TARGET_NAME}|g" \
		-i "{}"
}

termux_step_make() {
	just build
}

termux_step_make_install() {
	just install
}
