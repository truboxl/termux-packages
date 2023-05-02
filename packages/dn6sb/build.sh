TERMUX_PKG_HOMEPAGE=dn6sb
TERMUX_PKG_DESCRIPTION="dn6sb"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=6.0.408
TERMUX_PKG_SRCURL=git+https://github.com/dotnet/installer
TERMUX_PKG_GIT_BRANCH=v${TERMUX_PKG_VERSION}
TERMUX_PKG_DEPENDS="krb5, zlib"
TERMUX_PKG_HOSTBUILD=true

termux_step_post_get_source() {
	DotNetBuildFromSource=true ./build.sh \
		/p:ArcadeBuildTarball=true \
		/p:TarballDir=$TERMUX_PKG_CACHEDIR/src \
		/p:TarballFilePath=$TERMUX_PKG_SRCDIR/src.tar
	mkdir -p $TERMUX_PKG_BUILDDIR
	tar -C $TERMUX_PKG_BUILDDIR -xf $TERMUX_PKG_SRCDIR/src.tar
}

termux_step_host_build() {
	termux_setup_cmake
	termux_setup_ninja
	#git clone https://github.com/llvm/llvm-project --depth 1
	#cmake -G Ninja -B llvm-build -S llvm-project/llvm -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$TERMUX_PKG_BUILDDIR/llvm-install
	#ninja -C llvm-build -j $TERMUX_MAKE_PROCESSES install
	#export PATH=$TERMUX_PKG_BUILDDIR/llvm-install/bin:$PATH
	tar -xf $TERMUX_PKG_SRCDIR/src.tar
	./prep.sh --help
	#./prep.sh
	./build.sh --help
	#./build.sh || :
}

termux_step_pre_configure() {
	echo "=========== skip preconfigure =========="
	return
	if [ "$TERMUX_ARCH" == "arm" ]; then
		CFLAGS="${CFLAGS//-mthumb/}"
	fi
	LDFLAGS+=" -lgssapi_krb5 -lz"
	termux_setup_cmake
	termux_setup_ninja
}

termux_step_make() {
	echo "=========== skip make =========="
	return
	rm -fr "$TERMUX_PKG_TMPDIR/cmake"
	mkdir -p "$TERMUX_PKG_TMPDIR/cmake"
	pushd "$TERMUX_PKG_TMPDIR/cmake"
	echo "project(foo)" > CMakeLists.txt
	TERMUX_PKG_SRCDIR=$PWD termux_step_configure_cmake
	echo "========== CMakeCache.txt =========="
	cat CMakeCache.txt
	echo "========== CMakeCache.txt =========="
	grep -e "^CMAKE_CROSSCOMPILING:" CMakeCache.txt >> cmakeargs.txt
	grep -e "^CMAKE_LINKER:" CMakeCache.txt >> cmakeargs.txt
	grep -e "^CMAKE_SYSTEM_NAME:" CMakeCache.txt >> cmakeargs.txt
	grep -e "^CMAKE_SYSTEM_VERSION:" CMakeCache.txt >> cmakeargs.txt
	grep -e "^CMAKE_ANDROID_STANDALONE_TOOLCHAIN:" CMakeCache.txt >> cmakeargs.txt
	grep -e "^CMAKE_AR:" CMakeCache.txt >> cmakeargs.txt
	grep -e "^CMAKE_UNAME:" CMakeCache.txt >> cmakeargs.txt
	grep -e "^CMAKE_RANLIB:" CMakeCache.txt >> cmakeargs.txt
	grep -e "^CMAKE_STRIP:" CMakeCache.txt >> cmakeargs.txt
	grep -e "^CMAKE_BUILD_TYPE:" CMakeCache.txt >> cmakeargs.txt
	grep -e "^CMAKE_C_FLAGS:" CMakeCache.txt >> cmakeargs.txt
	grep -e "^CMAKE_CXX_FLAGS:" CMakeCache.txt >> cmakeargs.txt
	grep -e "^CMAKE_FIND_ROOT_PATH:" CMakeCache.txt >> cmakeargs.txt
	grep -e "^CMAKE_FIND_ROOT_PATH_MODE_PROGRAM:" CMakeCache.txt >> cmakeargs.txt
	grep -e "^CMAKE_FIND_ROOT_PATH_MODE_INCLUDE:" CMakeCache.txt >> cmakeargs.txt
	grep -e "^CMAKE_FIND_ROOT_PATH_MODE_LIBRARY:" CMakeCache.txt >> cmakeargs.txt
	grep -e "^CMAKE_INSTALL_PREFIX:" CMakeCache.txt >> cmakeargs.txt
	grep -e "^CMAKE_INSTALL_LIBDIR:" CMakeCache.txt >> cmakeargs.txt
	grep -e "^CMAKE_MAKE_PROGRAM:" CMakeCache.txt >> cmakeargs.txt
	grep -e "^CMAKE_SKIP_INSTALL_RPATH:" CMakeCache.txt >> cmakeargs.txt
	grep -e "^CMAKE_USE_SYSTEM_LIBRARIES:" CMakeCache.txt >> cmakeargs.txt
	echo "========== cmakeargs.txt =========="
	cat cmakeargs.txt
	echo "========== cmakeargs.txt =========="
	sed -i cmakeargs.txt \
		-e "s|$|\"|g" \
		-e "s|:BOOL=|=\"|g" \
		-e "s|:FILEPATH=|=\"|g" \
		-e "s|:INTERNAL=|=\"|g" \
		-e "s|:PATH=|=\"|g" \
		-e "s|:STRING=|=\"|g" \
		-e "s|:UNINITIALIZED=|=\"|g" \
		-e "s|^|/p:CMakeArgs=-D|g"
	echo "========== cmakeargs.txt =========="
	cat cmakeargs.txt
	echo "========== cmakeargs.txt =========="
	local _cmake_args=$(cat cmakeargs.txt)
	popd

	case "$TERMUX_ARCH" in
		aarch64) local arch=aarch64;;
		arm) local arch=arm;;
		i686) local arch=x86;;
		x86_64) local arch=x64;;
	esac
	./prep.sh

	export ROOTFS_DIR=$TERMUX_PREFIX
	# nasty hack
	#ln -sv "$TERMUX_PREFIX/usr" ".."
	# convoluted build system
	./build.sh -- /p:Architecture=$arch /p:CrossBuild=true /p:CleanWhileBuilding=true /p:CrossgenOutput=false /p:DISABLE_CROSSGEN=true /p:TargetRid=android.24-$arch ${_cmake_args// /%20}
}

termux_step_post_make_install() {
	mkdir -p $TERMUX_PREFIX/opt/dn6
	cp -fr $TERMUX_PKG_BUILDDIR $TERMUX_PREFIX/opt/dn6
	du -sh $TERMUX_PREFIX/opt/dn6
}
