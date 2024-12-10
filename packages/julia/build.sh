TERMUX_PKG_HOMEPAGE=https://julialang.org/
TERMUX_PKG_DESCRIPTION="The Julia Programming Language"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.11.2"
TERMUX_PKG_SRCURL=https://github.com/JuliaLang/julia/releases/download/v${TERMUX_PKG_VERSION}/julia-${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=5d56c7163aefbf4dfb97d97388f93175826bcc3f4b0e885fa351694f84dc70c4
TERMUX_PKG_DEPENDS="libc++"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_EXTRA_MAKE_ARGS=""

termux_step_pre_configure() {
	export XCHOST=${TERMUX_ARCH}-linux-android
	LDFLAGS+=" -Wl,--undefined-version"
}
