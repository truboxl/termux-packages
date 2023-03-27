TERMUX_SUBPKG_INCLUDE="
bin/c++
bin/cc
bin/*cpp
bin/*-clang
bin/*-clang++
bin/clang
bin/clang++
bin/*g++
bin/*gcc
"
TERMUX_SUBPKG_DESCRIPTION="Clang native build target wrappers"
TERMUX_SUBPKG_DEPENDS="clang"
TERMUX_SUBPKG_BREAKS="clang-default"
TERMUX_SUBPKG_REPLACES="clang-default"
TERMUX_SUBPKG_GROUPS="base-devel"

termux_step_create_subpkg_debscripts() {
	cat <<- EOF > postinst
	#!${TERMUX_PREFIX}/bin/bash
	for tool in cc c++ gcc g++ clang clang++; do
	rm -fv ${TERMUX_PREFIX}/bin/\${tool}
	done
	rm -fv ${TERMUX_HOST_PLATFORM}-{clang,clang++,gcc,g++}
	cat <<- EOL > ${TERMUX_PREFIX}/bin/clang
	#!${TERMUX_PREFIX}/bin/bash
	api_level=\\\$(getprop ro.build.version.sdk 2>/dev/null)
	if [ "\$1" != "-cc1" ]; then
	EOF

	if [ "${TERMUX_ARCH}" == "arm" ]; then
	cat <<- EOF >> postinst
	\\\`dirname \\\$0\\`/clang-${LLVM_MAJOR_VERSION} --target=armv7a-linux-androideabi\\\${api_level} "\\\$\@"
	EOF
	else
	cat <<- EOF >> postinst
	\\\`dirname \\\$0\\`/clang-${LLVM_MAJOR_VERSION} --target=${TERMUX_HOST_PLATFORM}\\\${api_level} "\\\$@"
	EOF
	fi

	cat <<- EOF >> postinst
	else
	# Target is already an argument.
	\\\`dirname \\\$0\\`/clang-${LLVM_MAJOR_VERSION} "\\\$@"
	fi
	EOL
	chmod +x ${TERMUX_PREFIX}/bin/clang
	for tool in cc c++ gcc g++ clang++ ${TERMUX_HOST_PLATFORM}-{clang,clang++,gcc,g++}; do
	cp -fv ${TERMUX_PREFIX}/bin/clang ${TERMUX_PREFIX}/bin/\${tool}
	done
	for tool in c++ g++ clang++ ${TERMUX_HOST_PLATFORM}-{clang++,g++}; do
	sed -i \${tool} -e "s|clang|clang++|g"
	done
	EOF
	echo "========== postinst =========="
	cat postinst
	echo "========== postinst =========="
}
