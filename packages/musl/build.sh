TERMUX_PKG_HOMEPAGE=https://musl.libc.org/
TERMUX_PKG_DESCRIPTION="Musl C library"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.2.3"
TERMUX_PKG_SRCURL=git+https://github.com/richfelker/musl-cross-make
TERMUX_PKG_GIT_BRANCH=master
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_pre_configure() {
	# References:
	# https://git.zv.io/toolchains/musl-cross-make/-/commit/f753d58b14987cc0fbdfea2f0040162da58c55b6

	# use host toolchain instead of NDK
	unset AR CC CFLAGS CPP CPPFLAGS CXX CXXFLAGS LD LDFLAGS NM OBJCOPY RANLIB

	export _TARGET="${TERMUX_ARCH}-linux-musl"
	case "${TERMUX_ARCH}" in
	arm) _TARGET="armv7-linux-musleabihf" ;;
	esac

	# handle hard and symbolic links
	local _WRAPPER_BIN="${TERMUX_PKG_BUILDDIR}/_wrapper/bin"
	local real_ln=$(command -v ln)
	mkdir -p "${_WRAPPER_BIN}"
	cat <<- EOL > "${_WRAPPER_BIN}/ln"
	#!$(command -v bash)
	case "\$1:\$2" in
	*:.*) ;;
	/*:*)
	${real_ln} -s \$@
	exit \$?
	;;
	[[:alpha:]]*:*)
	${real_ln} -s \$@
	exit \$?
	;;
	esac
	${real_ln} \$@
	EOL
	chmod +x "${_WRAPPER_BIN}/ln"
	export PATH="${_WRAPPER_BIN}:${PATH}"
}

termux_step_make() {
	:
}

termux_step_make_install() {
	local MUSL_TARGET

	for MUSL_TARGET in \
		aarch64-linux-musl \
		armv7-linux-musleabihf \
		i686-linux-musl \
		x86_64-linux-musl \
	; do
	echo "INFO: Stage 1 (${MUSL_TARGET})"

	cat <<- EOF > "${TERMUX_PKG_SRCDIR}/config.mak"
	BINUTILS_CONFIG += --enable-gold=yes
	DL_CMD = curl -sLo
	COMMON_CONFIG += CC="gcc -static --static"
	COMMON_CONFIG += CFLAGS="-Os"
	COMMON_CONFIG += CXX="g++ -static --static"
	COMMON_CONFIG += CXXFLAGS="-Os"
	COMMON_CONFIG += LDFLAGS="-s"
	GCC_CONFIG += --disable-bootstrap
	GCC_CONFIG += --disable-cet
	GCC_CONFIG += --disable-nls
	GCC_CONFIG += --enable-default-pie
	GCC_CONFIG += --enable-static-pie
	GNU_SITE = https://ftp.gnu.org/gnu
	MUSL_CONFIG = --enable-debug
	MUSL_VER = ${TERMUX_PKG_VERSION}
	TARGET = ${MUSL_TARGET}
	EOF
	if [[ "${MUSL_TARGET}" == "armv7"* ]]; then
	cat <<- EOF >> "${TERMUX_PKG_SRCDIR}/config.mak"
	GCC_CONFIG += --with-arch=armv7-a --with-fpu=neon
	EOF
	fi

	make \
		-j "${TERMUX_MAKE_PROCESSES}" \
		OUTPUT="${TERMUX_PREFIX}/opt/musl/cross" \
		install >/dev/null

	echo "INFO: Stage 1 clean (${MUSL_TARGET})"
	make -j "${TERMUX_MAKE_PROCESSES}" clean
	done

	pushd ${TERMUX_PREFIX}/opt/musl
	ls -l cross/lib/*
	popd
	export PATH="${TERMUX_PREFIX}/opt/musl/cross/bin:${PATH}"

	for MUSL_TARGET in \
		aarch64-linux-musl \
		armv7-linux-musleabihf \
		i686-linux-musl \
		x86_64-linux-musl \
	; do
	echo "INFO: Stage 2 (${_TARGET} -> ${MUSL_TARGET})"

	cat <<- EOF > "${TERMUX_PKG_SRCDIR}/config.mak"
	BINUTILS_CONFIG += --enable-gold=yes
	DL_CMD = curl -sLo
	COMMON_CONFIG += CC="${_TARGET}-gcc -static --static"
	COMMON_CONFIG += CFLAGS="-Os"
	COMMON_CONFIG += CXX="${_TARGET}-g++ -static --static"
	COMMON_CONFIG += CXXFLAGS="-Os"
	GCC_CONFIG += --disable-bootstrap
	GCC_CONFIG += --disable-cet
	GCC_CONFIG += --disable-nls
	GCC_CONFIG += --enable-default-pie
	GCC_CONFIG += --enable-static-pie
	GNU_SITE = https://ftp.gnu.org/gnu
	MUSL_CONFIG = --enable-debug
	MUSL_VER = ${TERMUX_PKG_VERSION}
	HOST = ${_TARGET//-musl*}
	TARGET = ${MUSL_TARGET}
	EOF
	if [[ "${MUSL_TARGET}" == "armv7"* ]]; then
	cat <<- EOF >> "${TERMUX_PKG_SRCDIR}/config.mak"
	GCC_CONFIG += --with-arch=armv7-a --with-fpu=neon
	EOF
	fi

	make \
		-j "${TERMUX_MAKE_PROCESSES}" \
		OUTPUT="${TERMUX_PREFIX}/opt/musl" \
		install >/dev/null

	echo "INFO: Stage 2 clean (${_TARGET} -> ${MUSL_TARGET})"
	make -j "${TERMUX_MAKE_PROCESSES}" clean
	done

	pushd ${TERMUX_PREFIX}/opt/musl
	ls -l lib/*
	popd
}
