TERMUX_PKG_HOMEPAGE=https://github.com/hrkfdn/ncspot
TERMUX_PKG_DESCRIPTION="An ncurses Spotify client written in Rust (with MPRIS support)"
TERMUX_PKG_LICENSE="BSD 2-Clause"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.1.2"
TERMUX_PKG_SRCURL=https://github.com/hrkfdn/ncspot/archive/v${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=010b12172b85e6ae0eaf60ae0ab923580bcca0b132927b39c2a2fc878cb5e6a7
TERMUX_PKG_DEPENDS="dbus, pulseaudio"
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_BUILD_IN_SRC=true

TERMUX_PKG_CONFLICTS="ncspot"

TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
--no-default-features
--features termion_backend,pulseaudio_backend,mpris,notify
"
# NOTE: ncurses-rs runs a test while building which fails while cross compiling:
# therefore, we use termion_backend instead.
# share_clipboard cannot be used due to 1Password/arboard#56.
