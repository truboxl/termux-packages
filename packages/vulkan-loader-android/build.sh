TERMUX_PKG_HOMEPAGE=https://source.android.com/devices/graphics/arch-vulkan
TERMUX_PKG_DESCRIPTION="Vulkan Loader for Android"
TERMUX_PKG_LICENSE="NCSA"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=$TERMUX_NDK_VERSION
TERMUX_PKG_REVISION=3
TERMUX_PKG_SKIP_SRC_EXTRACT=true
TERMUX_PKG_HOSTBUILD=true
TERMUX_PKG_CONFLICTS="vulkan-loader, vulkan-loader-x"

# Android Vulkan Loader
# https://source.android.com/devices/graphics/arch-vulkan
# https://android.googlesource.com/platform/frameworks/native/+/master/vulkan

# Vulkan functions exported by Android Vulkan Loader depending on API version
# https://android.googlesource.com/platform/frameworks/native/+/master/vulkan/libvulkan/libvulkan.map.txt

# For now this package provides the NDK stub libvulkan.so (Termux current minimum API verison)
# Due to confusion arised, symlink to system libs will be dropped and warning notice is shown

termux_step_host_build() {
	# it doesnt make sense to set vulkan.pc version to:
	# 1. vulkan-loader package version and bump this package every time the former updates
	# 2. NDK version since the stubs are the same between NDK releases AFAIK and isnt related to vulkan
	# so we use NDK provided vulkan header version but https://github.com/android/ndk/issues/1721
	# NDK shows that there is 2 different versions of vulkan headers
	cat <<- EOF > vulkan_header_version.c
	#include <stdio.h>
	#include "vulkan/vulkan_core.h"
	int main(void) {
		printf("%d.%d.%d\n",
			VK_HEADER_VERSION_COMPLETE >> 22,
			VK_HEADER_VERSION_COMPLETE >> 12 & 0x03ff,
			VK_HEADER_VERSION_COMPLETE & 0x0fff);
		return 0;
	}
	EOF
	rm -fr ./vulkan
	cp -fr "$NDK/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/vulkan" ./vulkan
	cc vulkan_header_version.c -o vulkan_header_version
}

# using termux_step_extract_into_massagedir seems to cause
# packages build after this cant find libvulkan.so
termux_step_post_make_install() {
	install -v -Dm644 "$TERMUX_STANDALONE_TOOLCHAIN/sysroot/usr/lib/$TERMUX_HOST_PLATFORM/$TERMUX_PKG_API_LEVEL/libvulkan.so" \
		"$TERMUX_PREFIX/lib/libvulkan.so"

	local vulkan_loader_version="$($TERMUX_PKG_HOSTBUILD_DIR/vulkan_header_version)"
	if [ -z "$vulkan_loader_version" ]; then
		termux_error_exit "ERROR: Host built vulkan_header_version is not printing version!"
	fi

	# based on https://github.com/KhronosGroup/Vulkan-Loader/blob/master/loader/vulkan.pc.in
	# not using "Libs.private"
	cat <<- EOF > "$TERMUX_PKG_TMPDIR/vulkan.pc"
	prefix=$TERMUX_PREFIX
	exec_prefix=\${prefix}
	libdir=\${exec_prefix}/lib
	includedir=\${prefix}/include

	Name: Vulkan-Loader
	Description: Vulkan Loader
	Version: $vulkan_loader_version
	Libs: -L\${libdir} -lvulkan
	Cflags: -I\${includedir}
	EOF
	install -Dm644 "$TERMUX_PKG_TMPDIR/vulkan.pc" "$TERMUX_PREFIX/lib/pkgconfig/vulkan.pc"
	echo "INFO: Printing vulkan.pc..."
	cat "$TERMUX_PREFIX/lib/pkgconfig/vulkan.pc"
}

termux_step_create_debscripts() {
	cat <<- EOF > postinst
	#!$TERMUX_PREFIX/bin/sh
	echo '
	WARNING: This "vulkan-loader-android" package is for building packages. Do not use this during runtime!
	' >&2
	EOF
}
