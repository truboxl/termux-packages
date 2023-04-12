TERMUX_PKG_HOMEPAGE=https://sr.ht/~kennylevinsen/seatd/
TERMUX_PKG_DESCRIPTION="Seat management daemon and library"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=0.7.0
TERMUX_PKG_SRCURL=https://git.sr.ht/~kennylevinsen/seatd/archive/${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=210ddf8efa1149cde4dd35908bef8e9e63c2edaa0cdb5435f2e6db277fafff3c
TERMUX_PKG_NO_STATIC_SPLIT=true
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-Ddefaultpath=${TERMUX_PREFIX}/var/run/seatd.socket
"
