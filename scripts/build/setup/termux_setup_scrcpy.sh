termux_setup_scrcpy() {
	local TERMUX_SCRCPY_VERSION=3.1
	local TERMUX_SCRCPY_SHA256=37dba54092ed9ec6b2f8f95432f61b8ea124aec9f1e9f2b3d22d4b10bb04c59a
	local TERMUX_SCRCPY_TARNAME="scrcpy-linux-x86_64-v${TERMUX_SCRCPY_VERSION}.tar.gz"
	local TERMUX_SCRCPY_URL="https://github.com/Genymobile/scrcpy/releases/download/v${TERMUX_SCRCPY_VERSION}/${TERMUX_SCRCPY_TARNAME}"
	local TERMUX_SCRCPY_TARFILE="${TERMUX_PKG_TMPDIR}/${TERMUX_SCRCPY_TARNAME}"
	local TERMUX_SCRCPY_FOLDER="${TERMUX_COMMON_CACHEDIR}/scrcpy-${TERMUX_SCRCPY_VERSION}"
	if [ "${TERMUX_PACKAGES_OFFLINE-false}" = "true" ]; then
		TERMUX_SCRCPY_FOLDER="${TERMUX_SCRIPTDIR}/build-tools/scrcpy-${TERMUX_SCRCPY_VERSION}"
	fi

	if [ "${TERMUX_ON_DEVICE_BUILD}" = "true" ]; then
		if [[ -z "$(command -v scrcpy)" ]]; then
			echo "Package 'scrcpy' is not installed."
			echo "You can install it with"
			echo
			echo "  pkg install x11-repo"
			echo "  pkg install scrcpy"
			echo
			exit 1
		fi
		return
	fi

	if [ ! -d "${TERMUX_SCRCPY_FOLDER}" ]; then
		termux_download "${TERMUX_SCRCPY_URL}" \
			"${TERMUX_SCRCPY_TARFILE}" \
			"${TERMUX_SCRCPY_SHA256}"
		rm -fr "${TERMUX_SCRCPY_FOLDER}"
		mkdir -p "${TERMUX_SCRCPY_FOLDER}"
		tar -xf "${TERMUX_SCRCPY_TARFILE}" -C "${TERMUX_SCRCPY_FOLDER}" --strip-components=1
	fi

	export PATH="${TERMUX_SCRCPY_FOLDER}:${PATH}"
}
