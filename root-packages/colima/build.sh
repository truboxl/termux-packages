TERMUX_PKG_HOMEPAGE=https://github.com/abiosoft/colima
TERMUX_PKG_DESCRIPTION="Container runtimes on macOS (and Linux) with minimal setup"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="0.9.1"
TERMUX_PKG_SRCURL=git+https://github.com/abiosoft/colima
TERMUX_PKG_GIT_BRANCH="v${TERMUX_PKG_VERSION}"
TERMUX_PKG_DEPENDS="curl, lima, perl"
TERMUX_PKG_ANTI_BUILD_DEPENDS="curl, lima, perl"
TERMUX_PKG_SUGGESTS="docker"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_EXCLUDED_ARCHES="arm, i686"

termux_step_pre_configure() {
	termux_setup_golang

	TERMUX_PKG_EXTRA_MAKE_ARGS+="OS=android ARCH=${TERMUX_ARCH} INSTALL_DIR=${TERMUX_PREFIX}/bin"
}
