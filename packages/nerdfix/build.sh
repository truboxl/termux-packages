TERMUX_PKG_HOMEPAGE=https://github.com/loichyan/nerdfix
TERMUX_PKG_DESCRIPTION="nerdfix helps you to find/fix obsolete Nerd Font icons in your project."
TERMUX_PKG_LICENSE="Apache-2.0, MIT"
TERMUX_PKG_MAINTAINER="Joshua Kahn @TomJo2000"
# most recent commit as of 9. Oct. 2023
# Significant improvements over latest release from May 14th
_COMMIT=76bf959ccc4da0fc1e162df9932b0ba705354d30
TERMUX_PKG_SRCURL=https://github.com/loichyan/nerdfix/archive/${_COMMIT}.tar.gz
TERMUX_PKG_VERSION=0.3.1
TERMUX_PKG_SHA256=ecacef18199f1ed6c7fd10c5090d476ebbab54f459e070a6a2fc8aecbc226dd3
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_pre_configure() {
	# do not pin the version of the rust toolchain
	rm -f rust-toolchain
	termux_setup_rust
}

termux_step_make() {
	cargo build --jobs $TERMUX_MAKE_PROCESSES --target $CARGO_TARGET_NAME --release
}

termux_step_make_install() {
	install -Dm755 -t $TERMUX_PREFIX/bin target/${CARGO_TARGET_NAME}/release/nerdfix
}

