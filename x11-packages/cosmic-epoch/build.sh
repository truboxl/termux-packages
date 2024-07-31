TERMUX_PKG_HOMEPAGE=https://github.com/pop-os/cosmic-epoch
TERMUX_PKG_DESCRIPTION="Next generation Cosmic desktop environment"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=0.0
TERMUX_PKG_SRCURL=git+https://github.com/pop-os/cosmic-epoch
TERMUX_PKG_GIT_BRANCH=master
TERMUX_PKG_DEPENDS="libxkbcommon"
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_pre_configure() {
	termux_setup_just
	termux_setup_rust

	: "${CARGO_HOME:=${HOME}/.cargo}"
	export CARGO_HOME

	local justfiles=$(find . -type f -name "justfile" | sort)
	echo "${justfiles}" | xargs -P${TERMUX_PKG_MAKE_PROCESSES} -i -r sed \
		-e "s|/usr/local|${TERMUX_PREFIX}|g" \
		-e "s|/usr|${TERMUX_PREFIX}|g" \
		-e "s|cargo build|rustup target add ${CARGO_TARGET_NAME}; rm -fr ${CARGO_HOME}/registry/src/*/rustix-*; cargo fetch --target ${CARGO_TARGET_NAME}; for a in ${CARGO_HOME}/registry/src/*/rustix-*; do patch -p1 -i ${TERMUX_PKG_BUILDER_DIR}/rustix.diff -d \$a; done; cargo build --target ${CARGO_TARGET_NAME}; ln -fsv target/${CARGO_TARGET_NAME}/release target/release|g" \
		-i "{}"
}

termux_step_make() {
	just build
}

termux_step_make_install() {
	just install
}
