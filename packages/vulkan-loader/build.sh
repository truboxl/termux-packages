TERMUX_PKG_HOMEPAGE=https://github.com/KhronosGroup/Vulkan-Loader
TERMUX_PKG_DESCRIPTION="Vulkan Loader"
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.3.240"
TERMUX_PKG_SRCURL=https://github.com/KhronosGroup/Vulkan-Loader/archive/v${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=7ea479c22f70d453dd029503c2664733cd01f98948af1e483308ef721175cfc8
TERMUX_PKG_BUILD_DEPENDS="vulkan-headers (=${TERMUX_PKG_VERSION}), libxcb, libx11, libwayland"
TERMUX_PKG_CONFLICTS="vulkan-loader-android"
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_UPDATE_TAG_TYPE="newest-tag"

# Desktop Vulkan Loader
# https://github.com/KhronosGroup/Vulkan-Loader/blob/master/loader/LoaderAndLayerInterface.md

# https://github.com/KhronosGroup/Vulkan-Loader/blob/master/CMakeLists.txt
# https://github.com/KhronosGroup/Vulkan-Loader/blob/master/loader/CMakeLists.txt
NO_TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
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
	'
	EOF
}
