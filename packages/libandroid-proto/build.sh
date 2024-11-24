TERMUX_PKG_HOMEPAGE=https://man7.org/linux/man-pages/man5/protocols.5.html
TERMUX_PKG_DESCRIPTION="Shared library for replacing stub Bionic protocol entry"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=0.1
TERMUX_PKG_SKIP_SRC_EXTRACT=true
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_AUTO_UPDATE=false

termux_step_make() {
	$CC $CPPFLAGS $CFLAGS -c $TERMUX_PKG_BUILDER_DIR/proto.c
	$CC $LDFLAGS -shared proto.o -o libandroid-proto.so
	$AR rcu libandroid-proto.a proto.o
	cp -f $TERMUX_PKG_BUILDER_DIR/LICENSE $TERMUX_PKG_SRCDIR/
}

termux_step_make_install() {
	install -Dm600 -t $TERMUX_PREFIX/lib \
		libandroid-proto.a libandroid-proto.so
}
