TERMUX_PKG_HOMEPAGE=https://github.com/neovide/neovide
TERMUX_PKG_DESCRIPTION="No Nonsense Neovim Client in Rust"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux-user-repository"
TERMUX_PKG_VERSION="0.14.1"
TERMUX_PKG_SRCURL=https://github.com/neovide/neovide/archive/refs/tags/${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=ca89ddd63b2a321ff0b7fb2afbaa33d125c207ed6b8663e5fb6d6f665329b899
TERMUX_PKG_DEPENDS="libc++"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_AUTO_UPDATE=true

termux_step_pre_configure() {
	termux_setup_rust

	rm -fv Cargo.lock

	: "${CARGO_HOME:=$HOME/.cargo}"
	export CARGO_HOME

	cargo fetch --target "${CARGO_TARGET_NAME}"
	cargo tree --target "${CARGO_TARGET_NAME}"

	local f
	for f in \
		$CARGO_HOME/registry/src/*/winit-*/Cargo.toml \
		; do
		cp -fv ${f}{.orig,}
		#sed -e 's/target_os = "android"/not(target_os = "android")/g' -i $f
		sed -e 's/target_os = "android",//g' -i $f
		sed -e 's/= "0.5.0"$/= { version = "0.5.0", default-features = false }/g' -i $f
		diff -u $f{.orig,} || :
	done

	grep android -nHR $CARGO_HOME/registry/src/*/*/Cargo.toml

	#CFLAGS="$CPPFLAGS"

	rm -fv Cargo.lock
	cargo update --offline --recursive --verbose
	cargo tree --target "$CARGO_TARGET_NAME" --offline
}

termux_step_make() {
	cargo build --jobs "${TERMUX_PKG_MAKE_PROCESSES}" --target "${CARGO_TARGET_NAME}" --release
}

termux_step_make_install() {
	install -Dm755 -t "${TERMUX_PREFIX}/bin" "target/${CARGO_TARGET_NAME}/release/neovide"
}
