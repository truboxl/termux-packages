TERMUX_PKG_HOMEPAGE=https://crosvm.dev/book/
TERMUX_PKG_DESCRIPTION="ChromeOS Virtual Machine Monitor (AOSP)"
TERMUX_PKG_LICENSE="BSD 3-Clause"
TERMUX_PKG_MAINTAINER="@termux"
_COMMIT=ef97559e74d91b83c636895da46bf9d4fba80f07
_COMMIT_DATE=20260508
_COMMIT_TIME=184306
TERMUX_PKG_VERSION="0.1.0.20260508.184306"
TERMUX_PKG_DEPENDS="libandroid-fexecve, libandroid-shmem, libcap"
TERMUX_PKG_AUTO_UPDATE=false
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_SKIP_SRC_EXTRACT=true

# missing arch specific policies in jail/seccomp
TERMUX_PKG_EXCLUDED_ARCHES="arm, i686"

termux_step_post_get_source() {
	curl -o ${TERMUX_PKG_TMPDIR}/repo https://storage.googleapis.com/git-repo-downloads/repo
	gpg --recv-keys 8BB9AD793E8E6153AF0F9A4416530D5E920F5C65
	curl -s https://storage.googleapis.com/git-repo-downloads/repo.asc | gpg --verify - ${TERMUX_PKG_TMPDIR}/repo && chmod 755 ${TERMUX_PKG_TMPDIR}/repo && export PATH+=":${TERMUX_PKG_TMPDIR}"
	repo init --partial-clone --no-use-superproject -b android-latest-release -u https://android.googlesource.com/platform/manifest
	repo sync -c -j${TERMUX_PKG_MAKE_PROCESSES}
}

termux_step_pre_configure() {
	termux_setup_rust
}

termux_step_make() {
	local env_host=$(printf ${CARGO_TARGET_NAME} | tr a-z A-Z | sed s/-/_/g)
	export CARGO_TARGET_${env_host}_RUSTFLAGS="-L${TERMUX_PKG_BUILDDIR} -L${TERMUX_PREFIX}/lib"
	export CARGO_TARGET_${env_host}_RUSTFLAGS+=" -C link-arg=-Wl,-rpath=${TERMUX_PREFIX}/lib"
	export CARGO_TARGET_${env_host}_RUSTFLAGS+=" -C link-arg=-Wl,--enable-new-dtags"
	export CARGO_TARGET_${env_host}_RUSTFLAGS+=" -C link-arg=-Wl,--as-needed"

	"${CC}" ${CPPFLAGS} ${CFLAGS} -c "${TERMUX_PKG_BUILDER_DIR}/mlock2.c"
	"${AR}" rcu "${TERMUX_PKG_BUILDDIR}/libmlock2.a" mlock2.o
	export CARGO_TARGET_${env_host}_RUSTFLAGS+=" -C link-arg=-l:libmlock2.a"

	export CARGO_TARGET_${env_host}_RUSTFLAGS+=" -C link-arg=-landroid-fexecve"
	export LDFLAGS+=" -landroid-fexecve"

	local extra_opt="--release"
	[[ "${TERMUX_DEBUG_BUILD}" == "true" ]] && extra_opt=""

	cargo build \
		--jobs "${TERMUX_PKG_MAKE_PROCESSES}" \
		--target "${CARGO_TARGET_NAME}" \
		--features geniezone,gunyah,halla,gpu,x,virgl_renderer \
		${extra_opt}
}

termux_step_make_install() {
	local profile="release"
	[[ "${TERMUX_DEBUG_BUILD}" == "true" ]] && profile="debug"

	echo "INFO: READELF = ${READELF} ... $(command -v ${READELF})"
	local crosvm_readelf=$(${READELF} -d target/${CARGO_TARGET_NAME}/${profile}/crosvm)
	local crosvm_runpath=$(echo "${crosvm_readelf}" | sed -ne "s|.*RUNPATH.*\[\(.*\)\].*|\1|p")
	if [[ "${crosvm_runpath}" != "${TERMUX_PREFIX}/lib" ]]; then
		termux_error_exit "
		Unexpected RUNPATH found. Check readelf output below:
		${crosvm_readelf}
		"
	fi

	install -Dm700 -t "${TERMUX_PREFIX}/bin" \
		"target/${CARGO_TARGET_NAME}/${profile}/crosvm"
}
