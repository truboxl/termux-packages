TERMUX_PKG_HOMEPAGE=https://ollama.com/
TERMUX_PKG_DESCRIPTION="Ollama fork with Vulkan backend"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux"
_COMMIT=3c22d5a6934c8d09dbf4118eef43bbf36d46c087
TERMUX_PKG_VERSION="0.5.1"
TERMUX_PKG_SRCURL=git+https://github.com/Dts0/ollama
TERMUX_PKG_GIT_BRANCH="vulkan"
TERMUX_PKG_DEPENDS="libc++, shaderc, vulkan-loader"
TERMUX_PKG_BUILD_DEPENDS="libcap, vulkan-headers, vulkan-loader-generic"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_AUTO_UPDATE=false
TERMUX_PKG_BLACKLISTED_ARCHES="arm, i686"
# error: install TARGETS RUNTIME_DEPENDENCIES is not supported when cross-compiling
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-DCMAKE_CROSSCOMPILING=OFF
"

termux_step_post_get_source() {
	git fetch --unshallow
	git checkout "${_COMMIT}"
}

termux_step_make() {
	termux_setup_golang

	export ARCH="$GOARCH"
	export VERSION="$TERMUX_PKG_VERSION"

	go build -trimpath -ldflags="-w -s -X=github.com/ollama/ollama/version.Version=$TERMUX_PKG_VERSION -X=github.com/ollama/ollama/server.mode=release"
}

termux_step_make_install() {
	install -Dm700 ollama $TERMUX_PREFIX/bin/ollama-vulkan
}
