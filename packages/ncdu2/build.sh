TERMUX_PKG_HOMEPAGE=https://dev.yorhel.nl/ncdu
TERMUX_PKG_DESCRIPTION="Disk usage analyzer"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_LICENSE_FILE="LICENSES/MIT.txt"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="2.3"
TERMUX_PKG_SRCURL=https://dev.yorhel.nl/download/ncdu-${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=bbce1d1c70f1247671be4ea2135d8c52cd29a708af5ed62cecda7dc6a8000a3c
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_post_get_source() {
	# TODO drop all this once figure out how zig can work with bionic libc
	local NCURSES_SRCURL=$(. "${TERMUX_SCRIPTDIR}"/packages/ncurses/build.sh; echo ${TERMUX_PKG_SRCURL[*]})
	local NCURSES_SHA256=$(. "${TERMUX_SCRIPTDIR}"/packages/ncurses/build.sh; echo ${TERMUX_PKG_SHA256[*]})
	local l=$(echo "${NCURSES_SRCURL}" | wc -w)

	rm -fr external ncurses
	mkdir -p external

	for i in $(seq 1 "${l}"); do
	local srcurl=$(echo "${NCURSES_SRCURL}" | awk "{print \$${i}}")
	local sha256=$(echo "${NCURSES_SHA256}" | awk "{print \$${i}}")
	local tar=${TERMUX_PKG_CACHEDIR}/$(basename "${srcurl}")
	termux_download "${srcurl}" "${tar}" "${sha256}"
	tar -xf "${tar}" -C external
	done

	pushd external
	for i in $(ls); do
	mv -v "${i}" "${i//-*}"
	done
	echo "INFO: Applying patches from packages/ncurses"
	for p in "${TERMUX_SCRIPTDIR}"/packages/ncurses/*.patch; do
	patch -p1 -i "${p}" -d ncurses
	done
	popd

	ln -sv external/ncurses ncurses

	sed \
		-e "s|--with-default-terminfo-dir=/usr|--with-default-terminfo-dir=${TERMUX_PREFIX}|" \
		-i Makefile
}

termux_step_pre_configure() {
	termux_setup_zig
	unset CFLAGS LDFLAGS
}

termux_step_make() {
	make -j "${TERMUX_MAKE_PROCESSES}" static-${ZIG_TARGET_NAME}.tar.gz
}

termux_step_make_install() {
	# allow ncdu2 to co-exist with ncdu
	tar -xf static-${ZIG_TARGET_NAME}.tar.gz
	mv -v ncdu ncdu2
	mv -v ncdu.1 ncdu2.1
	install -Dm755 -t "${TERMUX_PREFIX}/bin" ncdu2
	install -Dm644 -t "${TERMUX_PREFIX}/share/man/man1" ncdu2.1
}
