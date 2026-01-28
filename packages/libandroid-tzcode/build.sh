TERMUX_PKG_HOMEPAGE=https://android.googlesource.com/platform/bionic/+/refs/heads/main/libc/tzcode/
TERMUX_PKG_DESCRIPTION="A shared library providing tzcode"
TERMUX_PKG_LICENSE="BSD 2-Clause, Public Domain"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="0.1"
TERMUX_PKG_DEPENDS="libc++"
TERMUX_PKG_SKIP_SRC_EXTRACT=true
TERMUX_PKG_AUTO_UPDATE=false

# https://android.googlesource.com/platform/bionic/+/main/libc/libc.map.txt
# https://android.googlesource.com/platform/bionic/+/main/docs/status.md#libc

termux_step_make() {
	${CC} ${CPPFLAGS} ${CFLAGS} \
		-I${TERMUX_PKG_BUILDER_DIR}/tzcode -c \
		${TERMUX_PKG_BUILDER_DIR}/tzcode/*.c
	${CXX} ${CPPFLAGS} ${CXXFLAGS} \
		-I${TERMUX_PKG_BUILDER_DIR} -I${TERMUX_PKG_BUILDER_DIR}/tzcode -c \
		${TERMUX_PKG_BUILDER_DIR}/tzcode/*.cpp
	${LD} ${LDFLAGS} -shared -o libandroid-tzcode.so *.o
	${AR} cru libandroid-tzcode.a *.o
	cp -f ${TERMUX_PKG_BUILDER_DIR}/LICENSE ${TERMUX_PKG_SRCDIR}/
}

termux_step_make_install() {
	install -Dm644 -t ${TERMUX_PREFIX}/lib libandroid-tzcode.{a,so}
}
