TERMUX_PKG_HOMEPAGE=https://dotnet.microsoft.com/en-us/
TERMUX_PKG_DESCRIPTION=".NET 9"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="9.0.101"
TERMUX_PKG_SRCURL=git+https://github.com/dotnet/dotnet
TERMUX_PKG_GIT_BRANCH=v${TERMUX_PKG_VERSION}
TERMUX_PKG_DEPENDS="libc++, openssl, zlib"
TERMUX_PKG_BUILD_DEPENDS="krb5"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_NO_STATICSPLIT=true
# https://github.com/dotnet/runtime/issues/7335
# linux-x86 is not officially supported
TERMUX_PKG_BLACKLISTED_ARCHES="i686"

termux_step_post_get_source() {
	# set up dotnet cli and override source files
	./prep-source-build.sh

	# removed by BinaryTool
	git restore src/runtime/src/installer/tests/Assets/Projects/AppWithUnknownLanguageResource/test.res
}

termux_step_pre_configure() {
	termux_setup_cmake
	termux_setup_ninja

	# aspnetcore needs nodejs <= 19, but nodejs 19.x is EOL
	local NODEJS_VERSION=18.20.5
	local NODEJS_SHA256=e4a3a21e5ac7e074ed50d2533dd0087d8460647ab567464867141a2b643f3fb3
	local NODEJS_FOLDER="${TERMUX_PKG_CACHEDIR}/nodejs-${NODEJS_VERSION}"
	local NODEJS_TAR_XZ="${TERMUX_PKG_CACHEDIR}/node.tar.xz"
	termux_download \
		https://nodejs.org/dist/v${NODEJS_VERSION}/node-v${NODEJS_VERSION}-linux-x64.tar.xz \
		"${NODEJS_TAR_XZ}" \
		"${NODEJS_SHA256}"
	mkdir -p "${NODEJS_FOLDER}"
	tar -xf "${NODEJS_TAR_XZ}" -C "${NODEJS_FOLDER}" --strip-components=1
	export PATH="${NODEJS_FOLDER}/bin:${PATH}"
	if [[ "$(node --version)" != "v${NODEJS_VERSION}" ]]; then
		termux_error_exit "$(command -v node) $(node --version) != ${NODEJS_VERSION}"
	fi

	export DOTNET_INSTALL_DIR="${TERMUX_PKG_SRCDIR}/.dotnet"
	export DotNetBuildFromSource=true
	export _downloaddir="${TERMUX_PKG_TMPDIR}/local-downloads"
	export _packagesdir="${TERMUX_PKG_TMPDIR}/local-packages"
	mkdir -p "${_downloaddir}" "${_packagesdir}"
}

