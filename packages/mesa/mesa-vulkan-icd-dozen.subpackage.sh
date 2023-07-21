TERMUX_SUBPKG_DESCRIPTION="Mesa's Dozen Vulkan ICD"
TERMUX_SUBPKG_DEPEND_ON_PARENT="no"
TERMUX_SUBPKG_DEPENDS="libandroid-shmem, libc++, libdrm, libwayland, libx11, libxcb, zlib, zstd"
TERMUX_SUBPKG_EXCLUDED_ARCHES="aarch64, arm, i686"
TERMUX_SUBPKG_INCLUDE="
lib/libvulkan_dzn.so
share/vulkan/icd.d/dzn_icd.*.json
"
