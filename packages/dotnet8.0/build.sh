TERMUX_PKG_HOMEPAGE=https://dotnet.microsoft.com/en-us/
TERMUX_PKG_DESCRIPTION=".NET 8"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="8.0.11"
TERMUX_PKG_SRCURL=git+https://github.com/dotnet/dotnet
TERMUX_PKG_GIT_BRANCH=v${TERMUX_PKG_VERSION}
TERMUX_PKG_DEPENDS="krb5, libandroid-glob, libicu, libllvm, liblzma, zlib"
TERMUX_PKG_BUILD_IN_SRC=true

# https://github.com/dotnet/runtime/issues/7335
# linux-x86 is not officially supported
#TERMUX_PKG_BLACKLISTED_ARCHES="i686"

termux_step_post_get_source() {
	# set up dotnet cli and override source files
	./prep.sh
}

termux_step_pre_configure() {
	termux_setup_cmake
	termux_setup_ninja

	# aspnetcore needs nodejs <= 19, but nodejs 19.x is EOL
	local NODEJS_VERSION=18.20.4
	local NODEJS_SHA256=592eb35c352c7c0c8c4b2ecf9c19d615e78de68c20b660eb74bd85f8c8395063
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

	# in case need to build openssl
	if ! :; then
	local OPENSSL_VERSION=$(. ${TERMUX_SCRIPTDIR}/packages/openssl/build.sh; echo ${TERMUX_PKG_VERSION})
	local OPENSSL_SRCURL=$(. ${TERMUX_SCRIPTDIR}/packages/openssl/build.sh; echo ${TERMUX_PKG_SRCURL})
	local OPENSSL_SHA256=$(. ${TERMUX_SCRIPTDIR}/packages/openssl/build.sh; echo ${TERMUX_PKG_SHA256})
	termux_download ${OPENSSL_SRCURL} ${TERMUX_PKG_CACHEDIR}/openssl.tar.gz ${OPENSSL_SHA256}
	mkdir -p ${TERMUX_PKG_BUILDDIR}/openssl
	tar -xf ${TERMUX_PKG_CACHEDIR}/openssl.tar.gz -C ${TERMUX_PKG_BUILDDIR}/openssl --strip-components=1
	pushd ${TERMUX_PKG_BUILDDIR}/openssl
	for p in ${TERMUX_SCRIPTDIR}/packages/openssl/*.patch; do
		test -f "$p" && patch -p1 -i "$p"
	done
	test $TERMUX_ARCH = "arm" && TERMUX_OPENSSL_PLATFORM="android-arm"
	test $TERMUX_ARCH = "aarch64" && TERMUX_OPENSSL_PLATFORM="android-arm64"
	test $TERMUX_ARCH = "i686" && TERMUX_OPENSSL_PLATFORM="android-x86"
	test $TERMUX_ARCH = "x86_64" && TERMUX_OPENSSL_PLATFORM="android-x86_64"
	./Configure $TERMUX_OPENSSL_PLATFORM \
		--prefix=$TERMUX_PREFIX \
		--openssldir=$TERMUX_PREFIX/etc/tls \
		shared \
		zlib-dynamic \
		no-ssl \
		no-hw \
		no-srp \
		no-tests \
		enable-tls1_3
	make depend
	make -j $TERMUX_PKG_MAKE_PROCESSES all
	make -j 1 install_sw DESTDIR=${TERMUX_PKG_BUILDDIR}/openssl-install
	nm -D $TERMUX_PKG_BUILDDIR/openssl-install${TERMUX_PREFIX}/lib/libssl.so
	popd
	fi

	export DOTNET_INSTALL_DIR="${TERMUX_PKG_SRCDIR}/.dotnet"
	export DotNetBuildFromSource=true
	export _downloaddir="${TERMUX_PREFIX}/opt/dotnet8/local-downloads"
	export _packagesdir="${TERMUX_PREFIX}/opt/dotnet8/local-packages"
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
	export CFLAGS+=" --target=${CCTERMUX_HOST_PLATFORM}"
	export CXXFLAGS+=" --target=${CCTERMUX_HOST_PLATFORM}"

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

	echo "===== android.toolchain.cmake ====="
	cat "${TERMUX_PKG_TMPDIR}/build/cmake/android.toolchain.cmake"
	echo "===== android.toolchain.cmake ====="

	#export _EXTRA_ARGS=()
	#if [[ "${TERMUX_DEBUG_BUILD}" == "true" ]]; then
	#	_EXTRA_ARGS+=("/p:Configuration=Debug")
	#else
	#	_EXTRA_ARGS+=("/p:Configuration=Release")
	#fi
	#_EXTRA_ARGS+=("/p:CrossBuild=True")
	#_EXTRA_ARGS+=("/p:TargetArchitecture=${arch}")
	# TODO hardcode for now
	#_EXTRA_ARGS+=("/p:BuildArchitecture=x64")
	#_EXTRA_ARGS+=("/p:TargetOS=android")
	#_EXTRA_ARGS+=("/p:CleanWhileBuilding=true")
	#_EXTRA_ARGS+=("/p:BuildWithOnlineSources=true")
	#_EXTRA_ARGS+=("/p:MonoLibClang=${TERMUX_STANDALONE_TOOLCHAIN}/lib/libclang.so")
	#_EXTRA_ARGS+=("/p:FeaturePerfTracing=false")
	#_EXTRA_ARGS+=("/p:TreatWarningsAsErrors=false")

	#export _CMAKE_ARGS=""
	#_CMAKE_ARGS="${_CMAKE_ARGS// /%20}"
	#_EXTRA_ARGS+=("/p:CMakeArgs=\"${_CMAKE_ARGS}\"")

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
	# CoreCLR on Android still broken, use mono instead of clr
	# Error below will appear for clr:
	# Could not resolve CoreCLR path. For more details, enable tracing by setting COREHOST_TRACE environment variable to 1
	./build.sh \
		--configuration Release \
		--arch "${arch}" \
		--subset mono+libs+host+packs \
		--os linux-bionic \
		--ninja \
		/p:_toolsRID=linux-bionic-${arch} \
		/p:OutputRid=linux-bionic-${arch}
	local p=""
	while IFS= read -r p; do
		[[ ! -f "${p}" ]] && continue
		"${DOTNET_INSTALL_DIR}"/dotnet nuget push "${p}" --source="${_packagesdir}"
	done < <(find artifacts/packages -name "*.nupkg" | sort)
	find artifacts -name "*.tar.gz" -o -name "*.zip"
	mkdir -p "${_downloaddir}/Runtime"
	cp -fv artifacts/packages/*/*/dotnet-runtime-*-*.tar.gz "${_downloaddir}/Runtime/"
	git status
	rm -fr .dotnet
	popd

	"${DOTNET_INSTALL_DIR}"/dotnet build-server shutdown
	pushd src/sdk
	# set DotNetBuildFromSource=false for now due to:
	# sdk/src/Layout/redist/targets/GenerateLayout.targets(196,5): error : Something moved around in Test CLI package, adjust code here accordingly. TFM change? [sdk/src/Layout/redist/redist.csproj]
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
	find artifacts -name "*.tar.gz" -o -name "*.zip"
	mkdir -p "${_downloaddir}/Sdk"
	cp -fv artifacts/packages/*/*/dotnet-toolset-internal-*.* "${_downloaddir}/Sdk/"
	rm -fr .dotnet artifacts/obj
	popd

	# aspnetcore and installer builds using linux- instead of linux-bionic-
	# quit for now
	#return

	"${DOTNET_INSTALL_DIR}"/dotnet build-server shutdown
	# aspnetcore/eng/targets/ResolveReferences.targets(220,5): error MSB3245: Could not resolve this reference. Could not locate the package or project for "Microsoft.NETCore.App.Runtime.linux-x86". Did you update baselines and dependencies lists? See docs/ReferenceResolution.md for more details. [aspnetcore/src/Framework/App.Runtime/src/Microsoft.AspNetCore.App.Runtime.csproj]
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
	find artifacts -name "*.tar.gz" -o -name "*.zip"
	mkdir -p "${_downloaddir}/aspnetcore/Runtime"
	cp -fv artifacts/installers/*/aspnetcore-runtime-*-linux-*.tar.gz "${_downloaddir}/aspnetcore/Runtime/"
	cp -fv artifacts/installers/*/aspnetcore_base_runtime.version "${_downloaddir}/aspnetcore/Runtime/"
	git status
	rm -fr .dotnet artifacts/obj
	popd
	fi

	"${DOTNET_INSTALL_DIR}"/dotnet build-server shutdown
	# redist/targets/GenerateLayout.targets(397,5): error : Failed to download file using addresses in Uri and/or Uris. [installer/src/redist/redist.csproj]
	if [[ "${arch}" != "x86" ]]; then
	pushd src/installer
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
	find artifacts -name "*.tar.gz" -o -name "*.zip"
	mkdir -p "${_downloaddir}/installer"
	find artifacts -name "*.tar.gz"
	cp -fv artifacts/packages/*/*/dotnet-sdk-*.tar.gz "${_downloaddir}/installer/"
	git status
	rm -fr .dotnet artifacts/obj
	popd
	fi
}

termux_step_post_make_install() {
	mkdir -p "${TERMUX_PREFIX}/opt/dotnet8"
	if ! :; then
	for component in runtime sdk aspnetcore installer; do
		echo "INFO: ${component}"
		[[ ! -d "${TERMUX_PKG_BUILDDIR}/src/${component}/artifacts" ]] && echo "INFO: No artifacts folder" && continue
		cp -fr "${TERMUX_PKG_BUILDDIR}/src/${component}/artifacts" "${TERMUX_PREFIX}/opt/dotnet8/${component}"
		rm -fr "${TERMUX_PKG_BUILDDIR}/src/${component}/artifacts"
	done
	fi
	du -sh "${TERMUX_PREFIX}/opt/dotnet8"
}