termux_step_configure() {
	export arch
	case "${TERMUX_ARCH}" in
	aarch64) arch=arm64 ;;
	arm) arch=arm ;;
	i686) arch=x86 ;;
	x86_64) arch=x64 ;;
	*) termux_error_exit "Unknown arch: ${TERMUX_ARCH}"
	esac

	export ANDROID_NDK_ROOT="${TERMUX_PKG_TMPDIR}"

	# unified sysroot needed when CMAKE_SYSROOT / --sysroot cannot be used
	export ROOTFS_DIR="${TERMUX_PKG_TMPDIR}/sysroot"
	if [[ -e "${TERMUX_STANDALONE_TOOLCHAIN}/sysroot.tmp" ]]; then
		rm -f "${TERMUX_STANDALONE_TOOLCHAIN}/sysroot"
		mv -v "${TERMUX_STANDALONE_TOOLCHAIN}"/sysroot{.tmp,}
	fi
	rm -fr "${ROOTFS_DIR}"
	echo "INFO: Copying ${TERMUX_STANDALONE_TOOLCHAIN}/sysroot to ${ROOTFS_DIR}"
	cp -fr "${TERMUX_STANDALONE_TOOLCHAIN}/sysroot" "${ROOTFS_DIR}"
	echo "INFO: Copying ${TERMUX_PREFIX} to ${ROOTFS_DIR}"
	cp -fr "${TERMUX_PREFIX}" "${ROOTFS_DIR}"
	mv -v "${TERMUX_STANDALONE_TOOLCHAIN}"/sysroot{,.tmp}
	rm -fr "${TERMUX_STANDALONE_TOOLCHAIN}/sysroot.tmp"
	ln -sv "${ROOTFS_DIR}" "${TERMUX_STANDALONE_TOOLCHAIN}/sysroot"

	#echo "RID=android.${TERMUX_PKG_API_LEVEL}-${arch}" > "${ROOTFS_DIR}/android_platform"

	# manual termux_step_configure_cmake
	CMAKE_PROC="${TERMUX_ARCH}"
	[[ "${CMAKE_PROC}" == "arm" ]] && CMAKE_PROC="armv7-a"
	export CFLAGS+=" --target=${CCTERMUX_HOST_PLATFORM} -v"
	export CXXFLAGS+=" --target=${CCTERMUX_HOST_PLATFORM} -v"

	# easier to embed in toolchain file than CMakeArgs
	mkdir -p "${TERMUX_PKG_TMPDIR}/build/cmake"
	cat <<- EOL > "${TERMUX_PKG_TMPDIR}/build/cmake/android.toolchain.cmake"
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
	set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM "NEVER")
	set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE "ONLY")
	set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY "ONLY")
	#set(CMAKE_INSTALL_PREFIX "${TERMUX_PREFIX}")
	#set(CMAKE_INSTALL_LIBDIR "${TERMUX_PREFIX}/lib")
	set(CMAKE_SKIP_INSTALL_RPATH "ON")
	set(CMAKE_USE_SYSTEM_LIBRARIES "True")
	set(CMAKE_CROSSCOMPILING "True")
	set(DOXYGEN_EXECUTABLE "")
	set(BUILD_TESTING "OFF")
	set(CMAKE_LINKER "${TERMUX_STANDALONE_TOOLCHAIN}/bin/${LD}")
	set(CMAKE_SYSTEM_NAME "Android")
	set(CMAKE_SYSTEM_VERSION "${TERMUX_PKG_API_LEVEL}")
	set(CMAKE_SYSTEM_PROCESSOR "${CMAKE_PROC}")
	set(CMAKE_ANDROID_STANDALONE_TOOLCHAIN "${TERMUX_STANDALONE_TOOLCHAIN}")

	# https://github.com/dotnet/runtime/blob/445dac9e8e541b2364deea000dde8487ea1ec20e/src/coreclr/pal/src/configure.cmake#L776-L793
	# for unknown reason, this is needed here
	set(HAVE_COMPATIBLE_EXP_EXITCODE 0)

	# https://github.com/dotnet/runtime/issues/57784
	# Android has no liblttng-ust, Linux also has different issue
	#set(DISABLE_EVENTPIPE 1)
	#set(FEATURE_EVENT_TRACE 0)
	#set(FEATURE_PERFTRACING 0)
	EOL

	echo "INFO: ${TERMUX_PKG_TMPDIR}/build/cmake/android.toolchain.cmake"
	cat "${TERMUX_PKG_TMPDIR}/build/cmake/android.toolchain.cmake"
	echo

	export EXTRA_CFLAGS="${CFLAGS}"
	export EXTRA_CXXFLAGS="${CXXFLAGS}"
	export EXTRA_LDFLAGS="${LDFLAGS}"

	unset CC CFLAGS CXX CXXFLAGS LD LDFLAGS PKGCONFIG PKG_CONFIG PKG_CONFIG_DIR PKG_CONFIG_LIBDIR
}

