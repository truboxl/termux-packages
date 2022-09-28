TERMUX_PKG_HOMEPAGE=https://github.com/rui314/mold
TERMUX_PKG_DESCRIPTION="mold: A Modern Linker"
TERMUX_PKG_LICENSE="AGPL-V3"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.7.0"
TERMUX_PKG_SRCURL=https://github.com/rui314/mold/archive/v${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=ccd685afcdb7047f8a8ce8b5ce3b3cd22205a0ebc548ff1f1da7b35415fafbe4

# dont depend on libtbb, xxhash as upstream has other plans
# https://github.com/rui314/mold/commit/add94b86266b40bc66789e26358675da9d603919#commitcomment-80494077
TERMUX_PKG_DEPENDS="libandroid-spawn, libc++, openssl, zlib, zstd"

# dont set TERMUX_PKG_AUTO_UPDATE=true as license may change in the future

termux_step_pre_configure() {
	# dogfood except for arm
	if [[ "${TERMUX_ARCH}" != "arm" ]]; then
		termux_setup_mold
	fi

	# dont use MOLD_LTO=ON due to broken CMAKE_ANDROID_NDK_VERSION detection until CMake 3.25.0
	# https://github.com/Kitware/CMake/commit/1c86e397fe20b89521842617258db33079e34d1f
	# but LTO is blocking for NDK r25 with mold
	#export CFLAGS+=" -flto=thin"
	#export CXXFLAGS+=" -flto=thin"
	#export LDFLAGS+=" -flto=thin"
}
