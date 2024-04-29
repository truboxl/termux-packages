TERMUX_PKG_HOMEPAGE=https://gitlab.com/ve-nt/outfieldr
TERMUX_PKG_DESCRIPTION="A TLDR client in Zig"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux"
_COMMIT=f155dca100694bdd7eed9c8639e1cd79790e236f
_COMMIT_DATE=20231010
TERMUX_PKG_VERSION="1.0.3-p20231010"
TERMUX_PKG_SRCURL=git+https://gitlab.com/ve-nt/outfieldr
TERMUX_PKG_GIT_BRANCH=master
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_BLACKLISTED_ARCHES="arm, i686"
TERMUX_DEBUG_BUILD=true
TERMUX_ZIG_VERSION="0.9.1"

termux_step_post_get_source() {
	git fetch --unshallow
	git checkout "${_COMMIT}"
	git submodule update --init --recursive --depth=1
	git clean -ffxd
}

termux_step_pre_configure() {
	termux_setup_zig
}

termux_step_make() {
	zig build -Dtarget=$ZIG_TARGET_NAME
}

termux_step_make_install() {
	install -Dm700 -t $TERMUX_PREFIX/bin bin/tldr
}
