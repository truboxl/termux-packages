TERMUX_PKG_HOMEPAGE=https://wasi.dev/
TERMUX_PKG_DESCRIPTION="Libc for WebAssembly programs built on top of WASI system calls"
TERMUX_PKG_LICENSE="Apache-2.0, BSD 2-Clause, MIT"
TERMUX_PKG_LICENSE_FILE="LICENSE, src/wasi-libc/LICENSE-MIT, src/wasi-libc/libc-bottom-half/cloudlibc/LICENSE"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=20
TERMUX_PKG_SRCURL=https://github.com/WebAssembly/wasi-sdk/archive/refs/tags/wasi-sdk-${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=28f317520d9b522134f7a014b84833d91ab1329fbd697bad05aa4fcfa2746c83
TERMUX_PKG_PLATFORM_INDEPENDENT=true
TERMUX_PKG_NO_STATICSPLIT=true
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_post_get_source() {
	local WASI_LIBC_SRCURL="https://github.com/WebAssembly/wasi-libc/archive/refs/tags/wasi-sdk-${TERMUX_PKG_VERSION}.tar.gz"
	local WASI_LIBC_SHA256=0a1c09c8c1da62a1ba214254ff4c9db6b60979c00f648a5eae33831d6ee2840e
	local LLVM_VERSION=$(. "${TERMUX_SCRIPTDIR}/packages/libllvm/build.sh"; echo ${TERMUX_PKG_VERSION})
	local LLVM_SRCURL="https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/llvm-project-${LLVM_VERSION}.src.tar.xz"
	local LLVM_SHA256=be5a1e44d64f306bb44fce7d36e3b3993694e8e6122b2348608906283c176db8

	termux_download \
		"${WASI_LIBC_SRCURL}" \
		"${TERMUX_PKG_CACHEDIR}/wasi-libc-${TERMUX_PKG_VERSION}.tar.gz" \
		"${WASI_LIBC_SHA256}"
	termux_download \
		"${LLVM_SRCURL}" \
		"${TERMUX_PKG_CACHEDIR}/$(basename "${LLVM_SRCURL}")" \
		"${LLVM_SHA256}"

	tar -xf "${TERMUX_PKG_CACHEDIR}/wasi-libc-${TERMUX_PKG_VERSION}.tar.gz" -C src
	tar -xf "${TERMUX_PKG_CACHEDIR}/llvm-project-${LLVM_VERSION}.src.tar.xz" -C src
	rm -frv src/{config,llvm-project,wasi-libc}
	mv -v "src/wasi-libc-wasi-sdk-${TERMUX_PKG_VERSION}" src/wasi-libc
	mv -v "src/llvm-project-${LLVM_VERSION}.src" src/llvm-project
}

termux_step_pre_configure() {
	termux_setup_cmake
	termux_setup_ninja

	# TODO NDK r26 onwards support wasm32 target
	if [[ "${TERMUX_ON_DEVICE_BUILD}" == "false" ]]; then
		export CC="/usr/bin/clang-15"
		export CXX="/usr/bin/clang++-15"
	fi
	export AR=$(command -v llvm-ar)
	export NM=$(command -v llvm-nm)
	export INSTALL_DIR="${TERMUX_PREFIX}/share/wasi-sysroot"
	export NINJA_FLAGS="-j ${TERMUX_MAKE_PROCESSES}"

	sed \
		-e "s|CC=\$(BUILD_PREFIX).*|CC=${CC} \\\\|g" \
		-e "s|AR=\$(BUILD_PREFIX).*|AR=${AR} \\\\|g" \
		-e "s|NM=\$(BUILD_PREFIX).*|NM=${NM} \\\\|g" \
		-e "s|cp -R \$(ROOT_DIR)/build/llvm/|#cp -R \$(ROOT_DIR)/build/llvm/|g" \
		-i Makefile
	sed \
		-e "/^set(CMAKE_C_COMPILER .*/d" \
		-e "/^set(CMAKE_CXX_COMPILER .*/d" \
		-e "/^set(CMAKE_ASM_COMPILER .*/d" \
		-e "/^set(CMAKE_AR .*/d" \
		-e "/^set(CMAKE_NM .*/d" \
		-e "/^set(CMAKE_RANLIB .*/d" \
		-i wasi-sdk.cmake wasi-sdk-pthread.cmake

	mkdir -p build
	touch build/llvm.BUILT # use our own LLVM
	touch build/config.BUILT # use our own autoconf config.guess
}

termux_step_make_install() {
	cp -fr "build/install/${TERMUX_PREFIX}" "$(dirname "${TERMUX_PREFIX}")"
	install -v -Dm644 -t "${TERMUX_PREFIX}/share/cmake/Platform" \
		wasi-sdk.cmake \
		wasi-sdk-pthread.cmake \
		cmake/Platform/WASI.cmake
}
