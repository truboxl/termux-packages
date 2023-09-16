TERMUX_PKG_HOMEPAGE=https://musl.libc.org/
TERMUX_PKG_DESCRIPTION="An implementation of the C standard library built on top of the Linux system call API"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.2.4"
TERMUX_PKG_SRCURL=https://musl.libc.org/releases/musl-${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=7a35eae33d5372a7c0da1188de798726f68825513b7ae3ebe97aaaa52114f039
TERMUX_PKG_NO_STATICSPLIT=true

# do not override --syslibdir
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
--enable-debug
--enable-wrapper=all
--libdir=${TERMUX_PREFIX}/opt/musl/lib
--prefix=${TERMUX_PREFIX}/opt/musl
"

termux_step_post_get_source() {
	export _COMPILER_RT_VERSION=17.0.6
	export _COMPILER_RT_SRCURL="https://github.com/llvm/llvm-project/releases/download/llvmorg-${_COMPILER_RT_VERSION}/compiler-rt-${_COMPILER_RT_VERSION}.src.tar.xz"
	export _COMPILER_RT_SHA256=11b8d09dcf92a0f91c5c82defb5ad9ff4acf5cf073a80c317204baa922d136b4

	termux_download \
		"${_COMPILER_RT_SRCURL}" \
		"${TERMUX_PKG_CACHEDIR}/$(basename "${_COMPILER_RT_SRCURL}")" \
		"${_COMPILER_RT_SHA256}"

	tar -xf "${TERMUX_PKG_CACHEDIR}/compiler-rt-${_COMPILER_RT_VERSION}.src.tar.xz"
}

termux_step_pre_configure() {
	# https://developer.android.com/ndk/guides/abis#x86
	# https://gcc.gnu.org/onlinedocs/gcc/x86-Options.html#index-mlong-double-64-1
	# https://github.com/llvm/llvm-project/blob/main/compiler-rt/lib/builtins/CMakeLists.txt

	case "${TERMUX_ARCH}" in
	i686|x86_64)
		export CFLAGS+=" -mlong-double-80"
		;;
	esac

	# x86, x86_64: ld.lld: error: undefined symbol: __mulxc3
	local libgcc_ndk=$(${CC} -print-libgcc-file-name)
	local libgcc_new=${TERMUX_PKG_BUILDDIR}/$(basename ${libgcc_ndk})
	cp -f ${libgcc_ndk} ${libgcc_new}
	${CC} ${CFLAGS} ${CPPFLAGS} -c compiler-rt-${_COMPILER_RT_VERSION}.src/lib/builtins/mulxc3.c -o ${TERMUX_PKG_BUILDDIR}/mulxc3.c.o
	${AR} cru ${libgcc_new} ${TERMUX_PKG_BUILDDIR}/mulxc3.c.o

	# Arm: duplicate symbols error if put in LDFLAGS
	TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" LIBCC=${libgcc_new}"
}

termux_step_post_make_install() {
	for b in "${TERMUX_PREFIX}"/opt/musl/bin/*; do
		b=$(basename "${b}")
		ln -fsv "../opt/musl/bin/${b}" "${TERMUX_PREFIX}/bin/${b}"
	done
}
