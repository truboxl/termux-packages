TERMUX_PKG_HOMEPAGE=https://termux.dev
TERMUX_PKG_DESCRIPTION="libdummy"
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=0.1
TERMUX_PKG_AUTO_UPDATE=false
TERMUX_PKG_SKIP_SRC_EXTRACT=true

termux_step_make_install() {
	mkdir -p "${TERMUX_PREFIX}/lib/dummy"
	for i in {0..5}; do
	"${CC}" "${TERMUX_PKG_BUILDER_DIR}/dummy.c" -shared -o "${TERMUX_PREFIX}/lib/dummy/libdummy-${i}.so"
	"${CC}" "${TERMUX_PKG_BUILDER_DIR}/dummy.c" -shared -o "${TERMUX_PREFIX}/lib/dummy/libdummy-weak-${i}.so" -D__WEAK__
	"${CC}" "${TERMUX_PKG_BUILDER_DIR}/dummy.c" -shared -o "${TERMUX_PREFIX}/lib/dummy/libdummy-void-${i}.so" -D__VOID__
	done
}
