TERMUX_PKG_HOMEPAGE=https://www.gnu.org/software/parallel/
TERMUX_PKG_DESCRIPTION="GNU Parallel is a shell tool for executing jobs in parallel using one or more machines"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=20230822
TERMUX_PKG_REVISION=1
TERMUX_PKG_SRCURL=https://mirrors.kernel.org/gnu/parallel/parallel-${TERMUX_PKG_VERSION}.tar.bz2
TERMUX_PKG_SHA256=4b594599a3c113c2952d6b0c1b7ce54460098ea215ac5f6851201f99ee6bfc5e
TERMUX_PKG_DEPENDS="perl"
TERMUX_PKG_PLATFORM_INDEPENDENT=true
TERMUX_PKG_AUTO_UPDATE=true

termux_pkg_auto_update() {
	local api_url="https://mirrors.kernel.org/gnu/parallel"
	local api_url_r=$(curl -s "${api_url}/")
	if [[ -z "${api_url_r}" ]]; then
		echo "WARN: No response from ${api_url}/" >&2
		return
	fi

	local r1=$(echo "${api_url_r}" | sed -nE 's|<.*>parallel-(.*).tar.bz2<.*>.*|\1|p')
	if [[ -z "${r1}" ]]; then
		cat <<- EOL >&2
		WARN: No matching regex. Printing URL response:
		${api_url_r}
		EOL
		return
	fi

	local latest_version=$(echo "${r1}" | sed -nE 's|([0-9]+)|\1|p' | tail -n1)
	if [[ -z "${latest_version}" ]]; then
		cat <<- EOL >&2
		WARN: No matching regex. Printing past regex result:
		${r1}
		EOL
		return
	fi
	if [[ "${latest_version}" == "${TERMUX_PKG_VERSION}" ]]; then
		echo "INFO: No update needed. Already at version '${TERMUX_PKG_VERSION}'."
		return
	fi

	local latest_tbz="${api_url}/parallel-latest.tar.bz2"
	local tmpdir=$(mktemp -d)
	curl -so "${tmpdir}/parallel-latest.tar.bz2" "${latest_tbz}"
	tar -xf "${tmpdir}/parallel-latest.tar.bz2" -C "${tmpdir}"
	if [[ ! -d "${tmpdir}/parallel-${latest_version}" ]]; then
		termux_error_exit "
		ERROR: Latest archive does not contain latest version
		$(ls -l "${tmpdir}")
		"
	fi

	rm -fr "${tmpdir}"

	termux_pkg_upgrade_version "${latest_version}"
}

termux_step_post_make_install() {
	install -Dm644 /dev/null "${TERMUX_PREFIX}"/share/bash-completion/completions/parallel

	mkdir -p "${TERMUX_PREFIX}"/share/zsh/site-functions
	cat <<- EOF > "${TERMUX_PREFIX}"/share/zsh/site-functions/_parallel
	#compdef parallel
	(( $+functions[_comp_parallel] )) ||
	eval "\$(parallel --shell-completion auto)" &&
	comp_parallel
	EOF
}

termux_step_create_debscripts() {
	cat <<- EOF > postinst
	#!${TERMUX_PREFIX}/bin/sh
	parallel --shell-completion bash > ${TERMUX_PREFIX}/share/bash-completion/completions/parallel
	EOF
}
