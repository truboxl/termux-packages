TERMUX_PKG_HOMEPAGE=https://www.gnu.org/software/cpio/
TERMUX_PKG_DESCRIPTION="CPIO implementation from the GNU project"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="2.15"
TERMUX_PKG_REVISION=1
TERMUX_PKG_SRCURL=https://mirrors.kernel.org/gnu/cpio/cpio-$TERMUX_PKG_VERSION.tar.bz2
TERMUX_PKG_SHA256=937610b97c329a1ec9268553fb780037bcfff0dcffe9725ebc4fd9c1aa9075db
TERMUX_PKG_DEPENDS="tar"
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="--with-rmt=$TERMUX_PREFIX/libexec/rmt"

termux_step_post_get_source() {
	termux_download https://android.googlesource.com/platform/bionic/+archive/refs/heads/main/libc/tzcode.tar.gz tzcode.tar.gz SKIP_CHECKSUM
	mkdir -p ${TERMUX_PKG_SRCDIR}/tzcode
	tar -xf tzcode.tar.gz -C ${TERMUX_PKG_SRCDIR}/tzcode
}

termux_step_pre_configure() {
	pushd ${TERMUX_PKG_SRCDIR}/tzcode
	${CC} localtime.c -c
	${AR} rcu libtzcode.a *.o
	popd
	LDFLAGS+=" -L${TERMUX_PKG_SRCDIR}/tzcode -l:libtzcode.a"

	autoreconf -fi
}
