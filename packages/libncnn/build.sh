TERMUX_PKG_HOMEPAGE=https://github.com/Tencent/ncnn
TERMUX_PKG_DESCRIPTION="High-performance neural network inference framework"
TERMUX_PKG_LICENSE="BSD 3-Clause"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="20240410"
TERMUX_PKG_SRCURL=git+https://github.com/Tencent/ncnn
TERMUX_PKG_GIT_BRANCH=${TERMUX_PKG_VERSION}
TERMUX_PKG_SHA256=8805a6a7c9201779e04f64000f8b501e66e4c7aaf2756a8e5f217031ece70012
TERMUX_PKG_DEPENDS="abseil-cpp, libc++"
TERMUX_PKG_BUILD_DEPENDS="protobuf-static, python"
TERMUX_PKG_PYTHON_COMMON_DEPS="wheel, pybind11"
TERMUX_PKG_HOSTBUILD=true
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-DNCNN_BUILD_BENCHMARK=OFF
-DNCNN_BUILD_EXAMPLES=OFF
-DNCNN_BUILD_TESTS=OFF
-DNCNN_BUILD_TOOLS=OFF
-DNCNN_DISABLE_EXCEPTION=OFF
-DNCNN_DISABLE_RTTI=OFF
-DNCNN_ENABLE_LTO=ON
-DNCNN_OPENMP=ON
-DNCNN_PYTHON=ON
-DNCNN_SHARED_LIB=OFF
-DNCNN_SIMPLEOCV=ON
-DNCNN_SIMPLEOMP=ON
-DNCNN_SIMPLESTL=OFF
-DNCNN_SYSTEM_GLSLANG=ON
-DNCNN_VULKAN=OFF
-Dprotobuf_DIR=${TERMUX_PKG_HOSTBUILD_DIR}/prefix/cmake
"
TERMUX_PKG_RM_AFTER_INSTALL="
lib/libprotobuf.so
"

termux_step_post_get_source() {
	local version=$(git log -1 --format=%cs | sed -e "s|-||g")
	if [[ "${version}" != "${TERMUX_PKG_VERSION}" ]]; then
		termux_error_exit "
		Version mismatch detected!
		Expected = ${TERMUX_PKG_VERSION}
		Actual   = ${version}
		"
	fi

	local s=$(find . -type f ! -path '*/.git/*' -print0 | xargs -0 sha256sum | LC_ALL=C sort | sha256sum)
	if [[ "${s}" != "${TERMUX_PKG_SHA256}  "* ]]; then
		termux_error_exit "
		Checksum mismatch for source files!
		Expected = ${TERMUX_PKG_SHA256}
		Actual   = ${s}
		"
	fi
}

termux_step_host_build() {
	termux_setup_cmake
	termux_setup_ninja

	local PROTOBUF_VERSION=$(. $TERMUX_SCRIPTDIR/packages/libprotobuf/build.sh; echo ${TERMUX_PKG_VERSION#*:})
	local PROTOBUF_SRCURL=$(. $TERMUX_SCRIPTDIR/packages/libprotobuf/build.sh; echo $TERMUX_PKG_SRCURL)
	local PROTOBUF_SHA256=$(. $TERMUX_SCRIPTDIR/packages/libprotobuf/build.sh; echo $TERMUX_PKG_SHA256)
	termux_download ${PROTOBUF_SRCURL} ${TERMUX_PKG_BUILDER_DIR}/cache/protobuf-${PROTOBUF_VERSION}.tar.gz ${PROTOBUF_SHA256}
	tar -xvf ${TERMMUX_PKG_CACHEDIR}/protobuf-${PROTOBUF_VERSION}.tar.gz
	pushd protobuf-${PROTOBUF_VERSION}
	mkdir -p build
	cmake -G Ninja -B build -DCMAKE_INSTALL_PREFIX=${TERMUX_PKG_HOSTBUILD_DIR}/prefix
	ninja -C build -j ${TERMUX_MAKE_PROCESSES} install
	popd
}


termux_step_pre_configure() {
	termux_setup_cmake
	termux_setup_ninja
	termux_setup_protobuf

	CXXFLAGS+=" -std=c++17"
	LDFLAGS+=" $("${TERMUX_SCRIPTDIR}/packages/libprotobuf/interface_link_libraries.sh")"
	LDFLAGS+=" -lutf8_range -lutf8_validity"
	LDFLAGS+=" -landroid -ljnigraphics -llog"

	mv -v "${TERMUX_PREFIX}"/lib/libprotobuf.so{,.tmp}
}

termux_step_post_make_install() {
	# the build system can only build static or shared
	# at a given time
	local PROTOC_BIN=$(find ${TERMUX_PKG_TMPDIR} -type f -name protoc)
	TERMUX_PKG_EXTRA_CONFIGURE_ARGS+="
	-DNCNN_BUILD_TOOLS=ON
	-DNCNN_SHARED_LIB=ON
	"
	termux_step_configure
	termux_step_make
	termux_step_make_install

	pushd python
	pip install --no-deps . --prefix "${TERMUX_PREFIX}"
	popd

	mv -v "${TERMUX_PREFIX}"/lib/libprotobuf.so{.tmp,}

	return

	# below are testing tools that should not be packaged
	# as they can be >100MB
	TERMUX_PKG_EXTRA_CONFIGURE_ARGS+="
	-DNCNN_BUILD_BENCHMARK=ON
	-DNCNN_BUILD_EXAMPLES=ON
	-DNCNN_BUILD_TESTS=ON
	-DNCNN_SHARED_LIB=OFF
	"
	termux_step_configure
	termux_step_make

	local tools_dir="${TERMUX_PREFIX}/lib/ncnn"

	local benchmarks=$(find benchmark -mindepth 1 -maxdepth 1 -type f | sort)
	for benchmark in ${benchmarks}; do
		case "$(basename "${benchmark}")" in
		*[Cc][Mm]ake*) continue ;;
		*.cpp*) continue ;;
		*.md) continue ;;
		*.*) install -v -Dm644 -t "${tools_dir}/benchmark" "${benchmark}" ;;
		*) install -v -Dm755 -t "${tools_dir}/benchmark" "${benchmark}" ;;
		esac
	done

	local examples=$(find examples -mindepth 1 -maxdepth 1 -type f | sort)
	for example in ${examples}; do
		case "$(basename "${example}")" in
		*[Cc][Mm]ake*) continue ;;
		*.cpp*) continue ;;
		*.*) install -v -Dm644 -t "${tools_dir}/examples" "${example}" ;;
		*) install -v -Dm755 -t "${tools_dir}/examples" "${example}" ;;
		esac
	done

	local tests=$(find tests -mindepth 1 -maxdepth 1 -type f | sort)
	for test in ${tests}; do
		case "$(basename "${test}")" in
		*[Cc][Mm]ake*) continue ;;
		*.cpp*) continue ;;
		*.h) continue ;;
		*.py) continue ;;
		*) install -v -Dm755 -t "${tools_dir}/tests" "${test}" ;;
		esac
	done
}
