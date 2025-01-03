# shellcheck shell=bash disable=SC1091 disable=SC2086 disable=SC2155
termux_setup_dotnet() {
	export DOTNET_TARGET_NAME="linux-bionic"
	case "${TERMUX_ARCH}" in
	aarch64) DOTNET_TARGET_NAME+="-arm64" ;;
	arm) DOTNET_TARGET_NAME+="-arm" ;;
	i686) DOTNET_TARGET_NAME+="-x86" ;;
	x86_64) DOTNET_TARGET_NAME+="-x64" ;;
	esac

	if [[ "${TERMUX_ON_DEVICE_BUILD}" == "true" ]]; then
		if [[ -z "$(command -v dotnet)" ]]; then
			cat <<- EOL
			Package 'dotnet8.0' is not installed.
			You can install it with

			pkg install dotnet8.0

			pacman -S dotnet8.0
			EOL
			exit 1
		fi
		local RUSTC_VERSION=$(dotnet --version | awk '{ print $2 }')
		if [[ -n "${TERMUX_DOTNET_VERSION-}" && "${TERMUX_DOTNET_VERSION-}" != "${DOTNET_VERSION}" ]]; then
			cat <<- EOL >&2
			WARN: On device build with old dotnet version is not possible!
			TERMUX_DOTNET_VERSION = ${TERMUX_DOTNET_VERSION}
			DOTNET_VERSION       = ${DOTNET_VERSION}
			EOL
		fi
		return
	fi

	if [[ -z "${TERMUX_DOTNET_VERSION-}" ]]; then
		TERMUX_DOTNET_VERSION=$(. "${TERMUX_SCRIPTDIR}"/packages/dotnet8.0/build.sh; echo ${TERMUX_PKG_VERSION})
	fi
	if [[ "${TERMUX_DOTNET_VERSION}" == *"~beta"* ]]; then
		TERMUX_DOTNET_VERSION="beta"
	fi

	# https://github.com/dotnet/core/issues/9671
	curl https://raw.githubusercontent.com/dotnet/install-scripts/refs/heads/main/src/dotnet-install.sh -sSfo "${TERMUX_PKG_TMPDIR}"/dotnet-install.sh
	bash "${TERMUX_PKG_TMPDIR}"/dotnet-install.sh --version net9.0

	export PATH="${HOME}/.dotnet:${HOME}/.dotnet/tools:${PATH}"
}
