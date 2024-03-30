TERMUX_PKG_HOMEPAGE=https://crosvm.dev/book/
TERMUX_PKG_DESCRIPTION="Hosted Virtual Machine Monitor"
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="0"
TERMUX_PKG_SRCURL=git+https://chromium.googlesource.com/crosvm/crosvm
TERMUX_PKG_GIT_BRANCH=main
TERMUX_PKG_DEPENDS="libandroid-fexecve, libcap"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_AUTO_UPDATE=true

termux_step_pre_configure() {
	termux_setup_rust

	export PKG_CONFIG_ALLOW_CROSS=1

	# minijail
	export CDRIVER=clang
	export CXXDRIVER=clang

	unset CC CFLAGS CXX CXXFLAGS LD LDFLAGS
}

termux_step_make() {
	cargo build --jobs "${TERMUX_MAKE_PROCESSES}" --target "${CARGO_TARGET_NAME}" --release
}

termux_step_make_install() {
	install -Dm755 -t "${TERMUX_PREFIX}/bin" "target/${CARGO_TARGET_NAME}/release/crossvm"
}
