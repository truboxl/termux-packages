TERMUX_PKG_HOMEPAGE=https://julialang.org/
TERMUX_PKG_DESCRIPTION="The Julia Programming Language"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.11.2"
TERMUX_PKG_SRCURL=https://github.com/JuliaLang/julia/releases/download/v${TERMUX_PKG_VERSION}/julia-${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=5d56c7163aefbf4dfb97d97388f93175826bcc3f4b0e885fa351694f84dc70c4
TERMUX_PKG_DEPENDS="libc++, libllvm, libuv, p7zip"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_MAKE_PROCESSES=1
TERMUX_PKG_EXTRA_MAKE_ARGS="
USE_SYSTEM_CSL=1
USE_SYSTEM_LLVM=1
USE_SYSTEM_LIBUNWIND=1
DISABLE_LIBUNWIND=0
USE_SYSTEM_PCRE=1
USE_SYSTEM_LIBM=1
USE_SYSTEM_OPENLIBM=1
UNTRUSTED_SYSTEM_LIBM=0
USE_SYSTEM_DSFMT=1
USE_SYSTEM_LIBBLASTRAMPOLINE=1
USE_SYSTEM_BLAS=0
USE_SYSTEM_LAPACK=1
USE_SYSTEM_GMP=1
USE_SYSTEM_MPFR=1
USE_SYSTEM_LIBSUITESPARSE=0
USE_SYSTEM_LIBUV=1
USE_SYSTEM_UTF8PROC=1
USE_SYSTEM_MBEDTLS=1
USE_SYSTEM_LIBSSH2=1
USE_SYSTEM_NGHTTP2=1
USE_SYSTEM_CURL=1
USE_SYSTEM_LIBGIT2=1
USE_SYSTEM_PATCHELF=1
USE_SYSTEM_LIBWHICH=1
USE_SYSTEM_ZLIB=1
USE_SYSTEM_P7ZIP=1
USE_SYSTEM_LLD=1
LLVM_CONFIG=${TERMUX_PREFIX}/bin/llvm-config
V=1
LOCALBASE=${TERMUX_PREFIX}
"

termux_step_pre_configure() {
	termux_setup_cmake

	if [[ "${TERMUX_ARCH}" == "arm" ]]; then
		TERMUX_PKG_EXTRA_MAKE_ARGS+=" XCHOST=armv7a-linux-androideabi"
	else
		TERMUX_PKG_EXTRA_MAKE_ARGS+=" XCHOST=${TERMUX_ARCH}-linux-android"
	fi
	CFLAGS+=" -v"
	LDFLAGS+=" -Wl,--undefined-version"
}
