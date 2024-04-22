TERMUX_PKG_HOMEPAGE=https://ziglang.org/
TERMUX_PKG_DESCRIPTION="General-purpose programming language and toolchain"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_LICENSE_FILE="LICENSE"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=(
	0.12.0
	0.11.0
)
TERMUX_PKG_SRCURL=(
	https://github.com/ziglang/zig/archive/refs/tags/${TERMUX_PKG_VERSION[0]}.tar.gz
	https://github.com/ziglang/zig-bootstrap/archive/refs/tags/${TERMUX_PKG_VERSION[1]}.tar.gz
)
TERMUX_PKG_SHA256=(
	57d7e0ad565ef734d9f3fe8cff7a815f2ab012ec3d8e155a316dfc79f789c432
	046cede54ae0627c6ac98a1b3915242b35bc550ac7aaec3ec4cef6904c95019e
)
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_UPDATE_TAG_TYPE="newest-tag"

termux_step_post_get_source() {
	pushd zig-bootstrap-${TERMUX_PKG_VERSION[1]}
	rm -fr zig
	ln -fsv .. zig
	popd

	local bootstrap_patches=$(find "${TERMUX_PKG_BUILDER_DIR}" -mindepth 1 -maxdepth 1 -type f -name 'bootstrap-*.diff')
	if [[ -n "${bootstrap_patches}" ]]; then
		pushd "zig-bootstrap-${TERMUX_PKG_VERSION[1]}"
		for patch in ${bootstrap_patches}; do
			patch -p1 -i "${patch}" || :
		done
		local bootstrap_patches_rej=$(find . -type f -name '*.rej')
		if [[ -n "${bootstrap_patches_rej}" ]]; then
			echo "INFO: Patch failed! Printing *.rej files ..."
			for rej in ${bootstrap_patches_rej}; do
				echo -e "\n\n${rej}"
				cat "${rej}"
			done
			termux_error_exit "Patch failed! Please check patch errors above!"
		fi
		popd
	fi

	mv -v build.zig.zon build.zig.zon.unused
}

termux_step_pre_configure() {
	termux_setup_cmake
	termux_setup_ninja
	termux_setup_zig
	TERMUX_PKG_SRCDIR=${TERMUX_PKG_SRCDIR}/zig-bootstrap-${TERMUX_PKG_VERSION[1]}
}

termux_step_make() {
	pushd zig-bootstrap-${TERMUX_PKG_VERSION[1]}
	# zig 0.11.0+ uses 3 stages bootstrapping build system
	# which NDK cant be used anymore
	unset AS CC CFLAGS CPP CPPFLAGS CXX CXXFLAGS LD LDFLAGS

	# build.patch skipped various steps to make CI build <6 hours
	./build "${ZIG_TARGET_NAME}" baseline
	popd
}

termux_step_make_install() {
	pushd zig-bootstrap-${TERMUX_PKG_VERSION[1]}
	cp -fr "out/zig-${ZIG_TARGET_NAME}-baseline" "${TERMUX_PREFIX}/lib/zig"
	ln -fsv "../lib/zig/zig" "${TERMUX_PREFIX}/bin/zig"
	popd
}
