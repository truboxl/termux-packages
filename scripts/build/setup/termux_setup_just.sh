# shellcheck shell=bash disable=SC2155
termux_setup_just() {
	local TERMUX_JUST_VERSION=1.33.0

	local JUST_TGZ_SHA256
	case "${TERMUX_JUST_VERSION}" in
	1.33.0) JUST_TGZ_SHA256=7e6480ee1c1b1c906f7f1933cc1a1b9f281812341f997b78dcd166430f5ea500 ;;
	*) termux_error_exit "Please add ${TERMUX_JUST_VERSION} archive checksum to termux_setup_just" ;;
	esac

	local JUST_TGZ_URL=https://github.com/casey/just/releases/download/${TERMUX_JUST_VERSION}/just-${TERMUX_JUST_VERSION}-x86_64-unknown-linux-musl.tar.gz
	local JUST_TGZ_FILE=${TERMUX_PKG_TMPDIR}/just-${TERMUX_JUST_VERSION}.tar.gz
	local JUST_FOLDER=${TERMUX_COMMON_CACHEDIR}/just-${TERMUX_JUST_VERSION}
	if [[ "${TERMUX_PACKAGES_OFFLINE-false}" == "true" ]]; then
		JUST_FOLDER=${TERMUX_SCRIPTDIR}/build-tools/just-${TERMUX_JUST_VERSION}
	fi

	if [[ "${TERMUX_ON_DEVICE_BUILD}" == "true" ]]; then
		if [[ -z "$(command -v just)" ]]; then
			cat <<- EOL
			Package 'just' is not installed.
			You can install it with

			pkg install just
			EOL
			exit 1
		fi
		return
	fi

	if [[ ! -x "${JUST_FOLDER}/just" ]]; then
		mkdir -p "${JUST_FOLDER}"
		termux_download "${JUST_TGZ_URL}" "${JUST_TGZ_FILE}" "${JUST_TGZ_SHA256}"
		tar -xf "${JUST_TGZ_FILE}" -C "${JUST_FOLDER}"
	fi

	export PATH="${JUST_FOLDER}:${PATH}"
	if [[ -z "$(command -v just)" ]]; then
		termux_error_exit "termux_setup_just: No just executable found!"
	fi
}
