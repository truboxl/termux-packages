TERMUX_PKG_HOMEPAGE=https://github.com/microsoft/DirectX-Headers
TERMUX_PKG_DESCRIPTION="Microsoft DirectX Headers"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=1.610.0
TERMUX_PKG_SRCURL=https://github.com/microsoft/DirectX-Headers/archive/v${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=343b04a8206c4169a1feab99a7bd29ecb0c8f511988e9a007fea51768bda14fa
TERMUX_PKG_DEPENDS="libc++"
TERMUX_PKG_NO_STATICSPLIT=true
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-Dbuild-test=false
"

termux_step_pre_configure() {
	# use meson build
	rm -f CMakeLists.txt
}
