TERMUX_PKG_HOMEPAGE=https://github.com/rui314/mold
TERMUX_PKG_DESCRIPTION="mold: A Modern Linker"
TERMUX_PKG_LICENSE="AGPL-V3"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=1.0.3
_COMMIT=6ffcae428622c216b5f77384a7456fa248981d7c
TERMUX_PKG_SRCURL=https://github.com/rui314/mold.git
TERMUX_PKG_GIT_BRANCH=main
TERMUX_PKG_DEPENDS="libc++, openssl, zlib, xxhash, libandroid-spawn"
TERMUX_PKG_BUILD_IN_SRC=true

termux_post_get_source() {
	git fetch --unshallow
	git reset --hard ${_COMMIT}
}

termux_step_pre_configure() {
	# onetbb use cmake
	termux_setup_cmake
}

termux_step_make() {
	# Have to override Makefile variables here
	# else need to patch Makefile
	# When building mold-wrapper.so cant find
	# spawn.h from libandroid-spawn for some reason
	# Manually link just in case to avoid runtime surprises
	make -j ${TERMUX_MAKE_PROCESSES} \
		PREFIX="${TERMUX_PREFIX}" \
		CFLAGS="${CFLAGS} -I${TERMUX_PREFIX}/include" \
		CXXFLAGS="${CXXFLAGS}" \
		STRIP="${STRIP}" \
		SYSTEM_XXHASH=1 \
		MOLD_WRAPPER_LDFLAGS=" -ldl -landroid-spawn"
}

termux_step_make_install() {
	make -j 1 install \
		PREFIX="${TERMUX_PREFIX}" \
		CFLAGS="${CFLAGS} -I${TERMUX_PREFIX}/include" \
		CXXFLAGS="${CXXFLAGS}" \
		STRIP="${STRIP}" \
		SYSTEM_XXHASH=1 \
		MOLD_WRAPPER_LDFLAGS=" -ldl -landroid-spawn"
}
