TERMUX_PKG_HOMEPAGE=https://www.qt.io/
TERMUX_PKG_DESCRIPTION="A cross-platform application and UI framework"
TERMUX_PKG_LICENSE="LGPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="6.6.1"
TERMUX_PKG_SRCURL="https://download.qt.io/official_releases/qt/${TERMUX_PKG_VERSION%.*}/${TERMUX_PKG_VERSION}/submodules/qtbase-everywhere-src-${TERMUX_PKG_VERSION}.tar.xz"
TERMUX_PKG_SHA256=450c5b4677b2fe40ed07954d7f0f40690068e80a94c9df86c2c905ccd59d02f7
TERMUX_PKG_DEPENDS="brotli, double-conversion, libandroid-shmem, libc++, libsqlite, openssl, zlib, zstd"
TERMUX_PKG_HOSTBUILD=true
TERMUX_PKG_FORCE_CMAKE=true
TERMUX_PKG_NO_STATICSPLIT=true
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-DANDROID=OFF
-DCMAKE_SYSTEM_NAME=Linux
-DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON
-DCMAKE_MESSAGE_LOG_LEVEL=STATUS
-DFEATURE_journald=OFF
-DFEATURE_no_direct_extern_access=ON
-DFEATURE_openssl_linked=ON
-DFEATURE_system_sqlite=ON
-DINSTALL_ARCHDATADIR=lib/qt6
-DINSTALL_BINDIR=lib/qt6/bin
-DINSTALL_DATADIR=share/qt6
-DINSTALL_DOCDIR=share/doc/qt6
-DINSTALL_EXAMPLESDIR=share/doc/qt6/examples
-DINSTALL_INCLUDEDIR=include/qt6
-DINSTALL_LIBEXECDIR=lib/qt6
-DINSTALL_MKSPECSDIR=lib/qt6/mkspecs
-DINSTALL_PUBLICBINDIR=${TERMUX_PREFIX}/bin
-DQT_ALLOW_SYMLINK_IN_PATHS=ON
-DQT_FEATURE_freetype=OFF
-DQT_FEATURE_gui=OFF
-DQT_FEATURE_harfbuzz=OFF
-DQT_FEATURE_widgets=OFF
-DQT_FEATURE_zstd=ON
-DQT_HOST_PATH=${TERMUX_PREFIX}/opt/qt6/cross
"

termux_step_host_build() {
	termux_setup_cmake
	termux_setup_ninja

	cmake \
		-G Ninja \
		-S ${TERMUX_PKG_SRCDIR} \
		-DCMAKE_BUILD_TYPE=MinSizeRel \
		-DCMAKE_INSTALL_PREFIX=${TERMUX_PREFIX}/opt/qt6/cross \
		-DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
		-DCMAKE_MESSAGE_LOG_LEVEL=STATUS \
		-DFEATURE_journald=OFF \
		-DFEATURE_openssl_linked=ON \
		-DFEATURE_system_sqlite=ON \
		-DINSTALL_ARCHDATADIR=lib/qt6 \
		-DINSTALL_BINDIR=lib/qt6/bin \
		-DINSTALL_DATADIR=share/qt6 \
		-DINSTALL_DOCDIR=share/doc/qt6 \
		-DINSTALL_EXAMPLESDIR=share/doc/qt6/examples \
		-DINSTALL_INCLUDEDIR=include/qt6 \
		-DINSTALL_LIBEXECDIR=lib/qt6 \
		-DINSTALL_MKSPECSDIR=lib/qt6/mkspecs \
		-DINSTALL_PUBLICBINDIR=${TERMUX_PREFIX}/opt/qt6/cross/bin \
		-DQT_ALLOW_SYMLINK_IN_PATHS=ON \
		-DQT_FEATURE_freetype=OFF \
		-DQT_FEATURE_gui=OFF \
		-DQT_FEATURE_harfbuzz=OFF \
		-DQT_FEATURE_widgets=OFF \
		-DQT_FEATURE_zstd=OFF
	ninja \
		-j ${TERMUX_MAKE_PROCESSES} \
		install

	cat user_facing_tool_links.txt
	sed -e "s|^${TERMUX_PREFIX}/opt/qt6/cross|..|g" -i user_facing_tool_links.txt
	mkdir -p ${TERMUX_PREFIX}/opt/qt6/cross/bin
	cat user_facing_tool_links.txt | xargs -P${TERMUX_MAKE_PROCESSES} -L1 ln -sv
}

termux_step_pre_configure() {
	termux_setup_cmake
	termux_setup_ninja

	TERMUX_PKG_EXTRA_CONFIGURE_ARGS+="
	-DCMAKE_C_COMPILER_AR=${TERMUX_STANDALONE_TOOLCHAIN}/bin/llvm-ar
	-DCMAKE_C_COMPILER_RANLIB=${TERMUX_STANDALONE_TOOLCHAIN}/bin/llvm-ranlib
	"
}

termux_step_post_make_install() {
	find ${TERMUX_PKG_BUILDDIR} -type f -name user_facing_tool_links.txt
	cat ${TERMUX_PKG_BUILDDIR}/user_facing_tool_links.txt
	#cat ${TERMUX_PKG_BUILDDIR}/user_facing_tool_links.txt | xargs -P${TERMUX_MAKE_PROCESSES} -L1 ln -sv
}
