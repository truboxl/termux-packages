TERMUX_PKG_HOMEPAGE=https://github.com/KhronosGroup/Vulkan-Loader
TERMUX_PKG_DESCRIPTION="Vulkan Loader"
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_MAINTAINER="@termux"
# All Khronos vulkan packages should be updated at same time. Otherwise, they do not compile successfully.
TERMUX_PKG_VERSION="1.3.225"
TERMUX_PKG_SRCURL=https://github.com/KhronosGroup/Vulkan-Loader/archive/v${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=f20a5dcd016971b497659732ba3410aca7663f45554d24094509e4ffd0cc3239
TERMUX_PKG_BUILD_DEPENDS="vulkan-headers (=${TERMUX_PKG_VERSION})"
TERMUX_PKG_CONFLICTS="vulkan-loader-android"
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_UPDATE_TAG_TYPE="newest-tag"

# Desktop Vulkan Loader
# https://github.com/KhronosGroup/Vulkan-Loader/blob/master/loader/LoaderAndLayerInterface.md

# https://github.com/KhronosGroup/Vulkan-Loader/blob/master/CMakeLists.txt
# https://github.com/KhronosGroup/Vulkan-Loader/blob/master/loader/CMakeLists.txt
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-DBUILD_WSI_WAYLAND_SUPPORT=OFF
-DBUILD_WSI_XCB_SUPPORT=OFF
-DBUILD_WSI_XLIB_SUPPORT=OFF
-DUSE_GAS=OFF
"

# https://github.com/termux/termux-packages/commit/571db28a3dc962a780c7051954db91d85a4eaff7
# https://github.com/KhronosGroup/Vulkan-Loader/commit/3c1ad4b0d54875ff0899b77a92aeda53ca236f27
# do sanity check at termux_step_post_make_install
TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" -DCMAKE_INSTALL_LIBDIR=lib"

termux_step_pre_configure() {
	# https://github.com/KhronosGroup/Vulkan-LoaderAndValidationLayers/blob/master/loader/CMakeLists.txt#L227
	export CFLAGS="$CFLAGS -Wno-typedef-redefinition"
}

termux_step_post_make_install() {
	echo "INFO: Printing vulkan.pc..."
	cat "$TERMUX_PREFIX/lib/pkgconfig/vulkan.pc"
}

termux_step_create_debscripts() {
	cat <<- EOF > postinst
	#!$TERMUX_PREFIX/bin/sh
	echo '
	WARNING: This "vulkan-loader" package is for building packages. Do not use this during runtime!
	' >&2
	EOF
}
