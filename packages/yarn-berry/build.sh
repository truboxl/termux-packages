TERMUX_PKG_HOMEPAGE=https://yarnpkg.com/
TERMUX_PKG_DESCRIPTION="Fast, reliable, and secure dependency management"
TERMUX_PKG_LICENSE="BSD 2-Clause"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="4.2.2"
TERMUX_PKG_SRCURL=https://github.com/yarnpkg/berry/archive/refs/tags/@yarnpkg/cli/${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=31e7c82c7e352b21574faee725857a12630441f479d9ee784326d50e0656fa50
TERMUX_PKG_DEPENDS="nodejs | nodejs-lts"
TERMUX_PKG_ANTI_BUILD_DEPENDS="nodejs, nodejs-lts"
TERMUX_PKG_BREAKS="yarn"
TERMUX_PKG_CONFLICTS="yarn"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_PLATFORM_INDEPENDENT=true
TERMUX_PKG_RM_AFTER_INSTALL="
share/yarn/.yarn
"

termux_step_make_install() {
	mkdir -p ${TERMUX_PREFIX}/lib/node_modules
	cp -r ${TERMUX_PKG_SRCDIR} ${TERMUX_PREFIX}/lib/node_modules/yarn
	ln -fs ../lib/node_modules/yarn/packages/yarnpkg-cli/bin/yarn.js ${TERMUX_PREFIX}/bin/yarn
	ln -fs ../lib/node_modules/yarn/packages/yarnpkg-cli/bin/yarn.js ${TERMUX_PREFIX}/bin/yarnpkg
}
