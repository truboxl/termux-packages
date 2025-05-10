#!/bin/sh
# shellcheck disable=SC2046

# This script clears about ~22G of space. It also sets up a swapfile to account
# for packages requiring large memory.

# Test:
# echo "Listing 100 largest packages after"
# dpkg-query -Wf '${Installed-Size}\t${Package}\n' | sort -n | tail -n 100
# exit 0

create_swapfile() {
	sudo fallocate -l 4G /swapfile
	sudo chmod 600 /swapfile
	sudo mkswap /swapfile
	sudo swapon /swapfile
}

# https://github.com/actions/runner-images/issues/709#issuecomment-612569242
list_directory() {
	echo "
	/opt/ghc
	/opt/hostedtoolcache
	/usr/share/dotnet
	/usr/share/swift
	/usr/local/graalvm/
	/usr/local/.ghcup/
	/usr/local/share/powershell
	/usr/local/share/chromium
	/usr/local/lib/node_modules
	/usr/local/share/boost
	$AGENT_TOOLSDIRECTORY
	"
	#/usr/local/lib/android
}

list_package() {
	echo "
	$(test "${CLEAN_DOCKER_IMAGES-true}" = "true" && echo "containerd.io")
	$(dpkg -l |
		grep '^ii' |
		awk '{ print $2 }' |
		grep -P '(mecab|linux-azure-tools-|aspnetcore|liblldb-|netstandard-|clang-tidy|clang-format|gfortran-|mysql-|google-cloud-cli|postgresql-|cabal-|dotnet-|ghc-|mongodb-|libmono|llvm-16|llvm-17)'
	)
	snapd
	kubectl
	podman
	ruby3.2-doc
	mercurial-common
	git-lfs
	skopeo
	buildah
	vim
	python3-botocore
	azure-cli
	powershell
	shellcheck
	firefox
	google-chrome-stable
	microsoft-edge-stable
	"
}

if [ "${CI-false}" != "true" ]; then
	echo "ERROR: not running on CI, not deleting system files to free space!"
	exit 1
fi

create_swapfile

sudo rm -fr $(list_directory)

# We shouldn't remove docker & it's images when running from `package_updates` workflow.
if [ "${CLEAN_DOCKER_IMAGES-true}" = "true" ]; then
	sudo docker image prune --all --force
	sudo docker builder prune -a
fi

sudo apt purge -yq $(list_package)
sudo apt autoremove -yq
sudo apt clean
