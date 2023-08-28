TERMUX_PKG_HOMEPAGE=https://github.com/dotnet
TERMUX_PKG_DESCRIPTION=".NET 7"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=7.0.110
TERMUX_PKG_SRCURL=git+https://github.com/dotnet/installer
TERMUX_PKG_GIT_BRANCH=v${TERMUX_PKG_VERSION}
TERMUX_PKG_DEPENDS="krb5, libandroid-glob, libicu, liblzma, openssl, zlib"

# TODO need backport patches
TERMUX_PKG_BLACKLISTED_ARCHES="x86_64"

termux_step_post_get_source() {
	# https://github.com/dotnet/installer/issues/12185
	# must rely git clone and not possible to use release tarball

	if [[ -f "${TERMUX_PKG_CACHEDIR}/src.tar" ]]; then
		rm -fr "${TERMUX_PKG_BUILDDIR}"
		mkdir -p "${TERMUX_PKG_BUILDDIR}"
		tar -C "${TERMUX_PKG_BUILDDIR}" -xvf "${TERMUX_PKG_CACHEDIR}/src.tar"
	else
		DotNetBuildFromSource=true ./build.sh \
			/p:ArcadeBuildTarball=true \
			/p:TarballDir=${TERMUX_PKG_BUILDDIR} \
			/p:TarballFilePath=${TERMUX_PKG_CACHEDIR}/src.tar
	fi

	pushd "${TERMUX_PKG_BUILDDIR}"
	./prep.sh --bootstrap
	popd
}

termux_step_pre_configure() {
	#return
	termux_setup_cmake
	termux_setup_ninja
}

termux_step_configure() {
	#return
	local arch
	case "${TERMUX_ARCH}" in
	aarch64) arch=arm64 ;;
	arm) arch=arm ;;
	i686) arch=x86 ;;
	x86_64) arch=x64 ;;
	*) termux_error_exit "Unknown arch: ${TERMUX_ARCH}" ;;
	esac

	export ANDROID_NDK_ROOT="${TERMUX_PKG_TMPDIR}"

	# unified sysroot needed when CMAKE_SYSROOT / --sysroot cannot be used
	export ROOTFS_DIR="${TERMUX_PKG_TMPDIR}/sysroot"
	rm -fr "${ROOTFS_DIR}"
	echo "Copying ${TERMUX_STANDALONE_TOOLCHAIN}/sysroot to ${ROOTFS_DIR} ..."
	time cp -fr "${TERMUX_STANDALONE_TOOLCHAIN}/sysroot" "${ROOTFS_DIR}"
	echo "Copying ${TERMUX_PREFIX} to ${ROOTFS_DIR} ..."
	time cp -fr "${TERMUX_PREFIX}" "${ROOTFS_DIR}"
	mv -v "${TERMUX_STANDALONE_TOOLCHAIN}"/sysroot{,.tmp}
	rm -fr "${TERMUX_STANDALONE_TOOLCHAIN}/sysroot.tmp"
	ln -sv "${ROOTFS_DIR}" "${TERMUX_STANDALONE_TOOLCHAIN}/sysroot"

	mkdir -p "${TERMUX_PKG_TMPDIR}/toolchains/llvm/prebuilt"
	ln -sv "${TERMUX_STANDALONE_TOOLCHAIN}" "${TERMUX_PKG_TMPDIR}/toolchains/llvm/prebuilt/linux-x86_64"

	echo "RID=android.${TERMUX_PKG_API_LEVEL}-${arch}" > "${ROOTFS_DIR}/android_platform"

	# manual termux_step_configure_cmake
	local CMAKE_PROC="${TERMUX_ARCH}"
	test "${CMAKE_PROC}" == "arm" && CMAKE_PROC="armv7-a"
	export CFLAGS+=" --target=$CCTERMUX_HOST_PLATFORM"
	export CXXFLAGS+=" --target=$CCTERMUX_HOST_PLATFORM"

	# easier to embed in toolchain file than CMakeArgs
	mkdir -p "${TERMUX_PKG_TMPDIR}/build/cmake"
	cat <<-EOL > "${TERMUX_PKG_TMPDIR}/build/cmake/android.toolchain.cmake"
	set(CMAKE_C_FLAGS "\${CMAKE_C_FLAGS} ${CFLAGS}")
	set(CMAKE_CXX_FLAGS "\${CMAKE_CXX_FLAGS} ${CXXFLAGS}")
	set(CMAKE_SYSROOT "${ROOTFS_DIR}")
	set(CMAKE_C_COMPILER "${TERMUX_STANDALONE_TOOLCHAIN}/bin/${CC}")
	set(CMAKE_CXX_COMPILER "${TERMUX_STANDALONE_TOOLCHAIN}/bin/${CXX}")
	set(CMAKE_AR "$(command -v ${AR})")
	set(CMAKE_UNAME "$(command -v uname)")
	set(CMAKE_RANLIB "$(command -v ${RANLIB})")
	set(CMAKE_STRIP "$(command -v ${STRIP})")
	set(CMAKE_FIND_ROOT_PATH "${TERMUX_PREFIX}")
	set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
	set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
	set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
	set(CMAKE_SKIP_INSTALL_RPATH ON)
	set(CMAKE_USE_SYSTEM_LIBRARIES True)
	set(CMAKE_CROSSCOMPILING True)
	set(CMAKE_LINKER "${TERMUX_STANDALONE_TOOLCHAIN}/bin/${LD}")
	set(CMAKE_SYSTEM_NAME Android)
	set(CMAKE_SYSTEM_VERSION "${TERMUX_PKG_API_LEVEL}")
	set(CMAKE_SYSTEM_PROCESSOR "${CMAKE_PROC}")
	set(CMAKE_ANDROID_STANDALONE_TOOLCHAIN "${TERMUX_STANDALONE_TOOLCHAIN}")
	EOL
	echo "===== android.toolchain.cmake ====="
	cat "${TERMUX_PKG_TMPDIR}/build/cmake/android.toolchain.cmake"
	echo "===== android.toolchain.cmake ====="

	export _EXTRA_ARGS=()
	if [[ "${TERMUX_DEBUG_BUILD}" == "true" ]]; then
		_EXTRA_ARGS+=("/p:Configuration=Debug")
	else
		_EXTRA_ARGS+=("/p:Configuration=Release")
	fi
	_EXTRA_ARGS+=("/p:CrossBuild=True")
	_EXTRA_ARGS+=("/p:TargetArchitecture=${arch}")
	# TODO hardcode for now
	_EXTRA_ARGS+=("/p:BuildArchitecture=x64")
	_EXTRA_ARGS+=("/p:TargetOS=Android")
	_EXTRA_ARGS+=("/p:CleanWhileBuilding=true")
	_EXTRA_ARGS+=("/p:BuildWithOnlineSources=true")

	export _CMAKE_ARGS=()
	_CMAKE_ARGS+=("-DFEATURE_EVENT_TRACE=0")
	_CMAKE_ARGS="${_CMAKE_ARGS// /%20}"
	_EXTRA_ARGS+=("/p:CMakeArgs=\"${_CMAKE_ARGS}\"")

	export EXTRA_CFLAGS="${CFLAGS}"
	export EXTRA_CXXFLAGS="${CXXFLAGS}"
	export EXTRA_LDFLAGS="${LDFLAGS}"

	# dotnet runtime cross compile has a stage of host build
	# mono cross tool which our toolchain setup will interfere
	mv -v "${TERMUX_STANDALONE_TOOLCHAIN}"/bin/pkg-config{,.tmp}
	rm -fr "${TERMUX_STANDALONE_TOOLCHAIN}"/bin/pkg-config.tmp
	ln -sv /usr/bin/pkg-config "${TERMUX_STANDALONE_TOOLCHAIN}/bin/pkg-config"

	unset PKG_CONFIG PKGCONFIG PKG_CONFIG_DIR PKG_CONFIG_LIBDIR CC CXX CFLAGS CXXFLAGS LDFLAGS
}