termux_step_make() {
	#find /tmp -name "*.log" -exec echo "===== {} =====" \; -a -exec cat "{}" \; -a echo "===== {} =====" \;

	"${DOTNET_INSTALL_DIR}"/dotnet build-server shutdown
	pushd src/runtime
	# https://github.com/dotnet/runtime/issues/4296
	# CoreCLR on Android still broken, use mono
	# PublishAot true is also broken
	# Error below will appear when build with clr only:
	# Could not resolve CoreCLR path. For more details, enable tracing by setting COREHOST_TRACE environment variable to 1
	./build.sh \
		--configuration Release \
		--arch "${arch}" \
		--subset clr+mono+libs+host+packs \
		--os linux-bionic \
		--ninja \
		/p:_toolsRID=linux-bionic-${arch} \
		/p:OutputRid=linux-bionic-${arch}
	local p=""
	while IFS= read -r p; do
		[[ ! -f "${p}" ]] && continue
		"${DOTNET_INSTALL_DIR}"/dotnet nuget push "${p}" --source="${_packagesdir}"
	done < <(find artifacts/packages -name "*.nupkg" | sort)
	mkdir -p "${_downloaddir}/Runtime"
	find artifacts -name "*.tar.gz" -o -name "*.zip"
	cp -fv artifacts/packages/Release/Shipping/*.tar.gz "${_downloaddir}/Runtime/"
	git status
	rm -fr .dotnet artifacts/obj
	popd

	"${DOTNET_INSTALL_DIR}"/dotnet build-server shutdown
	pushd src/sdk
	# TODO set DotNetBuildFromSource=false for now due to:
	# sdk/src/Layout/redist/targets/GenerateLayout.targets(196,5): error : Something moved around in Test CLI package, adjust code here accordingly. TFM change? [sdk/src/Layout/redist/redist.csproj]
	# TODO fix this to make telemetry disabled by default
	DotNetBuildFromSource=false ./build.sh \
		--configuration Release \
		--pack \
		/p:Projects=${PWD}/source-build.slnf \
		/p:Architecture=${arch} \
		/p:TargetOS=linux-bionic \
		/p:TargetRid=linux-bionic-${arch}
	local p=""
	while IFS= read -r p; do
		[[ ! -f "${p}" ]] && continue
		"${DOTNET_INSTALL_DIR}"/dotnet nuget push "${p}" --source="${_packagesdir}"
	done < <(find artifacts/packages -name "*.nupkg" | sort)
	mkdir -p "${_downloaddir}/Sdk"
	find artifacts -name "*.tar.gz" -o -name "*.zip"
	cp -fv artifacts/packages/*/*/dotnet-toolset-internal-*.* "${_downloaddir}/Sdk/"
	rm -fr .dotnet artifacts/obj
	popd

	# TODO aspnetcore and installer generate linux- instead of linux-bionic-
	#return

	"${DOTNET_INSTALL_DIR}"/dotnet build-server shutdown
	# aspnetcore/eng/targets/ResolveReferences.targets(220,5): error MSB3245: Could not resolve this reference. Could not locate the package or project for "Microsoft.NETCore.App.Runtime.linux-x86". Did you update baselines and dependencies lists? See docs/ReferenceResolution.md for more details. [aspnetcore/src/Framework/App.Runtime/src/Microsoft.AspNetCore.App.Runtime.csproj]
	# dotnet9 points to internal pkgs.dev.azure.com
	if ! :; then
	if [[ "${arch}" != "x86" ]]; then
	pushd src/aspnetcore
	./eng/build.sh \
		--configuration Release \
		--ci \
		--pack \
		--arch "${arch}" \
		/p:DotNetAssetRootUrl=file://${_downloaddir}/
		#/p:TargetRuntimeIdentifier=linux-bionic-${arch}
	local p=""
	while IFS= read -r p; do
		"${DOTNET_INSTALL_DIR}"/dotnet nuget push "${p}" --source="${_packagesdir}"
	done < <(find artifacts/packages -name "*.nupkg" | sort)
	mkdir -p "${_downloaddir}/aspnetcore/Runtime"
	find artifacts -name "*.tar.gz" -o -name "*.zip"
	cp -fv artifacts/installers/*/aspnetcore-runtime-*-linux-*.tar.gz "${_downloaddir}/aspnetcore/Runtime/"
	cp -fv artifacts/installers/*/aspnetcore_base_runtime.version "${_downloaddir}/aspnetcore/Runtime/"
	git status
	rm -fr .dotnet artifacts/obj
	popd
	fi
	fi

	"${DOTNET_INSTALL_DIR}"/dotnet build-server shutdown
	# redist/targets/GenerateLayout.targets(397,5): error : Failed to download file using addresses in Uri and/or Uris. [installer/src/redist/redist.csproj]
	if [[ "${arch}" != "x86" ]]; then
	pushd src/runtime/src/installer
	./build.sh \
		--configuration Release \
		--architecture "${arch}" \
		--runtime-id "linux-bionic-${arch}" \
		/p:CoreSetupBlobRootUrl=file://$_downloaddir/ \
		/p:CoreSetupBlobRootUrl=file://$_downloaddir/ \
		/p:DISABLE_CROSSGEN=true
	local p=""
	while IFS= read -r p; do
		[[ ! -f "${p}" ]] && continue
		"${DOTNET_INSTALL_DIR}"/dotnet nuget push "${p}" --source="${_packagesdir}"
	done < <(find artifacts/packages -name "*.nupkg" | sort)
	mkdir -p "${_downloaddir}/installer"
	find artifacts -name "*.tar.gz" -o -name "*.zip"
	cp -fv artifacts/packages/*/*/dotnet-sdk-*.tar.gz "${_downloaddir}/installer/"
	git status
	rm -fr .dotnet artifacts/obj
	popd
	fi
}

