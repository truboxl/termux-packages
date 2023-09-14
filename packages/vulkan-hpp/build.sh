TERMUX_PKG_HOMEPAGE=https://github.com/KhronosGroup/Vulkan-Hpp
TERMUX_PKG_DESCRIPTION="Vulkan C++ Bindings"
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_MAINTAINER="@termux"
_COMMIT=d4704cce01ba5e27caa25ddd37e8fbb251d30032
TERMUX_PKG_VERSION="1.3.262-p20230709"
TERMUX_PKG_SRCURL=git+https://github.com/KhronosGroup/Vulkan-Hpp
TERMUX_PKG_GIT_BRANCH=main
TERMUX_PKG_BUILD_DEPENDS="libc++"
TERMUX_PKG_PLATFORM_INDEPENDENT=true
TERMUX_PKG_AUTO_UPDATE=false
TERMUX_PKG_UPDATE_TAG_TYPE="newest-tag"
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-DVULKAN_HPP_INSTALL=ON
-DVulkanHeaders_INCLUDE_DIR=${TERMUX_PKG_SRCDIR}
"

termux_step_post_get_source() {
	git fetch --unshallow
	git checkout "${_COMMIT}"
	git submodule update --init --recursive --depth=1
	git clean -ffxd
}
