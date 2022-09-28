#!@TERMUX_PREFIX@/bin/sh
PREFIX=@TERMUX_PREFIX@

check_cmd_status() {
	[ -n "$(command -v "$1")" ] && echo 0 && return
	[ -e "${PREFIX}/bin/$1" ] && echo 1 && return
	echo 2
}

check_cmd() {
	status=$(check_cmd_status "$1")
	[ "${status}" = 0 ] && echo "OK" && return
	[ "${status}" = 1 ] && echo "NOT WORKING"
	[ "${status}" = 2 ] && echo "NOT FOUND"
	echo "error" > "${DEPS_STATUS}"
}

DEPS_STATUS=$(mktemp)
DEPS="
basename
grep
install
ls
patchelf
readelf
sed
sort
uname
"
for dep in ${DEPS}; do
	echo "INFO: Checking command ${dep} ... $(check_cmd "${dep}" "${DEPS_STATUS}")"
done
if [ "$(cat "${DEPS_STATUS}")" = "error" ]; then
	rm -f "${DEPS_STATUS}"
	echo "WARN: One or more dependencies are not installed. Install them then try again. Exiting ..." >&2
	exit
fi
rm -f "${DEPS_STATUS}"

UNAME=$(uname -m)
BIT=""
case "${UNAME}" in
aarch64|x86_64)
	BIT="64"
	;;
armv*|i*86)
	;;
*)
	echo "WARN: Unknown arch ${UNAME}" >&2
esac

TARGET_LIBOPENCL_SO="${PREFIX}/opt/vendor/lib/libOpenCL_real.so"
VENDOR_LIBOPENCL_SO=""
if [ -e "/vendor/lib${BIT}/libOpenCL.so" ]; then
	VENDOR_LIBOPENCL_SO="/vendor/lib${BIT}/libOpenCL.so"
elif [ -e "/system/vendor/lib${BIT}/libOpenCL.so" ]; then
	VENDOR_LIBOPENCL_SO="/system/vendor/lib${BIT}/libOpenCL.so"
else
	echo "WARN: Unable to find libOpenCL.so in /vendor and /system/vendor. This package maybe useless." >&2
fi
if [ -n "${VENDOR_LIBOPENCL_SO}" ]; then
	echo "INFO: Found ${VENDOR_LIBOPENCL_SO}, installing as ${TARGET_LIBOPENCL_SO} ..."
	install -Dm644 "${VENDOR_LIBOPENCL_SO}" "${TARGET_LIBOPENCL_SO}"
fi

install_deps() { (
	LIB=$(basename "$1")
	NEEDED_LIBS=$(readelf -d "$1" | grep NEEDED | sed "s|.* \[\(.*\)\]|\1|g" | sort)
	SET_RPATH="false"
	NOT_SYSTEM_LIBS=""
	echo "INFO: Checking ${LIB} for missing dependencies ..."
	for needed_lib in ${NEEDED_LIBS}; do
		IS_SYSTEM_LIB="false"
		for system_lib in ${SYSTEM_LIBS}; do
			[ "${DEBUG}" = 1 ] && echo "DEBUG: ${LIB} ... ${needed_lib} ... ${system_lib}"
			[ "${needed_lib}" = "${system_lib}" ] && IS_SYSTEM_LIB="true" && break
		done
		if [ "${IS_SYSTEM_LIB}" != "true" ]; then
			NOT_SYSTEM_LIBS="${NOT_SYSTEM_LIBS} ${needed_lib}"
		fi
	done
	for needed_lib in ${NOT_SYSTEM_LIBS}; do
		target_needed_lib="${PREFIX}/opt/vendor/lib/${needed_lib}"
		vendor_needed_lib=""
		if [ -e "/vendor/lib${BIT}/${needed_lib}" ]; then
			vendor_needed_lib="/vendor/lib${BIT}/${needed_lib}"
		elif [ -e "/system/vendor/lib${BIT}/${needed_lib}" ]; then
			vendor_needed_lib="/system/vendor/lib${BIT}/${needed_lib}"
		else
			echo "WARN: Unable to find ${needed_lib}. This package may not work properly." >&2
		fi
		if [ -n "${vendor_needed_lib}" ]; then
			echo "INFO: Installing missing dependency ${vendor_needed_lib} ..."
			install -Dm644 "${vendor_needed_lib}" "${target_needed_lib}"
			install_deps "${target_needed_lib}"
			SET_RPATH="true"
		fi
	done
	if [ "${SET_RPATH}" = "true" ]; then
		echo "INFO: Patching rpath for $1 ..."
		patchelf --set-rpath '$ORIGIN' "$1"
	else
		echo "INFO: Removing rpath for $1 ..."
		patchelf --remove-rpath "$1"
	fi
) }

if [ -n "${VENDOR_LIBOPENCL_SO}" ]; then
	SYSTEM_LIBS=$(ls /system/lib${BIT})
	install_deps "${TARGET_LIBOPENCL_SO}"
fi
