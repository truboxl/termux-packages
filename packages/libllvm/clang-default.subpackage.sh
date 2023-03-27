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
TERMUX_SUBPKG_DESCRIPTION="Clang default build target symbolic links"
TERMUX_SUBPKG_DEPENDS="clang"
TERMUX_SUBPKG_BREAKS="clang-native"
TERMUX_SUBPKG_REPLACES="clang-native"
TERMUX_SUBPKG_GROUPS="base-devel"
