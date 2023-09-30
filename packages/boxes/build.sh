TERMUX_PKG_HOMEPAGE=https://boxes.thomasjensen.com/
TERMUX_PKG_DESCRIPTION="A command line filter program which draws ASCII art boxes around your input text"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=2.2.1
TERMUX_PKG_SRCURL=https://github.com/ascii-boxes/boxes/archive/v${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=c57287e0d482fc85bbceecaf96ff8049600ff6541aaeb33aae36ac86f01ad1e0
TERMUX_PKG_DEPENDS="libunistring, pcre2"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_CONFFILES="
share/boxes/boxes-config
"

termux_step_make() {
	make -j $TERMUX_MAKE_PROCESSES \
		CC="$CC" \
		CFLAGS_ADDTL="$CFLAGS $CPPFLAGS" \
		LDFLAGS_ADDTL="$LDFLAGS"
}

termux_step_make_install() {
	install -Dm700 -t $TERMUX_PREFIX/bin out/boxes
	install -Dm600 -t $TERMUX_PREFIX/share/man/man1 doc/boxes.1
	install -Dm600 -t $TERMUX_PREFIX/share/boxes boxes-config
}
