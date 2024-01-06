TERMUX_PKG_HOMEPAGE=https://github.com/Aloxaf/silicon
TERMUX_PKG_DESCRIPTION="Silicon is an alternative to Carbon implemented in Rust"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="Yaksh Bariya <thunder-coding@termux.dev>"
TERMUX_PKG_VERSION="0.5.2"
TERMUX_PKG_SRCURL=https://github.com/Aloxaf/silicon/archive/refs/tags/v${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=815d41775dd9cd399650addf8056f803f3f57e68438e8b38445ee727a56b4b2d
TERMUX_PKG_DEPENDS="fontconfig, harfbuzz"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_AUTO_UPDATE=true

termux_step_pre_configure() {
	termux_setup_cmake
	termux_setup_rust

	local CFLAGS=$(termux_step_setup_toolchain; echo ${CFLAGS})
	export TARGET_CMAKE_TOOLCHAIN_FILE="${TERMUX_PKG_BUILDDIR}/android.toolchain.cmake"
	cat <<- EOF > "${TERMUX_PKG_BUILDDIR}/android.toolchain.cmake"
	set(CMAKE_C_FLAGS "${CFLAGS}")
	set(CMAKE_CXX_FLAGS "${CXXFLAGS}")
	EOF
	cat "${TERMUX_PKG_BUILDDIR}/android.toolchain.cmake"
}

termux_step_make() {
	cargo build --jobs $TERMUX_MAKE_PROCESSES --target $CARGO_TARGET_NAME --release
}

termux_step_make_install() {
	install -Dm755 -t $TERMUX_PREFIX/bin target/${CARGO_TARGET_NAME}/release/silicon
}
