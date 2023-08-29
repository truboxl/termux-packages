TERMUX_PKG_HOMEPAGE=https://justine.lol/blinkenlights/
TERMUX_PKG_DESCRIPTION="Tiny x86-64 Linux emulator"
TERMUX_PKG_LICENSE="ISC"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=1:1.0.0
TERMUX_PKG_SRCURL=https://github.com/jart/blink/archive/${TERMUX_PKG_VERSION#*:}.tar.gz
TERMUX_PKG_SHA256=09ffc3cdb57449111510bbf2f552b3923d82a983ef032ee819c07f5da924c3a6
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_configure() {
	# build system does not work with cross compilers
	# https://github.com/jart/blink/issues/111

	export CPPFLAGS+=" -D_FILE_OFFSET_BITS=64 -D_DARWIN_C_SOURCE -D_DEFAULT_SOURCE -D_BSD_SOURCE -D_GNU_SOURCE"
	export LDFLAGS+=" -lm"
	./configure --prefix="${TERMUX_PREFIX}"

	# Android hard code to page size 4096
	# CANNOT LINK EXECUTABLE "blink": can't enable GNU RELRO protection for "blink": Out of memory
	sed \
		-e "s|-Wl,-z,common-page-size=65536,-z,max-page-size=65536||g" \
		-e "s|-Wl,-z,norelro||g" \
		-e "s|-Wl,-z,noseparate-code||g" \
		-i config.mk

	# https://github.com/jart/blink/blob/master/config.h.in
	# replace host generated config.h with our own
	# please check with a real device
	cp -f config.h.in config.h
	sed -e "s|^// #define HAVE_|#define HAVE_|g" -i config.h

	sed -e "s|^#define HAVE_SYSCTL|// #define HAVE_SYSCTL|" -i config.h

	if [[ "${TERMUX_ARCH_BITS}" == "32" ]]; then
		sed -e "s|^#define HAVE_INT128|// #define HAVE_INT128|" -i config.h
	fi

	sed -e "s|^#define HAVE_SA_LEN|// #define HAVE_SA_LEN|" -i config.h

	# TODO port libandroid-fexecve from Android P
	sed -e "s|^#define HAVE_FEXECVE|// #define HAVE_FEXECVE|" -i config.h

	# Bad System Call
	sed -e "s|^#define HAVE_SETREUID|// #define HAVE_SETREUID|" -i config.h

	sed -e "s|^#define HAVE_KERN_ARND|// #define HAVE_KERN_ARND|" -i config.h

	# TODO port libandroid-random from Android P
	sed -e "s|^#define HAVE_GETRANDOM|// #define HAVE_GETRANDOM|" -i config.h

	# Bad System Call
	sed -e "s|^#define HAVE_SETGROUPS|// #define HAVE_SETGROUPS|" -i config.h

	sed -e "s|^#define HAVE_LIBUNWIND|// #define HAVE_LIBUNWIND|" -i config.h

	# TODO port libandroid-random from Android P
	sed -e "s|^#define HAVE_GETENTROPY|// #define HAVE_GETENTROPY|" -i config.h

	sed \
		-e "s|^#define HAVE_RTLGENRANDOM|// #define HAVE_RTLGENRANDOM|" \
		-e "s|^#define HAVE_LIBUNWIND|// #define HAVE_LIBUNWIND|" \
		-e "s|^#define HAVE_EPOLL_PWAIT2|// #define HAVE_EPOLL_PWAIT2|" \
		-i config.h

	# TODO port libandroid-getsetdomainname from Android O
	sed \
		-e "s|^#define HAVE_GETDOMAINNAME|// #define HAVE_GETDOMAINNAME|" \
		-i config.h

	# Bad System Call
	sed \
		-e "s|^#define HAVE_CLOCK_SETTIME|// #define HAVE_CLOCK_SETTIME|" \
		-i config.h

	sed \
		-e "s|^#define HAVE_SYS_GETENTROPY|// #define HAVE_SYS_GETENTROPY|" \
		-e "s|^#define HAVE_PTHREAD_SETCANCELSTATE|// #define HAVE_PTHREAD_SETCANCELSTATE|" \
		-e "s|^#define HAVE_SOCKATMARK|// #define HAVE_SOCKATMARK|" \
		-i config.h

	for file in config.log config.h config.mk; do
		echo "INFO: ========== ${file} =========="
		cat "${file}"
		echo "INFO: ========== ${file} =========="
	done
}
