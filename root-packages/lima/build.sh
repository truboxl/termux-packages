TERMUX_PKG_HOMEPAGE=https://lima-vm.io
TERMUX_PKG_DESCRIPTION="Linux virtual machines, with a focus on running containers"
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="2.0.2"
TERMUX_PKG_SRCURL=git+https://github.com/lima-vm/lima
TERMUX_PKG_GIT_BRANCH="v${TERMUX_PKG_VERSION}"
TERMUX_PKG_DEPENDS="docker, openssh, qemu-utils"
TERMUX_PKG_ANTI_BUILD_DEPENDS="docker, openssh, qemu-utils"
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_EXCLUDED_ARCHES="arm, i686"

termux_step_pre_configure() {
	termux_setup_golang

	TERMUX_PKG_RECOMMENDS="qemu-system-${TERMUX_ARCH//_/-}-headless | qemu-system-${TERMUX_ARCH//_/-}"
}
