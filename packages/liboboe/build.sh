TERMUX_PKG_HOMEPAGE=https://github.com/google/oboe
TERMUX_PKG_DESCRIPTION="C++ library to build high-performance audio apps on Android"
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.8.0"
TERMUX_PKG_SRCURL=https://github.com/google/oboe/archive/refs/tags/${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=1ab24ff129af6396b8a5741c12b44b922814337d1b40958ac7ada8e270eb4880
TERMUX_PKG_DEPENDS="libc++"
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-DBUILD_SHARED_LIBS=ON
"