termux_step_make_install() {
	# DEBUG copy all the artifacts use lots of space
	if ! :; then
	mkdir -p "${TERMUX_PREFIX}/opt/${TERMUX_PKG_NAME}"
	for component in runtime sdk aspnetcore runtime/src/installer; do
		echo "INFO: ${component}"
		[[ ! -d "${TERMUX_PKG_BUILDDIR}/src/${component}/artifacts" ]] && echo "INFO: No artifacts folder" && continue
		cp -fr "${TERMUX_PKG_BUILDDIR}/src/${component}/artifacts" "${TERMUX_PREFIX}/opt/${TERMUX_PKG_NAME}/${component}"
		rm -fr "${TERMUX_PKG_BUILDDIR}/src/${component}/artifacts"
	done
	du -sh "${TERMUX_PREFIX}/opt/${TERMUX_PKG_NAME}"
	fi

	# TODO need to partition into subpackage per distribution packaging guideline
	local _DOTNET_ROOT="${TERMUX_PREFIX}/share/dotnet"
	rm -fr "${_DOTNET_ROOT}"
	mkdir -p "${_DOTNET_ROOT}"
	pushd "${_DOTNET_ROOT}"
	# TODO investigate this as contains musl binaries
	# likely downloaded from Microsoft and not built
	local tgz
	for tgz in ${TERMUX_PKG_BUILDDIR}/src/runtime/src/installer/artifacts/packages/*/*/dotnet-sdk-*.tar.gz; do
		test -f "$tgz" && echo "INFO: Extracting $tgz" && tar -xf "$tgz"
	done
	# remove musl binaries
	# TODO should we remove linux- dirs and keep only linux-bionic- ?
	find . -type f -print0 | xargs -0 -r -P$(nproc) -i bash -c 'if [[ -n "$($READELF -d {} 2>/dev/null | grep libc.so.6)" ]]; then rm -v {}; fi'
	# overlay on top with android binaries
	for tgz in ${TERMUX_PKG_BUILDDIR}/src/runtime/artifacts/packages/Release/Shipping/*.tar.gz; do
		# TODO find suitable location to put
		[[ "$tgz" == *"internal"* ]] && echo "SKIP: $tgz" && continue
		[[ "$tgz" == *"symbols"* ]] && echo "SKIP: $tgz" && continue
		test -f "$tgz" && echo "INFO: Extracting $tgz" && tar -xf "$tgz"
	done
	# copy nupkg files
	cp -fv ${_packagesdir}/*.nupkg templates/${TERMUX_PKG_VERSION}/
	popd

	# TODO investigate if can remove libc++ and other deps
	# https://github.com/dotnet/android/pull/4958
	# TODO investigate if can replace with runpath
	# below is needed to link libc++_shared.so, libssl.so.3, etc
	cat <<-EOL > "${TERMUX_PREFIX}/bin/dotnet"
	#!${TERMUX_PREFIX}/bin/sh
	LD_LIBRARY_PATH="\${LD_LIBRARY_PATH}:${TERMUX_PREFIX}/lib" exec ${_DOTNET_ROOT}/dotnet "\$@"
	EOL
	chmod u+x "${TERMUX_PREFIX}/bin/dotnet"

	# https://src.fedoraproject.org/rpms/dotnet8.0/raw/rawhide/f/dotnet.sh.in
	mkdir -p "${TERMUX_PREFIX}/etc/profile.d"
	sed \
		-e "s|@LIBDIR@|${_DOTNET_ROOT}|g" \
		"${TERMUX_PKG_BUILDER_DIR}/dotnet.sh.in" \
		> "${TERMUX_PREFIX}/etc/profile.d/dotnet.sh"

	# shell completion
	install -Dm 644 "${TERMUX_PKG_SRCDIR}/src/sdk/scripts/register-completions.bash" "${TERMUX_PREFIX}/share/bash-completion/completions/dotnet"
	install -Dm 644 "${TERMUX_PKG_SRCDIR}/src/sdk/scripts/register-completions.zsh" "${TERMUX_PREFIX}/usr/share/zsh/site-functions/_dotnet"

	# Fix executable permissions on files
	# Shared libraries are intentionally removed exec bit
	find "${_DOTNET_ROOT}" -type f -name 'apphost' -exec chmod +x {} \;
	find "${_DOTNET_ROOT}" -type f -name 'singlefilehost' -exec chmod +x {} \;
	find "${_DOTNET_ROOT}" -type f -name 'lib*so' -exec chmod -x {} \;
	find "${_DOTNET_ROOT}" -type f -name '*.a' -exec chmod -x {} \;
	find "${_DOTNET_ROOT}" -type f -name '*.dll' -exec chmod -x {} \;
	find "${_DOTNET_ROOT}" -type f -name '*.h' -exec chmod 0644 {} \;
	find "${_DOTNET_ROOT}" -type f -name '*.json' -exec chmod -x {} \;
	find "${_DOTNET_ROOT}" -type f -name '*.pdb' -exec chmod -x {} \;
	find "${_DOTNET_ROOT}" -type f -name '*.props' -exec chmod -x {} \;
	find "${_DOTNET_ROOT}" -type f -name '*.pubxml' -exec chmod -x {} \;
	find "${_DOTNET_ROOT}" -type f -name '*.targets' -exec chmod -x {} \;
	find "${_DOTNET_ROOT}" -type f -name '*.txt' -exec chmod -x {} \;
	find "${_DOTNET_ROOT}" -type f -name '*.xml' -exec chmod -x {} \;
}

# References:
# https://dotnet.microsoft.com/en-us/platform/support/policy/dotnet-core
# https://learn.microsoft.com/en-us/dotnet/core/distribution-packaging
# https://git.alpinelinux.org/aports/tree/community/dotnet8-stage0/APKBUILD
# https://git.alpinelinux.org/aports/tree/community/dotnet8-runtime/APKBUILD
# https://git.alpinelinux.org/aports/tree/community/dotnet8-sdk/APKBUILD
# https://src.fedoraproject.org/rpms/dotnet8.0/blob/rawhide/f/dotnet8.0.spec
# https://git.launchpad.net/ubuntu/+source/dotnet8/tree/debian/rules
# https://gitlab.archlinux.org/archlinux/packaging/packages/dotnet-core/-/blob/main/PKGBUILD