termux_step_make () {
	# this is to source build for build machine, do not use this
	#./build.sh --clean-while-building -- ${_EXTRA_ARGS[@]}
	#return

	local _packagesdir="${TERMUX_PKG_BUILDDIR}/local-packages"
	local _downloaddir="${TERMUX_PKG_BUILDDIR}/local-download"
	local _gitcommithash
	mkdir -p .dotnet "${_packagesdir}" "${_downloaddir}"
	ls -l src

	# working
	if ! :; then
	pushd src/runtime
	_gitcommithash=$(cat .git/HEAD)
	if [[ -z "${_gitcommithash}" ]]; then termux_error_exit "$PWD: GitCommitHash is empty!"; fi
	echo "GitCommitHash = ${_githash}"
	ln -sv ../../.dotnet .dotnet
	.dotnet/dotnet build-server shutdown
	#./eng/common/build.sh --restore --build --pack --warnAsError false ${_EXTRA_ARGS[@]}
	./eng/build.sh --help
	./eng/build.sh ${_EXTRA_ARGS[@]} /p:GitCommitHash=${_githash}
	for i in artifacts/packages/*/*/*.nupkg; do
		.dotnet/dotnet nuget push "$i" --source="${_packagesdir}"
	done
	local _runtimever_ns=$(
		grep VS.Redist.Common.NetCore.SharedFramework eng/Version.Details.xml | \
		sed -e "s|.*Version=\"\(.*\)\" .*|\1|" | \
		head -n1
	)
	mkdir -p "${_downloaddir}/Runtime/${_runtimever_ns}"
	find artifacts -name "*tar*" -type f
	cp -fv artifacts/packages/*/*/dotnet-runtime-*-*.tar.gz "${_downloaddir}/Runtime/${_runtimever_ns}"
	popd
	fi

	# not working
	if ! :; then
	pushd src/roslyn
	_gitcommithash=$(cat .git/HEAD)
	if [[ -z "${_gitcommithash}" ]]; then termux_error_exit "$PWD: GitCommitHash is empty!"; fi
	echo "GitCommitHash = ${_gitcommithash}"
	ln -sv ../../.dotnet .dotnet
	.dotnet/dotnet build-server shutdown
	#./eng/common/build.sh --restore --build --pack --warnAsError false ${_EXTRA_ARGS[@]}
	DotNetBuildFromSource=false ./eng/build.sh --restore
	./eng/build.sh --restore --build --pack /p:UseAppHost=false /p:GitCommitHash=${_gitcommithash}
	for i in artifacts/packages/*/*/*.nupkg; do
		.dotnet/dotnet nuget push "$i" --source="${_packagesdir}"
	done
	popd
	fi

	pushd src/sdk
	_gitcommithash=$(cat .git/HEAD)
	if [[ -z "${_gitcommithash}" ]]; then termux_error_exit "$PWD: GitCommitHash is empty!"; fi
	echo "GitCommitHash = ${_gitcommithash}"
	ln -sv ../../.dotnet .dotnet
	.dotnet/dotnet build-server shutdown
	./eng/common/build.sh --help
	./eng/common/build.sh --restore
	./eng/common/build.sh --restore --build --pack ${_EXTRA_ARGS[@]} /p:ArcadeBuildFromSource=true /p:GitCommitHash=${_gitcommithash}
	for i in artifacts/packages/*/*/*.nupkg; do
		.dotnet/dotnet nuget push "$i" --source="${_packagesdir}"
	done
	popd

	pushd src/aspnetcore
	_gitcommithash=$(cat .git/HEAD)
	if [[ -z "${_gitcommithash}" ]]; then termux_error_exit "$PWD: GitCommitHash is empty!"; fi
	echo "GitCommitHash = ${_gitcommithash}"
	ln -sv ../../.dotnet .dotnet
	.dotnet/dotnet build-server shutdown
	./eng/common/build.sh --help
	./eng/common/build.sh --restore
	./eng/common/build.sh --restore --build --pack ${_EXTRA_ARGS[@]} /p:GitCommitHash=${_gitcommithash}
	for i in artifacts/packages/*/*/*.nupkg; do
		.dotnet/dotnet nuget push "$i" --source="${_packagesdir}"
	done
	popd

	pushd src/installer
	_gitcommithash=$(cat .git/HEAD)
	if [[ -z "${_gitcommithash}" ]]; then termux_error_exit "$PWD: GitCommitHash is empty!"; fi
	echo "GitCommitHash = ${_gitcommithash}"
	ln -sv ../../.dotnet .dotnet
	.dotnet/dotnet build-server shutdown
	./eng/common/build.sh --help
	./eng/common/build.sh --restore
	./eng/common/build.sh --restore --build --pack ${_EXTRA_ARGS[@]} /p:GitCommitHash=${_gitcommithash}
	for i in artifacts/packages/*/*/*.nupkg; do
		.dotnet/dotnet nuget push "$i" --source="${_packagesdir}"
	done
	popd
}

