TERMUX_PKG_HOMEPAGE=https://rnote.flxzt.net/
TERMUX_PKG_DESCRIPTION="Open-source vector-based drawing app"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="0.11.0"
TERMUX_PKG_SRCURL=https://github.com/flxzt/rnote/releases/download/v${TERMUX_PKG_VERSION}/rnote-${TERMUX_PKG_VERSION}.tar.xz
TERMUX_PKG_SHA256=567d30523ef672a18ca33b16442af7b4a93910b47f416d09968dbc0e1d689cc3
TERMUX_PKG_DEPENDS="appstream, gettext, glib, gtk4, libadwaita, libcairo, poppler"
TERMUX_PKG_AUTO_UPDATE=true

termux_step_pre_configure() {
	termux_setup_cmake
	termux_setup_rust

	export CFLAGS=""
	export GETTEXT_DIR=${TERMUX_PREFIX}
	export GETTEXT_BIN_DIR=${TERMUX_PREFIX}/bin
	export GETTEXT_LIB_DIR=${TERMUX_PREFIX}/lib
	export GETTEXT_INCLUDE_DIR=${TERMUX_PREFIX}/include

	# remove rodio -> cpal -> alsa
	# dependencies that cannot be built or missing
	pushd crates/rnote-engine
	cargo remove rodio
	popd

	local p="${TERMUX_PKG_BUILDER_DIR}/0001-meson.build.diff"
	echo "Applying patch: $(basename "${p}")"
	sed "s|@CARGO_TARGET_NAME@|${CARGO_TARGET_NAME}|" "${p}" \
		| patch --silent -p1
}
