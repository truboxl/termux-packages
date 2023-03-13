TERMUX_PKG_HOMEPAGE=https://justine.lol/blinkenlights/
TERMUX_PKG_DESCRIPTION="Tiniest x86-64-linux emulator"
TERMUX_PKG_LICENSE="ISC"
TERMUX_PKG_MAINTAINER="@termux"
_COMMIT=7d3fa0d1525dd0863dd57cfc4a6e60000795fab6
_COMMIT_DATE=20230318
TERMUX_PKG_VERSION="0.9.2-p20230318"
TERMUX_PKG_SRCURL=https://github.com/jart/blink/archive/${_COMMIT}.tar.gz
TERMUX_PKG_SHA256=f7eb9000016c09b1d06be847dfe94231a08a52d693c4d6589608ab0330f83d20
TERMUX_PKG_DEPENDS="zlib"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_UPDATE_TAG_TYPE="newest-tag"

termux_step_pre_configure() {
	# from Makefile
	export CPPFLAGS+=" -D_FILE_OFFSET_BITS=64 -D_DARWIN_C_SOURCE -D_DEFAULT_SOURCE -D_BSD_SOURCE -D_GNU_SOURCE"
}

termux_step_configure() {
	# custom configure script that errors
	# instead of ignores unknown arguments
	# also run tests on host rather than target
	# which gives wrong result
	# we run this to generate config.h and config.mk
	./configure

	sed -i config.mk \
		-e "s|^TMPDIR =.*|TMPDIR = ${TERMUX_PKG_TMPDIR}|" \
		-e "s|^PREFIX =.*|PREFIX = ${TERMUX_PREFIX}|" \
		#-e "s|^LDLIBS =.*|LDLIBS = -lz -lm|" \

	# Android hard code to page size 4096
	# CANNOT LINK EXECUTABLE "blink": can't enable GNU RELRO protection for "blink": Out of memory
	sed -i config.mk \
		-e "s|-Wl,-z,common-page-size=65536,-z,max-page-size=65536||g"

	# these are for page size 64k to shrink binary size
	# not useful and maybe conflicting for Termux build
	sed -i config.mk \
		-e "s|-Wl,-z,norelro||g" \
		-e "s|-Wl,-z,noseparate-code||g"

	# replace config.h and enable all working features
	# TODO port libandroid-getsetdomainname from Android O
	# TODO port libandroid-fexecve from Android P
	cp -f config.h.in config.h
	sed -i config.h \
		-e "s|^// #define HAVE_|#define HAVE_|g" \
		-e "s|^#define HAVE_SYSCTL|// #define HAVE_SYSCTL|" \
		-e "s|^#define HAVE_SA_LEN|// #define HAVE_SA_LEN|" \
		-e "s|^#define HAVE_KERN_ARND|// #define HAVE_KERN_ARND|" \
		-e "s|^#define HAVE_RTLGENRANDOM|// #define HAVE_RTLGENRANDOM|" \
		-e "s|^#define HAVE_GETDOMAINNAME|// #define HAVE_GETDOMAINNAME|" \

	if [[ "${TERMUX_ARCH}" == "arm" ]] || [[ "${TERMUX_ARCH}" == "i686" ]]; then
		sed -i config.h -e "s|^#define HAVE_INT128|// #define HAVE_INT128|"
	fi

	echo "========== config.log =========="
	cat config.log
	echo "========== config.log =========="
	echo "========== config.h =========="
	cat config.h
	echo "========== config.h =========="
	echo "========== config.mk =========="
	cat config.mk
	echo "========== config.mk =========="
}