termux_step_post_make_install() {
	mkdir -p "${TERMUX_PREFIX}/lib/dotnet"
	cp -fr "${TERMUX_PKG_BUILDDIR}/local-packages" "${TERMUX_PREFIX}/lib/dotnet/local-packages"
	cp -fr "${TERMUX_PKG_BUILDDIR}/local-downloads"  "${TERMUX_PREFIX}/lib/dotnet/local-downloads"
	#cp -fr "${TERMUX_PKG_BUILDDIR}" "${TERMUX_PREFIX}/lib/dotnet/builddir"
	#return
	#local bindirs=$(find ${TERMUX_PKG_BUILDDIR}/src -mindepth 3 -maxdepth 3 -name bin -type d | sort)
	#for bindir in ${bindirs}; do
	#	cp -frv "${bindir}" "${TERMUX_PREFIX}/lib/dotnet"
	#	rm -fr "${bindir}"
	#done
	find "${TERMUX_PREFIX}/lib/dotnet" -name Debug -type d -exec rm -frv "{}" \; || :
	find "${TERMUX_PREFIX}/lib/dotnet" -name cross -type d -exec rm -frv "{}" \; || :
	find "${TERMUX_PREFIX}/lib/dotnet" -name "*.dll" -type f -exec chmod -v -x "{}" \;
	find "${TERMUX_PREFIX}/lib/dotnet" -name "*.xml" -type f -exec chmod -v -x "{}" \;
	find "${TERMUX_PREFIX}/lib/dotnet" -name "*.so" -type f -exec chmod -v -x "{}" \;
	du -sh "${TERMUX_PREFIX}/lib/dotnet"
}

# https://learn.microsoft.com/en-us/dotnet/core/distribution-packaging
# https://github.com/dotnet/source-build
# https://git.alpinelinux.org/aports/tree/community/dotnet7-stage0/APKBUILD
# https://src.fedoraproject.org/rpms/dotnet7.0/blob/rawhide/f/dotnet7.0.spec
