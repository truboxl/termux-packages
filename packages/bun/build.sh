TERMUX_PKG_HOMEPAGE=https://bun.sh/
TERMUX_PKG_DESCRIPTION="JavaScript runtime, bundler, test runner, and package manager"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.3.9"
TERMUX_PKG_SRCURL=git+https://github.com/oven-sh/bun
TERMUX_PKG_GIT_BRANCH="bun-v${TERMUX_PKG_VERSION}"
TERMUX_PKG_HOSTBUILD=true
TERMUX_PKG_ON_DEVICE_BUILD_NOT_SUPPORTED=true

termux_step_host_build() {
	# we are not using NDK to build bun
	termux_setup_cmake
	termux_setup_ninja
	termux_setup_rust
	termux_setup_zig

	if [[ "${TERMUX_ON_DEVICE_BUILD}" == "false" ]]; then
		curl -fsSL https://bun.sh/install | bash
		export PATH="${HOME}/.bun/bin:${PATH}"
		command -v bun
		command -v clang
	fi

	bun run --cwd=${TERMUX_PKG_SRCDIR} scripts/glob-sources.mjs

	cmake \
		-G Ninja \
		-S "${TERMUX_PKG_SRCDIR}" \
		-DCMAKE_BUILD_TYPE=Release \
		-DLLVM_VERSION=ignore
	ninja \
		-j ${TERMUX_PKG_MAKE_PROCESSES}

	ls -l
	mkdir -p ${TERMUX_PREFIX}/opt/bun
	cp -fr ${TERMUX_PKG_HOSTBUILD_DIR} ${TERMUX_PREFIX}/opt/bun
}

termux_step_configure() {
	:
}

termux_step_make() {
	:
}

termux_step_make_install() {
	:
}
