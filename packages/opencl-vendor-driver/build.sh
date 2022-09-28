TERMUX_PKG_HOMEPAGE=https://github.com/krrishnarraj/libopencl-stub
TERMUX_PKG_DESCRIPTION="OpenCL driver from system vendor"
TERMUX_PKG_LICENSE="Unlicense"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=0.1
TERMUX_PKG_BUILD_DEPENDS="opencl-headers"
TERMUX_PKG_RECOMMENDS="binutils | binutils-is-llvm, patchelf"
TERMUX_PKG_SUGGESTS="ocl-icd"
TERMUX_PKG_SKIP_SRC_EXTRACT=true

# This package copies on-device libOpenCL.so to the correct places on Termux
# so no need for export LD_LIBRARY_PATH=/vendor/lib64

# This package does not host true libOpenCL.so from OEM / SoC vendor and instead
# uses code from https://github.com/krrishnarraj/libopencl-stub
# with patches from
# https://github.com/krrishnarraj/libopencl-stub/pull/1

# Formatted using clang-format --style:file=clang-format

# This package attempts to standardise libOpenCL.so drivers across different vendors:
# GPU                   SONAME              cl_khr_icd
# Arm Mali              libOpenCL.so.1      y
# Qualcomm Adreno       libOpenCL.so        n

termux_step_make() {
	echo "${TERMUX_PREFIX}/opt/vendor/lib/libOpenCL.so" > vendor.icd
	cp -f "${TERMUX_PKG_BUILDER_DIR}"/libopencl.{c,h} .
	"${CC}" -v ${CPPFLAGS} ${CFLAGS/-Oz/-O2} \
		-Wl,-soname,libOpenCL.so -shared -o libOpenCL.so libopencl.c -flto \
		-DDEFAULT_LIBOPENCL_SO=\"${TERMUX_PREFIX}/opt/vendor/lib/libOpenCL_real.so\"
}

termux_step_make_install() {
	install -Dm644 vendor.icd "${TERMUX_PREFIX}/etc/OpenCL/vendors/vendor.icd"
	install -Dm644 libOpenCL.so "${TERMUX_PREFIX}/opt/vendor/lib/libOpenCL.so"
	install -Dm644 /dev/null "${TERMUX_PREFIX}/opt/vendor/lib/libOpenCL_real.so"
}

termux_step_create_debscripts() {
	cp -f "${TERMUX_PKG_BUILDER_DIR}/postinst.sh" postinst
	sed -i postinst -e "s|@TERMUX_PREFIX@|${TERMUX_PREFIX}|g"

	cat <<- EOF > prerm
	#!${TERMUX_PREFIX}/bin/sh
	case "\$1" in
	purge|remove)
	rm -fr "${TERMUX_PREFIX}/opt/vendor/lib"
	esac
	EOF
}
