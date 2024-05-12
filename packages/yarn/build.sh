TERMUX_PKG_HOMEPAGE=https://yarnpkg.com/
TERMUX_PKG_DESCRIPTION="Fast, reliable, and secure dependency management"
TERMUX_PKG_LICENSE="BSD 2-Clause"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.22.22"
TERMUX_PKG_SRCURL=https://yarnpkg.com/downloads/${TERMUX_PKG_VERSION}/yarn-v${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=88268464199d1611fcf73ce9c0a6c4d44c7d5363682720d8506f6508addf36a0
TERMUX_PKG_DEPENDS="nodejs | nodejs-lts"
TERMUX_PKG_ANTI_BUILD_DEPENDS="nodejs, nodejs-lts"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_PLATFORM_INDEPENDENT=true

termux_step_make_install() {
	cp -r . ${TERMUX_PREFIX}/share/yarn/
	ln -fs ../share/yarn/bin/yarn ${TERMUX_PREFIX}/bin/yarn
	ln -fs ../share/yarn/bin/yarn ${TERMUX_PREFIX}/bin/yarnpkg
}
