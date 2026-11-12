TERMUX_PKG_HOMEPAGE=https://dev.yorhel.nl/ncdu
TERMUX_PKG_DESCRIPTION="Disk usage analyzer"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_LICENSE_FILE="LICENSES/MIT.txt"
TERMUX_PKG_MAINTAINER="Joshua Kahn <tom@termux.dev>"
TERMUX_PKG_VERSION="2.12.0"
TERMUX_PKG_REVISION=1
TERMUX_PKG_SRCURL="https://github.com/BratishkaErik/ncdu/releases/download/v${TERMUX_PKG_VERSION}/ncdu-${TERMUX_PKG_VERSION}-src.tar.gz"
TERMUX_PKG_SHA256=b01b5388bc6d87c16ecd04d5b3a079dcc9806763cd582162e499cf0cc56dfbb2
TERMUX_PKG_CONFLICTS="ncdu"
TERMUX_PKG_REPLACES="ncdu"
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_UPDATE_VERSION_REGEXP='^v\K2\.\d+(\.\d+)?$'
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_NO_ELF_CLEANER=true

termux_step_post_get_source() {
	local f
	f=$(sed -nE "s|.*SPDX-FileCopyrightText.*: (.*)|\1|p" ChangeLog)
	sed \
		-e "s|<year> <copyright holders>|${f}|" \
		-i LICENSES/MIT.txt

	cp "${TERMUX_PKG_BUILDER_DIR}/stat_shim.c" src/stat_shim.c
}

termux_step_pre_configure() {
	termux_setup_zig
	unset CFLAGS CXXFLAGS CPPFLAGS LDFLAGS
}

termux_step_make() {
	local _sysroot="${NDK}/toolchains/llvm/prebuilt/linux-x86_64/sysroot"
	local _libc_file="${TERMUX_PKG_TMPDIR}/zig-libc.txt"
	cat > "${_libc_file}" <<-EOF
	include_dir=${_sysroot}/usr/include
	sys_include_dir=${_sysroot}/usr/include/${TERMUX_HOST_PLATFORM}
	crt_dir=${_sysroot}/usr/lib/${TERMUX_HOST_PLATFORM}/${TERMUX_PKG_API_LEVEL}
	msvc_lib_dir=
	kernel32_lib_dir=
	cc_dir=${_sysroot}/usr/lib/${TERMUX_HOST_PLATFORM}/${TERMUX_PKG_API_LEVEL}
	darwin_sdk_dir=
	EOF

	export ZIG_GLOBAL_CACHE_DIR="${TERMUX_PKG_CACHEDIR}/zig-global-cache"

	if ! zig build \
			--libc "${_libc_file}" \
			--release=fast \
			--search-prefix "${TERMUX_PREFIX}" \
			--verbose \
			-Dstrip \
			-Dtarget="${TERMUX_ARCH}-linux-android.${TERMUX_PKG_API_LEVEL}"; then
		find "${ZIG_GLOBAL_CACHE_DIR}" -name "config.log" | sort | xargs -r -n1 -i sh -c "echo {}; cat {}"
		termux_error_exit "see above"
	fi
}

termux_step_make_install() {
	install -Dm755 -t "${TERMUX_PREFIX}/bin" zig-out/bin/ncdu
	install -Dm644 -t "${TERMUX_PREFIX}/share/man/man1" ncdu.1
}
