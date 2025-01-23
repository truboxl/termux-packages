TERMUX_PKG_HOMEPAGE=https://libclc.llvm.org
TERMUX_PKG_DESCRIPTION="Open source implementation of OpenCL 1.1 library"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="19.1.7"
TERMUX_PKG_SRCURL=https://github.com/llvm/llvm-project/releases/download/llvmorg-${TERMUX_PKG_VERSION}/llvm-project-${TERMUX_PKG_VERSION}.src.tar.xz
TERMUX_PKG_SHA256=82401fea7b79d0078043f7598b835284d6650a75b93e64b6f761ea7b63097501
TERMUX_PKG_DEPENDS="libc++, libllvm"
TERMUX_PKG_BUILD_DEPENDS="libllvm-static"
TERMUX_PKG_HOSTBUILD=true

termux_step_host_build() {
	termux_setup_cmake
	termux_setup_ninja

	cmake \
		-G Ninja \
		-DCMAKE_BUILD_TYPE=Release \
		-DLLVM_ENABLE_PROJECTS='clang;libclc' \
		-DLLVM_INCLUDE_BENCHMARKS=OFF \
		-DLLVM_INCLUDE_EXAMPLES=OFF \
		-DLLVM_INCLUDE_TESTS=OFF \
		-DLLVM_INCLUDE_UTILS=OFF \
		"${TERMUX_PKG_SRCDIR}/llvm"
	ninja \
		-j "${TERMUX_PKG_MAKE_PROCESSES}" \
		clang llvm-as llvm-link opt prepare_builtins
}

termux_step_pre_configure() {
	TERMUX_PKG_SRCDIR=${TERMUX_PKG_SRCDIR}/libclc
	if [[ "${TERMUX_ON_DEVICE_BUILD}" == "false" ]]; then
		#local tool
		#for tool in clang llvm-as llvm-link; do
		#	ln -fsv "${TERMUX_STANDALONE_TOOLCHAIN}/bin/${tool}" "${TERMUX_PKG_HOSTBUILD_DIR}/bin"
		#done
		TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" -DLIBCLC_CUSTOM_LLVM_TOOLS_BINARY_DIR=${TERMUX_PKG_HOSTBUILD_DIR}/bin"
	fi
}
