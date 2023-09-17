TERMUX_PKG_HOMEPAGE=https://sourceforge.net/projects/dosemu/
TERMUX_PKG_DESCRIPTION="DOS Emulator"
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=1.4.0.8
TERMUX_PKG_SRCURL=git+https://git.code.sf.net/p/dosemu/code
TERMUX_PKG_GIT_BRANCH=dosemu-${TERMUX_PKG_VERSION}
UTERMUX_PKG_SHA256=
TERMUX_PKG_DEPENDS="libandroid-shmem, libx11, sdl"
UTERMUX_PKG_BUILD_DEPENDS="binutils-cross"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_BLACKLISTED_ARCHES="aarch64, arm"
UTERMUX_PKG_EXTRA_CONFIGURE_ARGS="
--disable-dynamic-x86
--disable-fpu-x86
--disable-opengl
"

termux_step_pre_configure() {
	#termux_setup_no_integrated_as
	CFLAGS+=" -fno-integrated-as"
	LDFLAGS+=" -landroid-shmem"
	[[ "${TERMUX_ARCH}" == "i686" ]] && ASFLAGS+=" -fPIC"
	autoreconf -fi
	pushd src/plugin/sdl
	autoreconf -fi
	popd
}
