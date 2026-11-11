TERMUX_PKG_HOMEPAGE=https://dev.yorhel.nl/ncdu
TERMUX_PKG_DESCRIPTION="Disk usage analyzer"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_LICENSE_FILE="LICENSES/MIT.txt"
TERMUX_PKG_MAINTAINER="Joshua Kahn <tom@termux.dev>"
TERMUX_PKG_VERSION="2.13.0"
TERMUX_PKG_REVISION=1
TERMUX_PKG_SRCURL="https://github.com/BratishkaErik/ncdu/releases/download/v${TERMUX_PKG_VERSION}/ncdu-${TERMUX_PKG_VERSION}-src.tar.gz"
TERMUX_PKG_SHA256=425cd86b1100ebd85c852f9f8a37aaa29a2bd81685ed0c7ff1ca6a7e95a95d7e
TERMUX_PKG_CONFLICTS="ncdu"
TERMUX_PKG_REPLACES="ncdu"
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_UPDATE_VERSION_REGEXP='^v\K2\.\d+(\.\d+)?$'
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_NO_ELF_CLEANER=true
TERMUX_PKG_API_LEVEL=26

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

	local _sysroot="${NDK}/toolchains/llvm/prebuilt/linux-x86_64/sysroot"
	export ZIG_LIBC="${TERMUX_PKG_TMPDIR}/zig-libc.txt"
	cat > "${ZIG_LIBC}" <<-EOF
	include_dir=${_sysroot}/usr/include
	sys_include_dir=${_sysroot}/usr/include/${TERMUX_HOST_PLATFORM}
	crt_dir=${_sysroot}/usr/lib/${TERMUX_HOST_PLATFORM}/${TERMUX_PKG_API_LEVEL}
	msvc_lib_dir=
	kernel32_lib_dir=
	cc_dir=${_sysroot}/usr/lib/${TERMUX_HOST_PLATFORM}/${TERMUX_PKG_API_LEVEL}
	darwin_sdk_dir=
	EOF

	local p="${TERMUX_PKG_BUILDER_DIR}/build.zig.diff"
	echo "Applying patch: $(basename "${p}")"
	sed \
		-e "s|@API_LEVEL@|${TERMUX_PKG_API_LEVEL}|g" \
		-e "s|@CFLAGS@|${CFLAGS}|g" \
		-e "s|@CPPFLAGS@|${CPPFLAGS}|g" \
		-e "s|@LDFLAGS@|${LDFLAGS}|g" \
		-e "s|@PREFIX@|${_sysroot}/usr|g" \
		-e "s|@TRIPLE@|${TERMUX_HOST_PLATFORM}|g" \
		"${p}" |
		patch --silent -p1

	unset CFLAGS CXXFLAGS CPPFLAGS LDFLAGS
}

termux_step_make() {
	local target
	case "${TERMUX_ARCH}" in
	arm) target="arm-linux-androideabi" ;;
	i686) target="x86-linux-android" ;;
	*) target="${TERMUX_ARCH}-linux-android" ;;
	esac

	export ZIG_GLOBAL_CACHE_DIR="${TERMUX_PKG_CACHEDIR}/zig-global-cache"

	if ! zig build \
			--release=fast \
			-Dstrip \
			-Dcpu=baseline \
			-Dtarget="${target}"; then
		find . -name "config.log" | sort | xargs -i sh -c "echo {}; cat {}" || :

		termux_error_exit "see above"
	fi
}

termux_step_make_install() {
	install -Dm755 -t "${TERMUX_PREFIX}/bin" zig-out/bin/ncdu
	install -Dm644 -t "${TERMUX_PREFIX}/share/man/man1" ncdu.1
}
