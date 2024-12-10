TERMUX_PKG_HOMEPAGE=https://mega.io/
TERMUX_PKG_DESCRIPTION="Provides non UI access to MEGA services"
TERMUX_PKG_LICENSE="BSD 2-Clause"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.7.0"
TERMUX_PKG_REVISION=4
TERMUX_PKG_SRCURL=git+https://github.com/meganz/MEGAcmd
TERMUX_PKG_GIT_BRANCH=${TERMUX_PKG_VERSION}_Linux
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_UPDATE_VERSION_REGEXP="\d+\.\d+\.\d+"
# dbus is required for $PREFIX/var/lib/dbus/machine-id
TERMUX_PKG_DEPENDS="c-ares, cryptopp, dbus, ffmpeg, freeimage, libandroid-glob, libc++, libcurl, libicu, libsodium, libsqlite, libuv, mediainfo, openssl, pcre, readline, zlib"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
--disable-static
--with-pcre=$TERMUX_PREFIX
--with-ffmpeg=$TERMUX_PREFIX
ac_cv_lib_pthread_pthread_create=yes
"

termux_step_post_get_source() {
	# We use `config.h` generated by configure script instead of this one.
	local f="sdk/include/mega/config-android.h"
	if [ -f "${f}" ]; then
		rm -f "${f}"
		echo '#error DO NOT INCLUDE ME!' > "${f}"
	else
		termux_error_exit "Source file '${f}' not found."
	fi
}

termux_step_pre_configure() {
	autoreconf -fi

	export OBJCXX="$CXX"

	LDFLAGS+=" -landroid-glob"
	LDFLAGS+=" $($CC -print-libgcc-file-name)"

	# Fix build against FFmpeg 6.0:
	CPPFLAGS+=" -DCODEC_CAP_TRUNCATED=0"
}

termux_step_post_massage() {
	find lib -name '*.la' -delete
}
