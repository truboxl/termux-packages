TERMUX_PKG_HOMEPAGE=https://dosemu2.github.io/dosemu2/
TERMUX_PKG_DESCRIPTION="Emulator for running DOS programs under Linux"
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=2.0-b7076
TERMUX_PKG_SRCURL=git+https://github.com/dosemu2/dosemu2
TERMUX_PKG_GIT_BRANCH=2.0pre9
TERMUX_PKG_DEPENDS="libandroid-shmem, libx11, sdl"
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_pre_configure() {
	#termux_setup_no_integrated_as
	#CFLAGS+=" -fno-integrated-as"
	LDFLAGS+=" -landroid-shmem -Wl,-pie"
	export ASFLAGS+=" -fPIC"
	autoreconf -fi
	pushd src/plugin/sdl
	autoreconf -fi
	popd
}

# dosemu2 versioning is a mess
# Do not turn on auto update for now
