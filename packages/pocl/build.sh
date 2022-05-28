TERMUX_PKG_HOMEPAGE=https://portablecl.org
TERMUX_PKG_DESCRIPTION="Portable Computing Language"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=3.0-RC1
TERMUX_PKG_SRCURL=https://github.com/pocl/pocl/archive/v${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=98f0dc924dfc9d236bd98f1964d074f23fba85e8571a5b76b37d4e22c64531d8
TERMUX_PKG_BUILD_DEPENDS="opencl-headers"
TERMUX_PKG_DEPENDS="hwloc, libllvm, llvm, ocl-icd"
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-DCMAKE_BUILD_TYPE=MinSizeRel
-DCMAKE_LIBRARY_PATH=$TERMUX_PREFIX/lib
-DCMAKE_PREFIX_PATH=$TERMUX_PREFIX

-DENABLE_LLVM=OFF
-DLLC_HOST_CPU=generic
"

termux_step_pre_configure() {
	# based on
	# scripts/build/configure/termux_step_configure_cmake.sh
	# scripts/build/termux_step_setup_variables.sh
	TERMUX_HOST_PLATFORM="${TERMUX_ARCH}-linux-android"
	if [ "$TERMUX_ARCH" = "arm" ]; then TERMUX_HOST_PLATFORM="${TERMUX_HOST_PLATFORM}eabi"; fi
	TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" -DHOST_DEVICE_BUILD_HASH=${TERMUX_HOST_PLATFORM}-generic"
}
