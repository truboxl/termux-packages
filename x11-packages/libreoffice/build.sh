TERMUX_PKG_HOMEPAGE=https://www.libreoffice.org/
TERMUX_PKG_DESCRIPTION="LibreOffice"
TERMUX_PKG_LICENSE="GPL-3.0, LGPL-3.0, MPL-2.0"
TERMUX_PKG_LICENSE_FILE="COPYING, COPYING.LGPL, COPYING.MPL"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="25.2.2.2"
UTERMUX_PKG_SRCURL=git+https://github.com/LibreOffice/core
UTERMUX_PKG_GIT_BRANCH=master
UTERMUX_PKG_SRCURL=(
	https://download.documentfoundation.org/libreoffice/src/${TERMUX_PKG_VERSION%.*}/libreoffice-${TERMUX_PKG_VERSION}.tar.xz
	https://download.documentfoundation.org/libreoffice/src/${TERMUX_PKG_VERSION%.*}/libreoffice-dictionaries-${TERMUX_PKG_VERSION}.tar.xz
	https://download.documentfoundation.org/libreoffice/src/${TERMUX_PKG_VERSION%.*}/libreoffice-help-${TERMUX_PKG_VERSION}.tar.xz
	https://download.documentfoundation.org/libreoffice/src/${TERMUX_PKG_VERSION%.*}/libreoffice-translations-${TERMUX_PKG_VERSION}.tar.xz
)
UTERMUX_PKG_SHA256=(
	01a14580c15a5b14153fa46c28e90307f6683e0d0326727a4ad13e9545dfe6ac
	18460f0ae1140b2faed8e513e83e796fb86570f5ab8a727679ccb0c1ed9f7838
	5a7c9fcc43afad674c3883f90c46f5e4fde728801a0d19e37e518bdc488a5f9e
	a74b05873778a47961c2fc44f85b300ab820c9b333e1be921ca6cbac6fef5430
)
TERMUX_PKG_SRCURL=https://download.documentfoundation.org/libreoffice/src/${TERMUX_PKG_VERSION%.*}/libreoffice-${TERMUX_PKG_VERSION}.tar.xz
TERMUX_PKG_SHA256=01a14580c15a5b14153fa46c28e90307f6683e0d0326727a4ad13e9545dfe6ac
TERMUX_PKG_DEPENDS="cups, fontconfig, libc++, libicu, libjpeg-turbo, libxslt, openldap, openssl, python, zlib"
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_configure() {
	# TERMUX_PKG_EXTRA_CONFIGURE_ARGS breaks when need to pass quoted variables
	./configure \
		--prefix=${TERMUX_PREFIX} \
		--libdir=${TERMUX_PREFIX}/lib \
		--sbindir=${TERMUX_PREFIX}/bin \
		--host=${TERMUX_ARCH}-linux-gnu \
		--with-system-openldap \
		--with-system-openssl \
		--without-java \
		ac_cv_lib_z_deflate=yes \
		PYTHON_VERSION=$(pkg-config --modversion python3) \
		|| termux_step_configure_autotools_failure_hook

		#--with-jdk-home=${TERMUX_JAVA_HOME}
}

termux_step_configure_autotools_failure_hook() {
	echo "########## LOG ##########"
	ls -l CONF-FOR-BUILD
	cat CONF-FOR-BUILD/config.log
	exit 1
}
