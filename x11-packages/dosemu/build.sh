TERMUX_PKG_HOMEPAGE=https://sourceforge.net/projects/dosemu/
TERMUX_PKG_DESCRIPTION="DOS Emulator"
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_MAINTAINER="@termux"
_COMMIT=a2ffb6b3ce856c53c2705646dd19537e6894e8ea
TERMUX_PKG_VERSION=1.4.0.8
TERMUX_PKG_SRCURL=https://sourceforge.net/code-snapshots/git/d/do/dosemu/code.git/dosemu-code-${_COMMIT}.zip
TERMUX_PKG_SHA256=16a0e18bcea53d0959716e1f598e881d5697a0ea86e54084bb052e5ae5cc56f7
TERMUX_PKG_DEPENDS="libx11, sdl"

UTERMUX_PKG_EXTRA_CONFIGURE_ARGS="
--disable-dynamic-x86
--disable-fpu-x86
--disable-opengl
"

termux_step_pre_configure() {
	[[ "${TERMUX_ARCH}" == "i686" ]] && CFLAGS+=" -fPIC"
	autoreconf -fi
}
