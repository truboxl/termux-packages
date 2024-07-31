TERMUX_PKG_HOMEPAGE=https://github.com/pop-os/cosmic-epoch
TERMUX_PKG_DESCRIPTION="Next generation Cosmic desktop environment"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=0.0
TERMUX_PKG_SRCURL=git+https://github.com/pop-os/cosmic-epoch
TERMUX_PKG_GIT_BRANCH=master
TERMUX_PKG_DEPENDS="dbus, libseat, libudev-zero, libxkbcommon, pulseaudio"
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_pre_configure() {
	# dgettext
	${CC} ${CPPFLAGS} -c ${TERMUX_PKG_BUILDER_DIR}/libintl.c
	${AR} rcu libintl.a libintl.o

	# shm_open
	sed -e "s|@TERMUX_PREFIX@|${TERMUX_PREFIX}|g" ${TERMUX_PKG_BUILDER_DIR}/posix-shmem.c > posix-shmem.c
	${CC} ${CPPFLAGS} -c posix-shmem.c
	${AR} rcu libposix-shmem.a posix-shmem.o

	export RUSTFLAGS+=" -L${TERMUX_PKG_BUILDDIR} -C link-arg=-l:libintl.a -C link-arg=-l:libposix-shmem.a"

	# skip building in gettext-sys
	export GETTEXT_SYSTEM=1

	termux_setup_just
	termux_setup_rust

	: "${CARGO_HOME:=${HOME}/.cargo}"
	export CARGO_HOME

	local components=$(find . -maxdepth 2 -type f -name Cargo.toml -exec dirname "{}" \; | sort)
	local component
	for component in ${components}; do
		pushd "$component"
		if [[ "$(basename $component)" == "cosmic-bg" ]]; then
			git checkout master
			git fetch --unshallow
			git reset --hard origin/master
		fi
		rm -fv Cargo.lock
		rm -fv rust-toolchain{,.toml}
		cargo fetch --target ${CARGO_TARGET_NAME}
		popd
	done

	_patch_crate
}

_patch_crate() {
	local rustix
	for rustix in ${CARGO_HOME}/registry/src/*/rustix-*; do
		[[ "$(basename $rustix)" == "rustix-0.37."* ]] && continue
		[[ "$(basename $rustix)" == "rustix-openpty-"* ]] && continue
		echo "In $rustix"
		echo "$(patch -p1 -i ${TERMUX_PKG_BUILDER_DIR}/rustix.diff -d $rustix)"
	done
	local libc
	for libc in ${CARGO_HOME}/registry/src/*/libc-*; do
		echo "In $libc"
		echo "$(patch -p1 -i ${TERMUX_PKG_BUILDER_DIR}/libc.diff -d $libc)"
	done
	local softbuffer
	for softbuffer in ${CARGO_HOME}/git/checkouts/softbuffer-*/*; do
		echo "In $softbuffer"
		echo "$(patch -p1 -i ${TERMUX_PKG_BUILDER_DIR}/softbuffer.diff -d $softbuffer)"
	done
	local gettext_sys
	for gettext_sys in ${CARGO_HOME}/registry/src/*/gettext-sys-*; do
		echo "In $gettext_sys"
		echo "$(patch -p1 -i ${TERMUX_PKG_BUILDER_DIR}/gettext-sys.diff -d $gettext_sys)"
	done
	local libcosmic
	for libcosmic in ${CARGO_HOME}/git/checkouts/libcosmic-*/*; do
		echo "In $libcosmic"
		echo "$(patch -p1 -i ${TERMUX_PKG_BUILDER_DIR}/libcosmic.diff -d $libcosmic)"
	done
	local input_sys
	for input_sys in ${CARGO_HOME}/registry/src/*/input-sys-*; do
		echo "In $input_sys"
		echo "$(patch -p1 -i ${TERMUX_PKG_BUILDER_DIR}/input-sys.diff -d $input_sys)"
	done
	local current_locale
	for current_locale in ${CARGO_HOME}/registry/src/*/current_locale-*; do
		echo "In $current_locale"
		echo "$(patch -p1 -i ${TERMUX_PKG_BUILDER_DIR}/current_locale.diff -d $current_locale)"
	done
	local winit
	for winit in ${CARGO_HOME}/registry/src/*/winit-* ${CARGO_HOME}/git/checkouts/winit-*/*; do
		[[ ! -d "$winit" ]] && continue
		echo "In $winit"
		echo "$(patch -p1 -i ${TERMUX_PKG_BUILDER_DIR}/winit.diff -d $winit)"
	done
	local smithay
	for smithay in ${CARGO_HOME}/git/checkouts/smithay-*/*; do
		echo "In $smithay"
		echo "$(patch -p1 -i ${TERMUX_PKG_BUILDER_DIR}/smithay.diff -d $smithay)"
	done

	local justfiles=$(find . -type f -name "justfile" | sort)
	local justfile
	for justfile in ${justfiles}; do
		echo "$justfile"
		sed \
			-e "s|/usr/local|${TERMUX_PREFIX}|g" \
			-e "s|/usr|${TERMUX_PREFIX}|g" \
			-e "s|cargo build|rustup target add ${CARGO_TARGET_NAME}; cargo build --target ${CARGO_TARGET_NAME}|g" \
			-i "$justfile"
	done
	local makefiles=$(find . -type f -name "Makefile" | sort)
	local makefile
	for makefile in ${makefiles}; do
		echo "$makefile"
		sed \
			-e "s|/usr/local|${TERMUX_PREFIX}|g" \
			-e "s|/usr|${TERMUX_PREFIX}|g" \
			-e "s|/etc|${TERMUX_PREFIX}/etc|g" \
			-e "s|cargo build|rustup target add ${CARGO_TARGET_NAME}; cargo build --target ${CARGO_TARGET_NAME}|g" \
			-i "$makefile"
	done
}

termux_step_make() {
	just build
}

termux_step_make_install() {
	just install
}
